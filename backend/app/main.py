from fastapi import FastAPI
from app import models
from app.db import engine, Base
from app.auth import router as auth_router
from app.scans import router as scans_router
from app.doctor import router as doctor_router
import os

# create tables
Base.metadata.create_all(bind=engine)

app = FastAPI(title="Vaidra Backend (FastAPI + Postgres + Perplexity)")

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

@app.get("/health")
def health():
    return {"status":"ok"}
