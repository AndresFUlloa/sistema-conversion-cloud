import os
import logging
from typing import Optional
from flask import Flask
from flask_cors import CORS
from celery import Celery, Task
from flask_restful import Api
from logging.config import dictConfig
from compressor.api.views import initialize_routes
from compressor.extensions import db, jwt, migrate

LOGGER = logging.getLogger()


def create_app(script_info=None)  -> Flask:
    dictConfig({
        'version': 1,
        'formatters': {'default': {
            'format': '[%(asctime)s] %(levelname)s in %(module)s: %(message)s',
        }},
        'handlers': {'wsgi': {
            'class': 'logging.StreamHandler',
            'stream': 'ext://flask.logging.wsgi_errors_stream',
            'formatter': 'default'
        }},
        'root': {
            'level': 'DEBUG',
            'handlers': ['wsgi']
        }
    })
    # instantiate the app
    app = Flask(
        __name__,
    )
    cors = CORS(app, resources={r"/api/*": {"origins": "*"}})
    api = Api(app, prefix="/api")

    # set config
    app_settings = os.getenv("APP_SETTINGS")
    app.config.from_object(app_settings)
    app.config.from_mapping(
        CELERY=dict(
            broker_url=app.config["CELERY_BROKER"],
            result_backend=app.config["CELERY_RESULT_BACKEND"],
            task_ignore_result=True,
        ),
    )
    app.config.from_prefixed_env()
    configure_extensions(app)
    celery_init_app(app)

    LOGGER.info('Starting app with %s settings', app_settings)

    initialize_routes(api)

    # shell context for flask cli
    app.shell_context_processor({"app": app})

    return app


def configure_extensions(app: Flask) -> None:
    """Configure flask extensions"""
    db.init_app(app)
    import compressor.models
    jwt.init_app(app)
    migrate.init_app(app, db)



def celery_init_app(app: Optional[Flask]) -> Celery:
    app = app or create_app()

    class FlaskTask(Task):
        def __call__(self, *args: object, **kwargs: object) -> object:
            with app.app_context():
                return self.run(*args, **kwargs)

    celery_app = Celery(app.name, task_cls=FlaskTask)
    celery_app.config_from_object(app.config["CELERY"])
    celery_app.set_default()
    app.extensions["celery"] = celery_app
    return celery_app