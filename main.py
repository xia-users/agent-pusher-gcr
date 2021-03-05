import os
import base64
import gzip
import json
from flask import Flask, render_template, request
import google.cloud.logging
from xialib.service import service_factory

app = Flask(__name__)


# Configuration Load
with open(os.path.join(".", 'config', 'global_conn_config.json')) as fp:
    global_conn_config = json.load(fp)
with open(os.path.join('.', 'config', 'object_config.json')) as fp:
    object_config = json.load(fp)

# Global Object Factory
global_connectors = service_factory(global_conn_config)

# Log configuration
client = google.cloud.logging.Client()
client.get_default_handler()
client.setup_logging()


@app.route('/', methods=['GET', 'POST'])
def main():
    if request.method == 'GET':
        pusher = service_factory(object_config, global_connectors)
        return render_template("index.html"), 200
    pusher = service_factory(object_config, global_connectors)

    envelope = request.get_json()
    if not envelope:
        return "no Pub/Sub message received", 204
    if not isinstance(envelope, dict) or 'message' not in envelope:
        return "invalid Pub/Sub message format", 204
    data_header = envelope['message']['attributes']
    data_body = json.loads(gzip.decompress(base64.b64decode(envelope['message']['data'])).decode())

    if pusher.push_data(data_header, data_body):
        return "message received", 200
    else:  # pragma: no cover
        return "message to be resent", 400  # pragma: no cover


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=int(os.environ.get('PORT', 8080)))  # pragma: no cover
