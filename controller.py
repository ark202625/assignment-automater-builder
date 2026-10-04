import os
from flask import Flask, jsonify, request
from google import genai

app = Flask(__name__)

GEMINI_API_KEY = os.environ.get("GEMINI_API_KEY")

if GEMINI_API_KEY:
    gemini = genai.Client(api_key=GEMINI_API_KEY)
else:
    gemini = None


@app.get("/")
def index():
    return jsonify({
        "service": "Assignment Automater Controller",
        "status": "online",
        "gemini_configured": gemini is not None
    })


@app.get("/health")
def health():
    return jsonify({
        "status": "healthy",
        "gemini_configured": gemini is not None
    })


@app.get("/state")
def state():
    return jsonify({
        "status": "controller_ready",
        "gemini_configured": gemini is not None
    })


@app.post("/trigger")
def trigger():
    if gemini is None:
        return jsonify({
            "accepted": False,
            "error": "GEMINI_API_KEY is not configured"
        }), 500

    try:
        data = request.get_json(silent=True) or {}

        task = data.get(
            "task",
            "Say hello and confirm that you are the AI controller for Assignment Automater."
        )

        prompt = f"""
You are the AI controller for the Assignment Automater project.

Task:
{task}

Respond briefly and confirm that you received the task.
"""

        response = gemini.models.generate_content(
            model="gemini-3.8-flash",
            contents=prompt
        )

        return jsonify({
            "accepted": True,
            "decision": response.text
        })

    except Exception as exc:
        print("GEMINI ERROR:", repr(exc), flush=True)

        return jsonify({
            "accepted": False,
            "error": str(exc)
        }), 500


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