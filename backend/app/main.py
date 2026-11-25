from fastapi import FastAPI
from fastapi.responses import HTMLResponse, FileResponse
from fastapi.staticfiles import StaticFiles
from app import models
from app.db import engine, Base
from app.auth import router as auth_router
from app.scans import router as scans_router
from app.doctor import router as doctor_router
import os

# create tables
Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="Vaidra AI Healthcare API",
    description="Instant skin condition analysis using Google Gemini Multimodal AI",
    version="1.0.5"
)

from fastapi.middleware.cors import CORSMiddleware

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth_router)
app.include_router(scans_router)
app.include_router(doctor_router)

# Mount Flutter Web App if build exists
web_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), "../../vaidra/build/web"))
if os.path.isdir(web_dir):
    app.mount("/app", StaticFiles(directory=web_dir, html=True), name="web_app")

@app.get("/health")
def health():
    return {"status": "ok"}

@app.get("/download-apk")
def download_apk():
    apk_path = os.path.abspath(os.path.join(os.path.dirname(__file__), "../../vaidra/build/app/outputs/flutter-apk/app-release.apk"))
    if os.path.exists(apk_path):
        return FileResponse(
            apk_path,
            media_type="application/vnd.android.package-archive",
            filename="Vaidra-Release.apk"
        )
    return {"error": "APK not found. Please build the APK first."}

@app.get("/", response_class=HTMLResponse)
def root():
    return """<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Vaidra - AI Healthcare Platform</title>
    <style>
        * { box-sizing: border-box; margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; }
        body { background: #0f172a; color: #f8fafc; display: flex; align-items: center; justify-content: center; min-height: 100vh; padding: 20px; }
        .card { background: #1e293b; border: 1px solid #334155; border-radius: 24px; max-width: 620px; width: 100%; padding: 40px; box-shadow: 0 25px 50px -12px rgba(0,0,0,0.6); text-align: center; }
        .badge { display: inline-flex; align-items: center; gap: 8px; background: rgba(34, 197, 94, 0.15); color: #4ade80; border: 1px solid rgba(34, 197, 94, 0.3); padding: 6px 16px; border-radius: 999px; font-size: 14px; font-weight: 600; margin-bottom: 24px; }
        .badge-dot { width: 8px; height: 8px; background: #22c55e; border-radius: 50%; box-shadow: 0 0 10px #22c55e; }
        h1 { font-size: 34px; font-weight: 800; margin-bottom: 12px; background: linear-gradient(135deg, #38bdf8, #818cf8); -webkit-background-clip: text; -webkit-text-fill-color: transparent; }
        p { color: #94a3b8; font-size: 16px; line-height: 1.6; margin-bottom: 28px; }
        .actions { display: flex; flex-direction: column; gap: 14px; margin-bottom: 28px; }
        .btn-launch { display: block; width: 100%; padding: 18px 24px; border-radius: 16px; font-size: 17px; font-weight: 700; text-decoration: none; background: linear-gradient(135deg, #0ea5e9, #3b82f6); color: white; box-shadow: 0 12px 24px rgba(14,165,233,0.35); transition: all 0.2s; }
        .btn-launch:hover { transform: translateY(-2px); box-shadow: 0 16px 30px rgba(14,165,233,0.45); }
        .btn-apk { display: block; width: 100%; padding: 16px 24px; border-radius: 16px; font-size: 16px; font-weight: 700; text-decoration: none; background: #10b981; color: white; box-shadow: 0 10px 20px rgba(16,185,129,0.3); transition: all 0.2s; }
        .btn-apk:hover { transform: translateY(-2px); background: #059669; }
        .btn-row { display: flex; gap: 12px; justify-content: center; }
        .btn-secondary { flex: 1; display: inline-flex; align-items: center; justify-content: center; padding: 12px 20px; border-radius: 12px; font-size: 14px; font-weight: 600; text-decoration: none; background: #334155; color: #f8fafc; border: 1px solid #475569; transition: all 0.2s; }
        .btn-secondary:hover { background: #475569; }
        .instructions { background: rgba(15, 23, 42, 0.6); border: 1px solid #334155; border-radius: 16px; padding: 20px; text-align: left; margin-top: 10px; }
        .instructions h3 { font-size: 15px; color: #38bdf8; margin-bottom: 10px; }
        .instructions ol { padding-left: 20px; font-size: 13px; color: #cbd5e1; line-height: 1.8; }
    </style>
</head>
<body>
    <div class="card">
        <div class="badge">
            <span class="badge-dot"></span>
            Server Live & Reachable
        </div>
        <h1>Vaidra AI Healthcare</h1>
        <p>Instant skin condition diagnosis with Gemini Multimodal AI. Works on any phone or browser.</p>
        
        <div class="actions">
            <a href="/app/" class="btn-launch">🌐 1. Open App in Phone Browser (Instant, No Install)</a>
            <a href="/download-apk" class="btn-apk">📥 2. Download Android APK (Native App)</a>
        </div>
        
        <div class="btn-row">
            <a href="/docs" class="btn-secondary">📖 API Swagger Docs</a>
            <a href="/health" class="btn-secondary">🔍 Health Check</a>
        </div>

        <div class="instructions">
            <h3>📲 Test on Another Mobile Phone:</h3>
            <ol>
                <li><strong>Browser Method (Easiest)</strong>: Tap <em>"Open App in Phone Browser"</em> to use the full camera & AI analysis in Safari or Chrome.</li>
                <li><strong>Native Android APK</strong>: Tap <em>"Download Android APK"</em> to download and install the app directly on an Android device.</li>
                <li><strong>Login</strong>: Use <code>test@test.com</code> / <code>password123</code> (or click Register).</li>
            </ol>
        </div>
    </div>
</body>
</html>
"""
