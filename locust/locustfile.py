import os
import logging
from pathlib import Path
from locust import HttpUser, between, task, FastHttpUser, constant
from requests_toolbelt.multipart.encoder import MultipartEncoder

LOGGER = logging.getLogger()

if os.environ["SHAPE"] == "LOGIN":

    class LoginUser(HttpUser):
        wait_time = constant(0.9)

        @task
        def login(self):
            response = self.client.post("/api/auth/login", json={"username": "test", "password": "123asd456"})
            if response.status_code == 200:
                LOGGER.info("Login successful")
            else:
                LOGGER.error("Login failed")

elif os.environ["SHAPE"] == "CREATE_TASK":
    class FileUploadUser(HttpUser):
        wait_time = constant(1)
        token = None

        def on_start(self):
            if self.token is None:
                token = self.login()
                self.token = token
                self.client.headers = {'Authorization': f'Bearer {token}'}

        def login(self):
            with self.client.post("/api/auth/login", json={
                "username": "test",
                "password": "123asd456"
            }, catch_response=True, headers={'Content-Type': 'application/json'}) as response:
                if response.status_code != 200:
                    LOGGER.error("Login failed")
                else:
                    LOGGER.info("Login successful")
                    token = response.json().get("token")
                    return token


        @task
        def upload_file(self):
            location = Path(__file__).absolute().parent
            file_path = f"{location}/asana.pptx"

            LOGGER.info("Uploading file %s", file_path)

            data  = MultipartEncoder(
                fields={
                    'newFormat': 'zip',
                    'file': ("asana.pptx", open(file_path, 'rb'), 'application/vnd.openxmlformats-officedocument.presentationml.presentation')
                }
            )

            response = self.client.post(
                "/api/tasks",
                data=data,
                headers={'Content-Type': data.content_type}
            )

            if response.status_code != 200:
                LOGGER.error("File upload failed %s", response.status_code)
            else:
                LOGGER.info("File upload successful")
else:
    raise Exception("SHAPE env variable not set")