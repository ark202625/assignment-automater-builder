import os
from flask import Flask, jsonify, request
from google import genai
from github import Github

app = Flask(__name__)

GEMINI_API_KEY = os.environ.get("GEMINI_API_KEY")
GITHUB_TOKEN = os.environ.get("GITHUB_TOKEN")

REPO_NAME = "ark202625/assignment-automater-builder"

if GEMINI_API_KEY:
    gemini = genai.Client(api_key=GEMINI_API_KEY)
else:
    gemini = None


def get_github_repo():
    if GITHUB_TOKEN:
        github = Github(GITHUB_TOKEN)
    else:
        github = Github()

    return github.get_repo(REPO_NAME)


def read_github_file(path):
    repo = get_github_repo()

    try:
        file = repo.get_contents(path)
        return file.decoded_content.decode("utf-8")
    except Exception as exc:
        return f"[FILE ERROR: {path}] {exc}"


def get_project_state():
    return {
        "project_state": read_github_file(".builder/PROJECT-STATE.json"),
        "build_queue": read_github_file(".builder/BUILD-QUEUE.json"),
        "test_results": read_github_file(".builder/TEST-RESULTS.json"),
        "agent_rules": read_github_file(".builder/AGENT-RULES.md"),
        "architecture": read_github_file(".builder/ARCHITECTURE.md"),
        "changelog": read_github_file(".builder/CHANGELOG.md")
    }


@app.get("/")
def index():
    return jsonify({
        "service": "Assignment Automater Controller",
        "status": "online",
        "gemini_configured": gemini is not None,
        "github_configured": True,
        "repository": REPO_NAME
    })


@app.get("/health")
def health():
    return jsonify({
        "status": "healthy",
        "gemini_configured": gemini is not None,
        "github_configured": True
    })


@app.get("/state")
def state():
    try:
        project = get_project_state()

        return jsonify({
            "status": "controller_ready",
            "repository": REPO_NAME,
            "state": project
        })

    except Exception as exc:
        return jsonify({
            "status": "error",
            "error": str(exc)
        }), 500


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
            "Analyze the current Assignment Automater project and determine the safest next development task."
        )

        project = get_project_state()

        prompt = f"""
You are the autonomous AI controller for the Assignment Automater project.

You must reason from the actual repository state supplied below.

USER TASK:
{task}

PROJECT STATE:
{project["project_state"]}

BUILD QUEUE:
{project["build_queue"]}

TEST RESULTS:
{project["test_results"]}

AGENT RULES:
{project["agent_rules"]}

ARCHITECTURE:
{project["architecture"]}

CHANGELOG:
{project["changelog"]}

Rules:
1. Do not invent assignment requirements.
2. Do not hardcode an EXP number or PDF filename.
3. Assignment PDFs are runtime/test inputs.
4. Respect the existing project architecture.
5. Prefer completing READY tasks before inventing new tasks.
6. Identify the safest concrete next engineering action.
7. Mention the exact files that should be changed.
8. Do not claim that a task is completed unless the supplied state proves it.

Return:
1. Current project assessment
2. Recommended next task
3. Reason
4. Files to modify
5. Validation required
"""

        response = gemini.models.generate_content(
            model="gemini-3.8-flash",
            contents=prompt
        )

        return jsonify({
            "accepted": True,
            "repository": REPO_NAME,
            "decision": response.text
        })

    except Exception as exc:
        print("CONTROLLER ERROR:", repr(exc), flush=True)

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