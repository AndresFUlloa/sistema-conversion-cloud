from flask_restful import Api, Resource
from compressor.tasks.example import add_together


class HealthView(Resource):
    def get(self):
        add_together.delay(1, 1)
        return {"status": "OK"}


def initialize_routes(api):
    api.add_resource(HealthView, '/health')

#
# @main_blueprint.route("/health", methods=["GET"])
# def health_check():
#     response_object = {
#         "status": "OK",
#     }
#
#     add_together.delay(1,1)
#
#     return jsonify(response_object), 202