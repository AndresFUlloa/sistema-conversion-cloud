import logging
from pathlib import Path
from locust import HttpUser, between, task

LOGGER = logging.getLogger()


class LoginUser(HttpUser):
    wait_time = between(1, 2)
    host = "https://1cc6-161-10-84-30.ngrok.io"

    @task
    def login(self):
        response = self.client.post("/api/auth/login", json={"username": "test", "password": "123asd456"})
        if response.status_code == 200:
            LOGGER.info("Login successful")
        else:
            LOGGER.error("Login failed")


class FileUploadUser(HttpUser):
    wait_time = between(1, 5)
    host = "https://1cc6-161-10-84-30.ngrok.io"
    token = None

    def on_start(self):
        token = self.login()
        self.client.headers = {'Authorization': f'Bearer {token}', 'Content-Type': 'application/json'}

    def login(self):
        with self.client.post("/api/auth/login", json={"username": "test", "password": "123asd456"}, catch_response=True) as response:
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
        with open(file_path, "rb") as file:
            LOGGER.info("Uploading file %s", file)
            response = self.client.post("/api/tasks", files={"file": file}, data={"new_format": "zip"}, verify=False)
            if response.status_code != 200:
                LOGGER.error("File upload failed %s", response.status_code)
            else:
                LOGGER.info("File upload successful")