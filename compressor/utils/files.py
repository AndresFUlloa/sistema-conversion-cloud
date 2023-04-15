import logging
import zipfile
import os
import tarfile
import py7zr
from typing import Text
from enum import Enum

LOGGER = logging.getLogger()


class CompressionTypes(Enum):
    ZIP = 'zip'
    TAR_GZ = 'tar.gz'
    SEVEN_Z = '7z'


def compress_files(path: Text, file_name: Text, compression_type:  Text) -> None:
    file_path = os.path.join(path, file_name)

    if compression_type == CompressionTypes.ZIP.value:
        result_path = os.path.join(path, file_name.split('.')[0] + '.zip')
        with zipfile.ZipFile(result_path, 'w') as zipf:
            zipf.write(file_path, arcname=os.path.basename(file_path))
    elif compression_type == CompressionTypes.TAR_GZ.value:
        result_path = os.path.join(path, file_name.split('.')[0] + '.tar.gz')
        with tarfile.open(result_path, 'w:gz') as tar:
            tar.add(file_path, arcname=os.path.basename(file_path))
    elif compression_type == CompressionTypes.SEVEN_Z.value:
        result_path = os.path.join(path, file_name.split('.')[0] + '.7z')
        with py7zr.SevenZipFile(result_path, 'w') as szf:
            szf.writeall(file_path, arcname=os.path.basename(file_path))
    else:
        raise ValueError(f"Unsupported compression type: {compression_type}")