    import os
from flask import Flask, jsonify, request
from google import genai
from github import Github

app = Flask(__name__)

GEMINI_API_KEY = os.environ.get("GEMINI_API_KEY")
GITHUB_TOKEN = os.environ.get("GITHUB_TOKEN")

REPO_NAME = "ark202625/assignment-automater-builder"

# ---------------------------------------------------------
# Gemini
# ---------------------------------------------------------

if GEMINI_API_KEY:
    gemini = genai.Client(api_key=GEMINI_API_KEY)
else:
    gemini = None


# ---------------------------------------------------------
# GitHub
# ---------------------------------------------------------

def get_github_repo():
    if not GITHUB_TOKEN:
        raise RuntimeError("GITHUB_TOKEN is not configured")

    github = Github(GITHUB_TOKEN)

    user = github.get_user()
    repo = github.get_repo(REPO_NAME)

    return github, user.login, repo


def read_github_file(path):
    github, login, repo = get_github_repo()

    try:
        file = repo.get_contents(path)

        if isinstance(file, list):
            raise RuntimeError(
                f"GitHub path is a directory, not a file: {path}"
            )

        return file.decoded_content.decode("utf-8")

    except Exception as exc:
        return f"[FILE ERROR: {path}] {exc}"


def get_project_state():
    return {
        "project_state": read_github_file(
            ".builder/PROJECT-STATE.json"
        ),
        "build_queue": read_github_file(
            ".builder/BUILD-QUEUE.json"
        ),
        "test_results": read_github_file(
            ".builder/TEST-RESULTS.json"
        ),
        "agent_rules": read_github_file(
            ".builder/AGENT-RULES.md"
        ),
        "architecture": read_github_file(
            ".builder/ARCHITECTURE.md"
        ),
        "changelog": read_github_file(
            ".builder/CHANGELOG.md"
        )
    }


# ---------------------------------------------------------
# GitHub write support
# ---------------------------------------------------------

def write_github_file(path, content, commit_message):
    github, login, repo = get_github_repo()

    try:
        existing = repo.get_contents(path)

        result = repo.update_file(
            path=path,
            message=commit_message,
            content=content,
            sha=existing.sha,
            branch="main"
        )

        return {
            "success": True,
            "action": "updated",
            "path": path,
            "commit": result["commit"].sha,
            "github_user": login
        }

    except Exception:
        result = repo.create_file(
            path=path,
            message=commit_message,
            content=content,
            branch="main"
        )

        return {
            "success": True,
            "action": "created",
            "path": path,
            "commit": result["commit"].sha,
            "github_user": login
        }


# ---------------------------------------------------------
# Root
# ---------------------------------------------------------

@app.get("/")
def index():
    return jsonify({
        "service": "Assignment Automater Controller",
        "status": "online",
        "gemini_configured": gemini is not None,
        "github_configured": GITHUB_TOKEN is not None,
        "repository": REPO_NAME
    })


# ---------------------------------------------------------
# Health
# ---------------------------------------------------------

@app.get("/health")
def health():
    return jsonify({
        "status": "healthy",
        "gemini_configured": gemini is not None,
        "github_configured": GITHUB_TOKEN is not None
    })


# ---------------------------------------------------------
# Project state
# ---------------------------------------------------------

@app.get("/state")
def state():
    try:
        github, login, repo = get_github_repo()

        project = get_project_state()

        return jsonify({
            "status": "controller_ready",
            "github_authenticated": True,
            "github_user": login,
            "repository": REPO_NAME,
            "state": project
        })

    except Exception as exc:
        return jsonify({
            "status": "error",
            "github_authenticated": False,
            "error": str(exc)
        }), 500


# ---------------------------------------------------------
# Gemini controller
# ---------------------------------------------------------

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
2. Do not hardcode an EXP number.
3. Do not hardcode an assignment PDF filename.
4. Assignment PDFs are runtime/test inputs.
5. Respect the existing project architecture.
6. Prefer completing READY tasks before inventing new tasks.
7. Identify the safest concrete next engineering action.
8. Mention exact files that should be changed.
9. Specify how the change must be validated.
10. Do not claim a task is completed unless the supplied state proves it.

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

        print(
            "CONTROLLER ERROR:",
            repr(exc),
            flush=True
        )

        return jsonify({
            "accepted": False,
            "error": str(exc)
        }), 500


# ---------------------------------------------------------
# GitHub file write endpoint
# ---------------------------------------------------------

@app.post("/github/write")
def github_write():

    try:

        data = request.get_json(silent=True) or {}

        path = data.get("path")
        content = data.get("content")
        commit_message = data.get(
            "commit_message",
            "Update project file"
        )

        if not path:
            return jsonify({
                "accepted": False,
                "error": "Missing path"
            }), 400

        if content is None:
            return jsonify({
                "accepted": False,
                "error": "Missing content"
            }), 400

        result = write_github_file(
            path,
            content,
            commit_message
        )

        return jsonify({
            "accepted": True,
            "repository": REPO_NAME,
            "result": result
        })

    except Exception as exc:

        print(
            "GITHUB WRITE ERROR:",
            repr(exc),
            flush=True
        )

        return jsonify({
            "accepted": False,
            "error": str(exc)
        }), 500


# ---------------------------------------------------------
# Windows runner heartbeat
# ---------------------------------------------------------

@app.post("/runner/heartbeat")
def runner_heartbeat():

    return jsonify({
        "accepted": True,
        "message": "Runner heartbeat received."
    })


# ---------------------------------------------------------
# Windows runner result
# ---------------------------------------------------------

@app.post("/runner/result")
def runner_result():

    data = request.get_json(silent=True) or {}

    return jsonify({
        "accepted": True,
        "received": data
    })


# ---------------------------------------------------------
# Local development
# ---------------------------------------------------------

if __name__ == "__main__":

    port = int(
        os.environ.get(
            "PORT",
            "10000"
        )
    )

    app.run(
        host="0.0.0.0",
        port=port
    )