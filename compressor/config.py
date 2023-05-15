import os

basedir = os.path.abspath(os.path.dirname(__file__))



class BaseConfig(object):
    """Base configuration."""
    CLOUD_STORAGE_BUCKET = os.getenv("CLOUD_STORAGE_BUCKET")
    SQLALCHEMY_DATABASE_URI = f"postgresql://{os.getenv('POSTGRES_USER')}:{os.getenv('POSTGRES_PASSWORD')}@{os.getenv('POSTGRES_HOST')}:{os.getenv('POSTGRES_PORT')}/{os.getenv('POSTGRES_DB')}"
    JWT_SECRET_KEY = "QeThWmZq4t7w!z%C*F)J@NcRfUjXn2r5"


class DevelopmentConfig(BaseConfig):
    """Development configuration."""
    DEBUG = True



class ProductionConfig(BaseConfig):
    """Production configuration."""
