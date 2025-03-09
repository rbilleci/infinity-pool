from flask import Flask, jsonify
import os
import requests

app = Flask(__name__)

@app.route("/", methods=["GET"])
def home():
    backend_url = os.getenv("BACKEND_URL") or "http://backend:80"  # Using Kubernetes DNS
    try:
        app.logger.warn("performing request to %s", backend_url)
        response = requests.get(backend_url)
        response.raise_for_status()
        data = response.json()
        return jsonify({"message": "Response from infinity-pool database", "data": data})
    except Exception as e:
        app.logger.error(e)
        return jsonify({"error": str(e)}), 500

@app.route("/health", methods=["GET"])
def health():
    return "OK"

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=80)
