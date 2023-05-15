import logging
import os
from flask.cli import FlaskGroup
from google.cloud import pubsub_v1

from compressor.app import create_app
from compressor.extensions import db
from compressor.tasks.files import run_compress_callback

LOGGER = logging.getLogger()

current_app = create_app()
cli = FlaskGroup(create_app=create_app)


@cli.command("run_worker")
def run_worker():
    subscription_name = 'projects/{project_id}/subscriptions/{sub}'.format(
        project_id=os.getenv('GOOGLE_CLOUD_PROJECT'),
        sub='compress-subscription',  # Set this to something appropriate.
    )

    # Limit the subscriber to only have ten outstanding messages at a time.
    flow_control = pubsub_v1.types.FlowControl(max_messages=7)

    LOGGER.info("Listening for messages on %s", subscription_name)

    with pubsub_v1.SubscriberClient() as subscriber:
        future = subscriber.subscribe(subscription_name, callback=run_compress_callback, flow_control=flow_control)

        try:
            future.result()
        except KeyboardInterrupt:
            future.cancel()


if __name__ == "__main__":
    cli()