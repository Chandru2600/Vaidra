import google.generativeai as genai
import PIL.Image
import json
import os
import traceback
from app.config import settings

# Safety prompt version — bump this whenever the guardrail wording changes,
# so audit rows (AiInteractionLog) can be traced to the exact prompt used.
PROMPT_VERSION = "v2-safety-2026-11-25"
MODEL_NAME = "gemini-2.5-flash"

DISCLAIMER = (
    "Preliminary visual guidance only — not a diagnosis. "
    "AI can be wrong. See a qualified doctor for a real diagnosis."
)

# Checklist §6 safety rules, enforced in the prompt itself:
# - NEVER state a diagnosis, NEVER prescribe, NEVER name medicines/dosages.
# - ALWAYS frame output as preliminary visual guidance with uncertainty.
# - Escalate to 112 when danger signs are visible.
PROMPT = """
You are a first-aid information assistant. You are NOT a doctor.
You must NEVER give a diagnosis, NEVER name a disease as a diagnosis,
and NEVER prescribe any medicine or give any dosage.

Analyze the image and return JSON with these fields:
- condition: (string) A neutral description of what is visible in general
  terms, for example "red, irritated patch of skin". Do NOT name a disease
  or condition as a diagnosis. Phrase it as a possible appearance only.
- confidence: (number) 0-100, how confident you are in the visual
  description (not in a diagnosis).
- severity: (string) One of ["MINOR", "MODERATE", "URGENT"]. Use URGENT if
  the image suggests heavy bleeding, severe burns, rapidly spreading
  redness, or any other danger sign.
- steps: (list of strings) Safe general first-aid information only. Never
  include medicine names or dosages. If severity is URGENT, the first step
  must be "Call 112 immediately".
- warnings: (list of strings) Warning signs to watch for.
- disclaimer: (string) "Preliminary visual guidance only — not a diagnosis.
  AI can be wrong. See a qualified doctor for a real diagnosis."
- uncertainty: (string) One of ["low", "medium", "high"] — how uncertain
  this visual assessment is.

Return ONLY raw JSON, no markdown formatting.
"""


def _fallback(condition: str, steps: list, warnings: list) -> dict:
    return {
        "condition": condition,
        "confidence": 0.0,
        "severity": "MINOR",
        "steps": steps,
        "warnings": warnings,
        "disclaimer": DISCLAIMER,
        "uncertainty": "high",
    }


def analyze_image(file_path: str):
    """
    Send image to Google Gemini for analysis using PIL to load the image.
    Returns structured JSON with keys: condition, confidence, severity,
    steps, warnings, disclaimer, uncertainty.

    The output is preliminary visual guidance — never a diagnosis.
    """
    print(f"Analyzing image at: {file_path}")

    if not settings.GEMINI_API_KEY:
        print("ERROR: GEMINI_API_KEY is not set.")
        raise ValueError("GEMINI_API_KEY is not set.")

    try:
        genai.configure(api_key=settings.GEMINI_API_KEY)

        print(f"Using model: {MODEL_NAME} (prompt {PROMPT_VERSION})")
        model = genai.GenerativeModel(MODEL_NAME)

        print("Loading image with PIL...")
        img = PIL.Image.open(file_path)

        print("Sending request to Gemini...")
        response = model.generate_content([PROMPT, img])
        print("Response received from Gemini.")

        try:
            content = response.text
        except Exception as e:
            print(f"Gemini response has no text (likely safety filter): {e}")
            return _fallback(
                "Analysis blocked by AI safety filters",
                ["Consult a real doctor — AI cannot analyze this image.", "Ensure the image is clear."],
                ["AI refused to analyze image."],
            )

        # Strip markdown if present
        if content.startswith("```json"):
            content = content.replace("```json", "").replace("```", "")
        elif content.startswith("```"):
            content = content.replace("```", "")

        print("Parsing JSON response...")
        result = json.loads(content.strip())
        # Guarantee the safety fields even if the model omits them.
        result.setdefault("disclaimer", DISCLAIMER)
        result.setdefault("uncertainty", "high")
        if result.get("uncertainty") not in ("low", "medium", "high"):
            result["uncertainty"] = "high"
        return result

    except Exception as e:
        print(f"CRITICAL ERROR in analyze_image: {e}")
        traceback.print_exc()
        # Fallback to prevent 500 error
        return _fallback(
            f"AI Service Error: {str(e)[:50]}...",
            ["AI analysis failed.", "Please try again or consult a real doctor."],
            [str(e)],
        )
