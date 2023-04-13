import hashlib
import os.path

import flask
import sqlalchemy
from flask import request
from flask_jwt_extended import jwt_required, create_access_token, get_jwt_identity
from flask_restful import Resource
from sqlalchemy.exc import IntegrityError
from datetime import datetime
from modelos import db, User, Tarea, TareaSchema
from app import ROOT_PATH

tarea_schema = TareaSchema()

class VistaSignUp(Resource):

    def post(self):
        if request.json['password1'] != request.json['password2']:
            return 'Las contraseñas no coinciden', 400

        usuario = User.query.filter(User.username == request.json["username"]).first()
        if usuario is not None:
            return 'El usuario {} ya existe'.format(request.json["username"]), 409

        usuario = User.query.filter(User.username == request.json["email"]).first()
        if usuario is not None:
            return 'Ya existe un usuario registrado con el email: {}'.format(request.json["email"]), 409

        contrasena_encriptada = hashlib.md5(request.json["password1"].encode('utf-8')).hexdigest()
        usuario_nuevo = User(
            username=request.json["username"],
            password=contrasena_encriptada,
            email=request.json["email"]
        )
        db.session.add(usuario_nuevo)
        db.session.commit()

        return 'Registro exitoso', 201


class VistaLogIn(Resource):

    def post(self):
        contrasena_encriptada = hashlib.md5(request.json["contrasena"].encode('utf-8')).hexdigest()
        usuario = User.query.filter(
            User.username == request.json['username'] and User.password == contrasena_encriptada).first()

        if usuario is None:
            return 'El nombre de usuario o contraseña son incorrectos', 401

        token_de_acceso = create_access_token(identity=usuario.id)
        return {
            "mensaje": "Inicio de sesión exitoso",
            "token": token_de_acceso,
            "id": usuario.id
        }, 200


class VistaTareas(Resource):

    @jwt_required()
    def get(self):
        id_usuario = get_jwt_identity()
        usuario = User.query.get_or_404(id_usuario)
        return [tarea_schema.dump(tarea) for tarea in usuario.tareas]

    @jwt_required()
    def post(self):
        id_usuario = get_jwt_identity()
        usuario = User.query.get_or_404(id_usuario)

        file = request.files['file']
        filename = file.filename

        nueva_tarea = Tarea(
            nombre_archivo=filename.split('.')[0],
            old_format=filename.split('.')[1],
            new_format=request.form['newFormat'],
            usuario=id_usuario
        )

        db.session.add(nueva_tarea)

        target_folder = os.path.join(ROOT_PATH, '/files/{}/'.format(usuario.username))
        if not os.path.exists(target_folder):
            os.makedirs(target_folder)

        file.save(os.path.join(target_folder, file.filename))

        db.session.commit()

        return 'Archivo cargado', 200


class VistaTarea(Resource):

    @jwt_required()
    def get(self, id_tarea):
        id_usuario = get_jwt_identity()
        usuario = User.query.get_or_404(id_usuario)

        tarea = Tarea.query.get_or_404(id_tarea)
        if tarea.usuario != id_usuario:
            return 'Acceso negado', 403

        return tarea_schema.dump(tarea), 200

    @jwt_required()
    def delete(self, id_tarea):
        id_usuario = get_jwt_identity()
        usuario = User.query.get_or_404(id_usuario)

        tarea = Tarea.query.get_or_404(id_tarea)
        if tarea.usuario != id_usuario:
            return 'Acceso negado', 403

        db.session.delete(tarea)
        db.session.commit()

        return 'Tarea eliminada', 200
