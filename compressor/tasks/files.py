import os
import json
import logging
from compressor.extensions import db
from compressor.models import Task, TaskStatus
from compressor.utils.files import compress_files
from google.cloud import storage

from google.cloud import pubsub_v1



LOGGER = logging.getLogger()

def run_compress_callback(message: pubsub_v1.subscriber.message.Message) -> None:
    from manage import current_app
    with current_app.app_context():
        message_data = message.data.decode('utf-8')
        data_dict = json.loads(message_data)

        LOGGER.info("Received %s", data_dict)

        task = Task.query.get_or_404(data_dict['task_id'])

        client = storage.Client()
        bucket = client.bucket(os.getenv("CLOUD_STORAGE_BUCKET"))

        blob = bucket.blob(data_dict['path'])

        temp_file_path = f'/{data_dict["file_name"]}'
        blob.download_to_filename(temp_file_path)

        result, content_type, filename = compress_files(
            "/",
            data_dict["file_name"],
            data_dict["compression_type"]
        )

        target_path = f"{data_dict['target_folder']}/{filename}"
        blob = bucket.blob(target_path)
        result_file = open(result, "rb")
        blob.upload_from_string(
            result_file.read(), content_type=content_type
        )

        if os.path.exists(temp_file_path):
            os.remove(temp_file_path)

        if os.path.exists(result):
            os.remove(result)

        task.status = TaskStatus.PROCESSED
        task.available = True
        db.session.commit()

        message.ack()