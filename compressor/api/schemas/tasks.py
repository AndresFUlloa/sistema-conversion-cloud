from flask_marshmallow.fields import fields

from compressor.extensions import ma, db
from compressor.models.tasks import Task


class EnumToDict(fields.Field):
    def _serialize(self, value, attr, obj, **kwargs):
        if value is None:
            return None
        return {'key': value.name, 'value': value.value}


class TaskSchema(ma.SQLAlchemyAutoSchema):
    status = EnumToDict(attribute='status')
    new_format = EnumToDict(attribute='new_format')

    class Meta:
        model = Task
        sqla_session = db.session
        include_relationships = True
        load_instance = True

    id = fields.String()