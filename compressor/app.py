import os
import logging
import sentry_sdk
from sentry_sdk.integrations.flask import FlaskIntegration
from flask import Flask
from flask_cors import CORS
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

    sentry_sdk.init(
        dsn="https://94deec57d6044edc91631216c1fb701b@o103299.ingest.sentry.io/4505143285121024",
        integrations=[
            FlaskIntegration(),
        ],
        traces_sample_rate=1.0,
    )

    # instantiate the app
    app = Flask(
        __name__,
    )
    cors = CORS(app, resources={r"/api/*": {"origins": "*"}})
    api = Api(app, prefix="/api")

    # set config
    app_settings = os.getenv("APP_SETTINGS")
    app.config.from_object(app_settings)
    app.config.from_prefixed_env()
    configure_extensions(app)

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
