import base64
import json
import os
import pathlib
import time
from urllib.parse import urlparse

import pyautogui
import requests
import yaml
from flask import Flask, jsonify, request, send_from_directory

APP = Flask(__name__)
POLICY_PATH = pathlib.Path(os.environ.get("POLICY_PATH", "/opt/gui-app/allowed-operations.yml"))
SCREEN_DIR = pathlib.Path("/workspace/screenshots")
SCREEN_DIR.mkdir(parents=True, exist_ok=True)


def policy():
    if not POLICY_PATH.exists():
        return {"sites": []}
    return yaml.safe_load(POLICY_PATH.read_text()) or {"sites": []}


def site_rule(url: str):
    host = urlparse(url).hostname or ""
    for rule in policy().get("sites", []):
        if host == rule.get("host") or host.endswith("." + rule.get("host", "")):
            return rule
    return None


def screenshot(label: str):
    stamp = time.strftime("%Y%m%d-%H%M%S")
    path = SCREEN_DIR / f"{stamp}-{label}.png"
    pyautogui.screenshot(str(path))
    return path


def call_mistral(image_path: pathlib.Path, instruction: str):
    key = os.environ.get("MISTRAL_API_KEY")
    if not key:
        return {"status": "needs_configuration", "message": "MISTRAL_API_KEY is not configured"}
    base = os.environ.get("MISTRAL_API_BASE", "https://api.mistral.ai/v1").rstrip("/")
    model = os.environ.get("MISTRAL_MODEL", "pixtral-large-latest")
    encoded = base64.b64encode(image_path.read_bytes()).decode()
    payload = {
        "model": model,
        "temperature": 0,
        "response_format": {"type": "json_object"},
        "messages": [{"role": "user", "content": [
            {"type": "text", "text": (
                "Return JSON only with keys action, x, y, confidence, reason. "
                "Suggest a click only inside a clearly visible allowed UI control. "
                "Never suggest typing secrets, submit, purchase, delete, login, or navigation outside the policy. "
                f"Instruction: {instruction}"
            )},
            {"type": "image_url", "image_url": f"data:image/png;base64,{encoded}"}
        ]}]
    }
    response = requests.post(f"{base}/chat/completions", headers={"Authorization": f"Bearer {key}"}, json=payload, timeout=45)
    response.raise_for_status()
    content = response.json()["choices"][0]["message"]["content"]
    return json.loads(content) if isinstance(content, str) else content


@APP.get("/health")
def health():
    size = pyautogui.size()
    return jsonify({"ok": True, "display": os.environ.get("DISPLAY", ":99"), "screen": [size.width, size.height]})


@APP.post("/api/plan")
def plan_action():
    body = request.get_json(force=True) or {}
    instruction = str(body.get("instruction", "")).strip()
    if not instruction or len(instruction) > 500:
        return jsonify({"error": "instruction must be 1-500 characters"}), 400
    shot = screenshot("before-plan")
    try:
        result = call_mistral(shot, instruction)
    except Exception as exc:
        return jsonify({"error": "AI request failed", "detail": type(exc).__name__, "screenshot": shot.name}), 502
    return jsonify({"result": result, "screenshot": shot.name, "requires_validation": True})


@APP.post("/api/click")
def click_action():
    body = request.get_json(force=True) or {}
    url = str(body.get("url", ""))
    x, y = body.get("x"), body.get("y")
    rule = site_rule(url)
    shot = screenshot("before-click")
    if not rule:
        return jsonify({"error": "site is not allowed by policy", "screenshot": shot.name}), 403
    try:
        x, y = int(x), int(y)
    except (TypeError, ValueError):
        return jsonify({"error": "x and y must be integers", "screenshot": shot.name}), 400
    width, height = pyautogui.size()
    bounds = rule.get("click_bounds", {"x_min": 0, "y_min": 0, "x_max": width, "y_max": height})
    if not (bounds["x_min"] <= x <= bounds["x_max"] and bounds["y_min"] <= y <= bounds["y_max"]):
        return jsonify({"error": "coordinates outside policy bounds", "screenshot": shot.name}), 403
    if str(body.get("operation", "click")) not in rule.get("operations", []):
        return jsonify({"error": "operation is not allowed", "screenshot": shot.name}), 403
    pyautogui.click(x, y)
    after = screenshot("after-click")
    return jsonify({"ok": True, "x": x, "y": y, "before": shot.name, "after": after.name})


@APP.get("/screenshots/<path:name>")
def get_screenshot(name):
    return send_from_directory(SCREEN_DIR, name)


if __name__ == "__main__":
    APP.run(host="0.0.0.0", port=int(os.environ.get("PORT", "8080")), threaded=True)
