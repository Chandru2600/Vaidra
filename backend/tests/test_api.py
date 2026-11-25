import pytest
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

def test_health_check():
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "ok"}

def test_register_and_login():
    import uuid
    unique_email = f"test_{uuid.uuid4().hex[:8]}@example.com"
    
    # 1. Register with short password should fail
    bad_res = client.post("/auth/register", json={
        "email": unique_email,
        "password": "123"
    })
    assert bad_res.status_code == 400

    # 2. Register valid user
    reg_res = client.post("/auth/register", json={
        "email": unique_email,
        "password": "password123",
        "name": "Test User"
    })
    assert reg_res.status_code == 201
    data = reg_res.json()
    assert data["email"] == unique_email

    # 3. Duplicate email should fail
    dup_res = client.post("/auth/register", json={
        "email": unique_email,
        "password": "password123"
    })
    assert dup_res.status_code == 400

    # 4. Login with valid credentials
    login_res = client.post("/auth/login", data={
        "username": unique_email,
        "password": "password123"
    })
    assert login_res.status_code == 200
    token_data = login_res.json()
    assert "access_token" in token_data
    token = token_data["access_token"]

    # 5. Get profile with token
    profile_res = client.get("/auth/profile", headers={
        "Authorization": f"Bearer {token}"
    })
    assert profile_res.status_code == 200
    assert profile_res.json()["email"] == unique_email

def test_doctor_access_control():
    # Unauthenticated access to /doctor/cases should be rejected (401)
    res = client.get("/doctor/cases")
    assert res.status_code == 401

def test_file_upload_security():
    # Attempting to upload a script (.sh) should be rejected (400)
    files = {"scan_image": ("malicious.sh", b"echo 'hack'", "text/plain")}
    res = client.post("/scans/analyze", files=files)
    assert res.status_code == 400
    assert "Invalid file type" in res.json()["detail"]

def test_scans_recent_privacy():
    # Unauthenticated query should return empty list (no data leak)
    res = client.get("/scans/recent")
    assert res.status_code == 200
    assert res.json() == []

