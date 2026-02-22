import google.generativeai as genai
import PIL.Image
import json
import os
import traceback
from app.config import settings

def analyze_image(file_path: str):
    """
    Send image to Google Gemini for analysis using PIL to load the image.
    Returns structured JSON with keys: condition, confidence, severity, steps, warnings.
    """
    print(f"Analyzing image at: {file_path}")
    
    if not settings.GEMINI_API_KEY:
        print("ERROR: GEMINI_API_KEY is not set.")
        raise ValueError("GEMINI_API_KEY is not set.")

    try:
        genai.configure(api_key=settings.GEMINI_API_KEY)
        
        # Use gemini-1.5-flash which is the standard fast model for vision
        print("Using model: gemini-1.5-flash")
        model = genai.GenerativeModel('gemini-1.5-flash')

        # Load image using PIL (bypasses upload_file issues)
        print("Loading image with PIL...")
        img = PIL.Image.open(file_path)
        
        prompt = """
        You are a dermatologist AI. Analyze the image and provide a JSON response with the following fields:
        - condition: (string) The name of the skin condition (e.g., Eczema, Psoriasis, Acne, Burn).
        - confidence: (number) Confidence score between 0 and 100.
        - severity: (string) One of ["MINOR", "MODERATE", "URGENT"].
        - steps: (list of strings) First aid or care steps.
        - warnings: (list of strings) Warning signs to watch for.
        
        Return ONLY raw JSON, no markdown formatting.
        """

        print("Sending request to Gemini...")
        response = model.generate_content([prompt, img])
        print("Response received from Gemini.")
        
        try:
            content = response.text
        except Exception as e:
            print(f"Gemini response has no text (likely safety filter): {e}")
            return {
                "condition": "Analysis block by AI safety filters",
                "confidence": 0.0,
                "severity": "MINOR",
                "steps": ["Consult a real doctor as AI cannot analyze this image.", "Ensure the image is clear."],
                "warnings": ["AI refused to analyze image."]
            }
            
        # Strip markdown if present
        if content.startswith("```json"):
            content = content.replace("```json", "").replace("```", "")
        elif content.startswith("```"):
            content = content.replace("```", "")
            
        print("Parsing JSON response...")
        return json.loads(content.strip())
        
    except Exception as e:
        print(f"CRITICAL ERROR in analyze_image: {e}")
        traceback.print_exc()
        # Fallback to prevent 500 error
        return {
            "condition": "AI Service Error",
            "confidence": 0.0,
            "severity": "MINOR",
            "steps": ["AI analysis failed.", "Please try again later."],
            "warnings": [str(e)]
        }

