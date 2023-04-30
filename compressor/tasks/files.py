import os
from typing import Text

from celery import shared_task
from compressor.extensions import db
from compressor.models import Task, TaskStatus
from compressor.utils.files import compress_files
from google.cloud import storage


@shared_task(ignore_result=False)
def run_compress_job(path: Text, file_name: Text, compression_type:  Text, task_id: int, target_folder: Text) -> None:
    task = Task.query.get_or_404(task_id)

    client = storage.Client()
    bucket = client.bucket(os.getenv("CLOUD_STORAGE_BUCKET"))

    blob = bucket.blob(path)
    temp_path = f'/temp/files/{target_folder}'

    if not os.path.exists(temp_path):
        os.makedirs(temp_path)

    temp_file_path = f'{temp_path}/{file_name}'
    blob.download_to_filename(temp_file_path)

    result, content_type, filename = compress_files(
        temp_path,
        file_name,
        compression_type
    )

    target_path = f"{target_folder}/{filename}"
    blob = bucket.blob(target_path)
    result_file = open(result, "rb")
    blob.upload_from_string(
        result_file.read(), content_type=content_type
    )

    os.remove(temp_file_path)
    os.remove(result)

    task.status = TaskStatus.PROCESSED
    task.available = True
    db.session.commit()