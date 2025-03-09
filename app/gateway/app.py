from flask import Flask, jsonify
import os
import requests

app = Flask(__name__)

@app.route("/", methods=["GET"])
def home():
    backend_url = os.getenv("BACKEND_URL") or "http://backend:80"  # Using Kubernetes DNS
    try:
        response = requests.get(backend_url)
        response.raise_for_status()
        data = response.json()
        return jsonify({"message": "Response from infinity-pool database", "data": data})
    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == "__main__":
    print(os.getenv("BACKEND_URL") or "http://backend:80")
    app.run(host="0.0.0.0", port=80)
