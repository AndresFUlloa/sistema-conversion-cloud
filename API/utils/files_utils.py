# Compresor ZIP, TAR.GZ, 7z
import zipfile
import os
import tarfile
import py7zr

def comprimir_zip(ruta_archivos, nombre_archivo):
    ruta_archivo = os.path.join(ruta_archivos, nombre_archivo)  # Ruta del archivo a comprimir
    ruta_zip = os.path.join(ruta_archivos, nombre_archivo.split('.')[0]+'.zip')  # Ruta del archivo .zip a crear
    with zipfile.ZipFile(ruta_zip, 'w') as zipf:
        zipf.write(ruta_archivo, arcname=os.path.basename(ruta_archivo))

    print(f'Se ha creado el archivo {ruta_zip} exitosamente.')

def comprimir_archivo_tar_gz(ruta_archivos, nombre_archivo):
    ruta_archivo = os.path.join(ruta_archivos, nombre_archivo)  # Ruta del archivo a comprimir
    ruta_tar_gz = os.path.join(ruta_archivos, nombre_archivo.split('.')[0]+'.tar.gz')  # Ruta del archivo .tar.gz a crear
    with tarfile.open(ruta_tar_gz, 'w:gz') as tar:
        tar.add(ruta_archivo, arcname=os.path.basename(ruta_archivo))
    print(f'Se ha creado el archivo {ruta_tar_gz} exitosamente.')

# Ejemplo de uso
# ruta_archivo = '/ruta/del/archivo.txt'  # Ruta del archivo a comprimir
# ruta_tar_gz = '/ruta/del/archivo.tar.gz'  # Ruta del archivo .tar.gz a crear

def comprimir_archivo_7z(ruta_archivos, nombre_archivo):
    ruta_archivo = os.path.join(ruta_archivos, nombre_archivo)  # Ruta del archivo a comprimir
    ruta_7z = os.path.join(ruta_archivos, nombre_archivo.split('.')[0]+'.7z')  # Ruta del archivo .7z a crear
    with py7zr.SevenZipFile(ruta_7z, 'w') as szf:
        szf.writeall(ruta_archivo, arcname=os.path.basename(ruta_archivo))
    print(f'Se ha creado el archivo {ruta_7z} exitosamente.')

# Ejemplo de uso
# ruta_archivo = '/ruta/del/archivo.txt'  # Ruta del archivo a comprimir
# ruta_7z = '/ruta/del/archivo.7z'  # Ruta del archivo .7z a crear


