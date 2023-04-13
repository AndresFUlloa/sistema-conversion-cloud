from flask import Flask
from flask_cors import CORS
from flask_restful import Api
from sqlalchemy import create_engine

from modelos import db
from vistas import VistaSignUp, VistaLogIn, VistaTareas, VistaTarea

app = Flask(__name__)
ROOT_PATH = app.root_path
# DATABASE_URL="postgres://${POSTGRES_USER}:${POSTGRES_PASSWORD}@${POSTGRES_HOST}:${POSTGRES_PORT}/${POSTGRES_DB}"
app.config['SQLALCHEMY_DATABASE_URI'] = 'postgresql+psycopg2://app:@123Asd456@postgresql:5432/app'
app.config['JWT_SECRET_KEY'] = 'frase-secreta'
app.config['PROPAGATE_EXCEPTIONS'] = True

app_context = app.app_context()
app_context.push()

db.init_app(app)

engine = create_engine("postgresql://app:@123Asd456@postgresql:5432/app")

connect = engine.connect()

db.create_all()

cors = CORS(app, resources={r"*": {"origins": "*"}},
            origin=['*', 'http://0.0.0.0', 'http://localhost', 'http://127.0.0.1/', 'localhost'])

api = Api(app)
api.add_resource(VistaSignUp, '/api/auth/signup')
api.add_resource(VistaLogIn, '/api/auth/login')
api.add_resource(VistaTareas, '/api/tasks')
api.add_resource(VistaTarea, '/api/task/id_tarea')
