import enum
import datetime
from compressor.extensions import db



class TaskStatus(enum.Enum):
    UPLOADED = 1
    PROCESSED = 2


class Task(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    file_name = db.Column(db.String(512))
    old_format = db.Column(db.String(8))
    new_format = db.Column(db.String(8))
    available = db.Column(db.Boolean, default=False)
    status = db.Column(db.Enum(TaskStatus), default=TaskStatus.UPLOADED)
    created_at = db.Column(db.DateTime, default=datetime.datetime.utcnow())
    user_id = db.Column(db.Integer, db.ForeignKey('user.id'))


