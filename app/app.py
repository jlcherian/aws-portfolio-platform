import os
from flask import Flask, jsonify

app = Flask(__name__)
VERSION = os.environ.get("APP_VERSION", "local")


@app.get("/")
def home():
    return f"<h1>Joel's portfolio app</h1><p>Version: {VERSION}</p>"


@app.get("/health")
def health():
    return jsonify(status="ok")