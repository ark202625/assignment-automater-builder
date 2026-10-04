import os
from flask import Flask, jsonify, request

app = Flask(__name__)

@app.get("/")
def index():
    return jsonify({
        "service": "Assignment Automater Controller",
        "status": "online"
    })

@app.get("/health")
def health():
    return jsonify({
        "status": "healthy"
    })

@app.get("/state")
def state():
    return jsonify({
        "status": "not_configured",
        "message": "Cloud controller is online. GitHub/Gemini execution will be connected next."
    })

@app.post("/trigger")
def trigger():
    return jsonify({
        "accepted": False,
        "message": "Controller endpoint is ready; autonomous workflow is not connected yet."
    }), 501

@app.post("/runner/heartbeat")
def runner_heartbeat():
    return jsonify({
        "accepted": True,
        "message": "Runner heartbeat received."
    })

@app.post("/runner/result")
def runner_result():
    data = request.get_json(silent=True) or {}

    return jsonify({
        "accepted": True,
        "received": data
    })

if __name__ == "__main__":
    port = int(os.environ.get("PORT", "10000"))
    app.run(host="0.0.0.0", port=port)
