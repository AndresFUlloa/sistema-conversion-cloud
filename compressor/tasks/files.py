from typing import Text

from celery import shared_task

from compressor.models import Task
from compressor.utils.files import compress_files


@shared_task(ignore_result=False)
def run_compress_job(path: Text, file_name: Text, compression_type:  Text, task_id: int) -> None:
    task = Task.query.get_or_404(task_id)
    compress_files(
        path,
        file_name,
        compression_type
    )