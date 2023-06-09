import logging
import os
import json
from google.cloud import pubsub_v1
from flask_jwt_extended import create_access_token, get_jwt_identity, jwt_required
from flask_restful import Api, Resource
from flask import request, send_file
from compressor.api.schemas.tasks import TaskSchema
from compressor.api.schemas.users import UserSchema, LoginSchema
from compressor.extensions import db
from compressor.models import User, Task, TaskStatus
from marshmallow import ValidationError
from google.cloud import storage

LOGGER = logging.getLogger()

user_schema = UserSchema()
login_schema = LoginSchema()
task_schema = TaskSchema()


class HealthView(Resource):
    @staticmethod
    def get():
        return {"status": "OK"}


class LoginView(Resource):
    @staticmethod
    def post():
        json_data = request.get_json()

        LOGGER.info("User login")

        if not json_data:
            return {"message": "No input data provided"}, 400

        try:
            data = login_schema.load(json_data)
        except ValidationError as err:
            return err.messages, 422

        user = User.query.filter(User.username == data.get('username')).first()

        if user is None:
            return {"message": "Username or password incorrect"}, 401

        token = create_access_token(identity=user.id)

        return {
                   "message": "Success",
                   "token": token,
                   "id": user.id
               }, 200


class SignUpView(Resource):
    @staticmethod
    def post():
        json_data = request.get_json()

        if not json_data:
            return {"message": "No input data provided"}, 400

        try:
            data = user_schema.load(json_data)
        except ValidationError as err:
            return err.messages, 422

        user = User.query.filter(User.username == data.username).first()
        if user is not None:
            return {"message": "User already exists"}, 409

        user = User.query.filter(User.email == data.email).first()
        if user is not None:
            return {"message": "User already exists"}, 409

        user = User(
            username=data.username,
            password=data.password,
            email=data.email
        )
        db.session.add(user)
        db.session.commit()

        return {"status": "OK"}


class TasksView(Resource):
    @jwt_required()
    def get(self):
        user_id = get_jwt_identity()
        user = User.query.get_or_404(user_id)

        return [task_schema.dump(task) for task in user.tasks]

    @jwt_required()
    def post(self):
        user_id = get_jwt_identity()
        user = User.query.get_or_404(user_id)

        new_format = request.form['newFormat']

        LOGGER.info("convert file to %s", new_format)

        uploaded_file = request.files.get("file")

        if not uploaded_file:
            return "No file uploaded.", 400

        filename = uploaded_file.filename
        new_task = Task(
            file_name=filename.split('.')[0],
            old_format=filename.split('.')[1],
            new_format=new_format,
            user_id=user_id
        )

        db.session.add(new_task)
        pos = Task.query.filter(Task.file_name.contains(filename.split('.')[0]), Task.user_id==user_id).count()
        
        LOGGER.info("user %s run jon in %s", user_id, pos)

        if pos > 1:
            filename = new_task.file_name + '_' + str(pos) + '.' + new_task.old_format
            new_task.file_name = filename.split('.')[0]

        target_path = f"{user.username}/{filename}"

        gcs = storage.Client()
        bucket = gcs.get_bucket(os.getenv("CLOUD_STORAGE_BUCKET"))
        blob = bucket.blob(target_path)

        blob.upload_from_string(
            uploaded_file.read(), content_type=uploaded_file.content_type
        )

        db.session.commit()

        publisher = pubsub_v1.PublisherClient()

        data_dict = {'path': target_path, 'file_name': filename, 'compression_type': new_task.new_format, 'task_id': new_task.id, 'target_folder': user.username}

        message_data = json.dumps(data_dict).encode('utf-8')

        topic_name = 'projects/{project_id}/topics/{topic}'.format(
            project_id=os.getenv('GOOGLE_CLOUD_PROJECT'),
            topic='compress',
        )
        future = publisher.publish(topic_name, data=message_data)
        future.result()

        return { "message": "File uploaded successfully"}, 200


class TaskView(Resource):
    @jwt_required()
    def get(self, task_id):
        user_id = get_jwt_identity()
        task = Task.query.get_or_404(task_id)

        if task.user_id != user_id:
            return {"message": "Access denied"}, 403

        return task_schema.dump(task), 200

    @jwt_required()
    def delete(self, task_id):
        user_id = get_jwt_identity()
        user = User.query.get_or_404(user_id)
        task = Task.query.get_or_404(task_id)

        if task.user_id != user_id:
            return {"message": "Access denied"}, 403

        if task.available:
           db.session.delete(task)
           db.session.commit()
           for extension in [task.old_format,task.new_format]:
               file_root = 'compressor/files/{}/{}.{}'.format(user.username, task.file_name,extension)
               os.remove(file_root)

        return {"message": "Task deleted successfully"}, 200


class FilesView(Resource):
    @jwt_required()
    def get(self, file_name):
        user_id = get_jwt_identity()
        user = User.query.get_or_404(user_id)

        task = Task.query.filter(
            Task.user_id==user.id,
            Task.file_name==file_name
        ).first()

        if task is None:
            return {"message": "File not found"}, 404

        file_name += '.' + (task.old_format if task.status == TaskStatus.UPLOADED else task.new_format)
        file_root = 'files/{}/{}'.format(user.username, file_name)
        return send_file(file_root, as_attachment=True)
        #attachment_filename=file_name)


def initialize_routes(api):
    api.add_resource(HealthView, '/health')

    api.add_resource(SignUpView, '/auth/sign-up')
    api.add_resource(LoginView, '/auth/login')

    api.add_resource(TasksView, '/tasks')
    api.add_resource(TaskView, '/tasks/<int:task_id>')

    api.add_resource(FilesView, '/files/<string:file_name>')