from locust import HttpUser, between, task

class LoginUser(HttpUser):
    wait_time = between(1, 2)
    host = "https://a639-161-10-84-30.ngrok.io"

    @task
    def login(self):
        response = self.client.post("/api/auth/login", json={"username": "test", "password": "123asd456"})
        if response.status_code == 200:
            print("Login exitoso")
        else:
            print("Error al hacer login")