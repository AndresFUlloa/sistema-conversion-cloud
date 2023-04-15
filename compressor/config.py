import os

basedir = os.path.abspath(os.path.dirname(__file__))



class BaseConfig(object):
    """Base configuration."""
    CELERY_BROKER = os.getenv("CELERY_BROKER")
    CELERY_RESULT_BACKEND = os.getenv("CELERY_RESULT_BACKEND")
    SQLALCHEMY_DATABASE_URI = f"postgresql://{os.getenv('POSTGRES_USER')}:{os.getenv('POSTGRES_PASSWORD')}@{os.getenv('POSTGRES_HOST')}:{os.getenv('POSTGRES_PORT')}/{os.getenv('POSTGRES_DB')}"
    CELERY = "config.ProductionCeleryConfig"
    JWT_SECRET_KEY = "QeThWmZq4t7w!z%C*F)J@NcRfUjXn2r5"


class DevelopmentConfig(BaseConfig):
    """Development configuration."""
    DEBUG = True
    CELERY = "config.DevelopmentCeleryConfig"



class ProductionConfig(BaseConfig):
    """Production configuration."""


class BaseCeleryConfig:
    enable_utc = True
    timezone = 'America/Bogota'


class DevelopmentCeleryConfig(BaseCeleryConfig):
    pass


class ProductionCeleryConfig(BaseCeleryConfig):
    pass


