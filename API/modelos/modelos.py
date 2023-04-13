import datetime

from flask_sqlalchemy import SQLAlchemy
from marshmallow import fields, Schema
from marshmallow_sqlalchemy import SQLAlchemyAutoSchema
from app import db
import enum

class EstadoTarea(enum.Enum):
    UPLOADED = 1
    PROCESSED = 2

class EnumADiccionario(fields.Field):
    def _serialize(self, value, attr, obj, **kwargs):
        if value is None:
            return None
        return {'llave': value.name, 'valor': value.value}

class User(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(64))
    password = db.Column(db.String(256))
    email = db.Column(db.String(256))
    tareas = db.relationship('Tarea', cascade='all, delete, delete-orphan')


class Tarea(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    nombre_archivo = db.Column(db.String(512))
    old_format = db.Column(db.String(3))
    new_format = db.Column(db.String(3))
    disponible = db.Column(db.Boolean, default=False)
    estado = db.Column(db.Enum(EstadoTarea), default=EstadoTarea.UPLOADED)
    fecha_subido = db.Column(db.DateTime, default=datetime.datetime.utcnow())
    usuario = db.Column(db.Integer, db.ForeignKey('usuario.id'))


class TareaSchema(SQLAlchemyAutoSchema):
    estado = EnumADiccionario(attribute=('estado'))

    class Meta:
        model = Tarea
        include_relationships = True
        load_instance = True

    id = fields.String()