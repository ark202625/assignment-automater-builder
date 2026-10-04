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

    data = request.get_json(silent=True) or {}

    task = data.get(
        "task",
        "Analyze the current Assignment Automater project and identify the next development task."
    )

    prompt = f"""
You are the AI controller for the Assignment Automater project.

Your job is to analyze the supplied task and determine the safest next engineering action.

Task:
{task}

Return:
1. Decision
2. Reason
3. Next action
4. Files that should be changed, if any

Do not invent assignment requirements.
Do not hardcode a specific EXP number or PDF.
Keep the project generic.
"""

    response = gemini.models.generate_content(
        model="gemini-2.5-flash",
        contents=prompt
    )

    return jsonify({
        "accepted": True,
        "decision": response.text
    })


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