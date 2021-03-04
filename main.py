
from flask import Flask
import google.cloud.logging
from xialib.service import service_factory

app = Flask(__name__)


# Log configuration
client = google.cloud.logging.Client()
client.get_default_handler()
client.setup_logging()


@app.route('/')
def hello_world():
    return 'Hello World!'


if __name__ == '__main__':
    app.run()
