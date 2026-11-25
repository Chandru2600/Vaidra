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


# ---------------------------------------------------------------------------
# Emergency features (checklist §3/§4/§6/§7) — added 2026-11-25
# ---------------------------------------------------------------------------
import io
from PIL import Image


def _register_user():
    """Register + log in a fresh user; returns (email, token)."""
    import uuid
    email = f"emerg_{uuid.uuid4().hex[:8]}@example.com"
    reg = client.post("/auth/register", json={
        "email": email, "password": "password123", "name": "Emergency Tester"
    })
    assert reg.status_code == 201
    login = client.post("/auth/login", data={"username": email, "password": "password123"})
    assert login.status_code == 200
    return email, login.json()["access_token"]


def _auth(token):
    return {"Authorization": f"Bearer {token}"}


# --- First-aid knowledge base ----------------------------------------------
def test_first_aid_guides_list():
    res = client.get("/first-aid/guides")
    assert res.status_code == 200
    guides = res.json()
    # Brief named 13 guides (said 12) — all must be present.
    assert len(guides) == 13
    ids = {g["id"] for g in guides}
    for expected in ("severe-bleeding", "burns", "choking-adult", "choking-child-infant",
                     "cpr-basics", "fracture", "sprain", "snake-bite", "fainting",
                     "heatstroke", "allergic-reaction", "nosebleed", "seizure"):
        assert expected in ids
    for g in guides:
        assert g["title"] and g["steps"] and g["danger_signs"]
        assert g["what_not_to_do"] and g["call_112_when"]
        assert "not medical advice" in g["disclaimer"]
        # No medication names or dosages anywhere in the KB.
        blob = " ".join(g["steps"] + g["what_not_to_do"]).lower()
        for banned in ("paracetamol", "ibuprofen", "aspirin", "antibiotic",
                       "epinephrine", "adrenaline", " mg", "tablet", "dose"):
            assert banned not in blob


def test_first_aid_guide_detail_and_404():
    res = client.get("/first-aid/guides/cpr-basics")
    assert res.status_code == 200
    assert res.json()["id"] == "cpr-basics"
    assert any("112" in s for s in res.json()["steps"])
    missing = client.get("/first-aid/guides/no-such-guide")
    assert missing.status_code == 404


# --- Danger-sign triage ------------------------------------------------------
def test_triage_danger_escalates_to_112():
    res = client.post("/emergency/triage", json={
        "description": "My father has chest pain and difficulty breathing",
        "symptoms": ["sweating", "pain in left arm"],
    })
    assert res.status_code == 200
    data = res.json()
    assert data["escalation"] == "CALL_112_NOW"
    assert data["call_112"] is True
    assert "112" in data["message"]


def test_triage_unconscious_escalates():
    res = client.post("/emergency/triage", json={
        "description": "He collapsed and is unresponsive",
        "symptoms": [],
    })
    assert res.json()["escalation"] == "CALL_112_NOW"


def test_triage_urgent_care():
    res = client.post("/emergency/triage", json={
        "description": "High fever and vomiting since morning",
        "symptoms": ["fever"],
    })
    assert res.json()["escalation"] == "URGENT_SEEK_CARE"


def test_triage_self_care_with_guide():
    res = client.post("/emergency/triage", json={
        "description": "Small nosebleed after blowing my nose",
        "symptoms": [],
    })
    data = res.json()
    assert data["escalation"] == "SELF_CARE_GUIDANCE"
    assert data["guide_id"] == "nosebleed"
    assert "If unsure, call 112 immediately." in data["advice"]


def test_triage_never_delays_escalation():
    # Even a vague description with a danger keyword must escalate at once.
    res = client.post("/emergency/triage", json={
        "description": "not sure, maybe chest pain?",
        "symptoms": [],
    })
    assert res.json()["escalation"] == "CALL_112_NOW"


# --- Emergency contacts CRUD -------------------------------------------------
def test_emergency_contacts_crud():
    _, token = _register_user()
    headers = _auth(token)

    # Unauthenticated -> 401
    assert client.get("/emergency-contacts").status_code == 401

    # Create two contacts, one primary
    c1 = client.post("/emergency-contacts", json={
        "name": "Mother", "relationship": "Mother",
        "phone": "+919999999999", "is_primary": True,
    }, headers=headers)
    assert c1.status_code == 201
    c1_id = c1.json()["id"]
    assert c1.json()["is_primary"] is True

    c2 = client.post("/emergency-contacts", json={
        "name": "Brother", "relationship": "Brother",
        "phone": "+918888888888", "is_primary": True,
    }, headers=headers)
    assert c2.status_code == 201
    # Only one primary: creating a second primary demotes the first.
    listed = client.get("/emergency-contacts", headers=headers).json()
    primaries = [c for c in listed if c["is_primary"]]
    assert len(primaries) == 1 and primaries[0]["id"] == c2.json()["id"]

    # Update
    upd = client.put(f"/emergency-contacts/{c1_id}", json={"phone": "+917777777777"}, headers=headers)
    assert upd.status_code == 200
    assert upd.json()["phone"] == "+917777777777"

    # Delete
    assert client.delete(f"/emergency-contacts/{c1_id}", headers=headers).status_code == 204
    remaining = client.get("/emergency-contacts", headers=headers).json()
    assert all(c["id"] != c1_id for c in remaining)


def test_emergency_contacts_owner_only():
    _, token_a = _register_user()
    _, token_b = _register_user()
    c = client.post("/emergency-contacts", json={
        "name": "Mother", "phone": "+919999999999",
    }, headers=_auth(token_a))
    cid = c.json()["id"]
    # User B cannot see / change / delete user A's contact.
    assert client.put(f"/emergency-contacts/{cid}", json={"phone": "+910000000000"},
                      headers=_auth(token_b)).status_code == 404
    assert client.delete(f"/emergency-contacts/{cid}", headers=_auth(token_b)).status_code == 404
    assert client.get("/emergency-contacts", headers=_auth(token_b)).json() == []


# --- LifeCard ------------------------------------------------------------------
def test_lifecard_get_put_public_and_regenerate():
    _, token = _register_user()
    headers = _auth(token)

    # No card yet -> 404
    assert client.get("/lifecard", headers=headers).status_code == 404

    put = client.put("/lifecard", json={
        "blood_group": "O+",
        "allergies": "Peanuts",
        "conditions": "Asthma",
        "medications": "SecretMed 10mg",  # must NEVER leak publicly
        "insurance": "POLICY-123",        # must NEVER leak publicly
        "notes": "Private note",
        "share_with_contacts": True,
    }, headers=headers)
    assert put.status_code == 200
    card = put.json()
    assert card["blood_group"] == "O+"
    token_value = card["share_token"]
    assert token_value

    # Add a contact so the public view has one to show.
    client.post("/emergency-contacts", json={
        "name": "Mother", "relationship": "Mother", "phone": "+919999999999",
    }, headers=headers)

    pub = client.get(f"/lifecard/public/{token_value}")
    assert pub.status_code == 200
    pub_data = pub.json()
    assert pub_data["blood_group"] == "O+"
    assert pub_data["allergies"] == "Peanuts"
    assert pub_data["conditions"] == "Asthma"
    assert pub_data["emergency_contacts"][0]["phone"] == "+919999999999"
    # Sensitive fields must NOT appear in the public response at all.
    assert "medications" not in pub_data
    assert "insurance" not in pub_data
    assert "notes" not in pub_data
    assert "SecretMed" not in str(pub_data) and "POLICY-123" not in str(pub_data)

    # Regenerate token: old URL stops working, new one works.
    regen = client.post("/lifecard/regenerate-token", headers=headers)
    assert regen.status_code == 200
    new_token = regen.json()["share_token"]
    assert new_token != token_value
    assert client.get(f"/lifecard/public/{token_value}").status_code == 404
    assert client.get(f"/lifecard/public/{new_token}").status_code == 200


# --- Discovery (mocked Overpass) ----------------------------------------------
class _FakeOverpassResponse:
    status_code = 200

    def json(self):
        return {"elements": [
            {"type": "node", "id": 1, "lat": 12.9716, "lon": 77.5946,
             "tags": {"amenity": "hospital", "name": "Test General Hospital",
                      "addr:full": "MG Road, Bengaluru"}},
            {"type": "node", "id": 2, "lat": 12.9720, "lon": 77.5950,
             "tags": {"amenity": "hospital"}},
        ]}


def test_discover_hospitals_mocked(monkeypatch):
    monkeypatch.setattr("app.discover.requests.post",
                        lambda *a, **k: _FakeOverpassResponse())
    res = client.get("/discover/hospitals", params={"lat": 12.9716, "lng": 77.5946, "radius_m": 5000})
    assert res.status_code == 200
    data = res.json()
    assert data["amenity"] == "hospital"
    assert data["count"] == 2
    first = data["results"][0]
    assert first["name"] == "Test General Hospital"
    assert first["address"] == "MG Road, Bengaluru"
    assert first["distance_m"] == 0.0
    assert first["verification_status"] == "unverified_osm"
    assert "never invents them" in first["note"]
    # No invented hours/beds/availability anywhere in the payload:
    # results carry ONLY the whitelisted fields.
    for r in data["results"]:
        assert set(r.keys()) == {"name", "lat", "lng", "distance_m", "address",
                                 "verification_status", "note"}
    second = data["results"][1]
    assert second["name"] == "Unnamed hospital"


def test_discover_pharmacies_mocked(monkeypatch):
    monkeypatch.setattr("app.discover.requests.post",
                        lambda *a, **k: _FakeOverpassResponse())
    res = client.get("/discover/pharmacies", params={"lat": 12.9716, "lng": 77.5946})
    assert res.status_code == 200
    assert res.json()["amenity"] == "pharmacy"


def test_discover_overpass_down_returns_503(monkeypatch):
    import requests as _rq

    def _boom(*a, **k):
        raise _rq.exceptions.ConnectionError("down")

    monkeypatch.setattr("app.discover.requests.post", _boom)
    res = client.get("/discover/hospitals", params={"lat": 12.9716, "lng": 77.5946})
    assert res.status_code == 503
    assert "unavailable" in res.json()["detail"].lower()


def test_discover_bad_coords():
    res = client.get("/discover/hospitals", params={"lat": 200, "lng": 77.0})
    assert res.status_code == 400


# --- Scan analysis safety fields (mocked Gemini) --------------------------------
def test_scan_analysis_returns_disclaimer_and_uncertainty(monkeypatch):
    def _fake_analyze(path):
        return {
            "condition": "Red irritated patch (preliminary guidance only, not a diagnosis)",
            "confidence": 70.0,
            "severity": "MINOR",
            "steps": ["Keep the area clean and dry."],
            "warnings": ["See a doctor if it spreads."],
            "disclaimer": "Preliminary visual guidance only — not a diagnosis. AI can be wrong. See a qualified doctor for a real diagnosis.",
            "uncertainty": "medium",
        }

    monkeypatch.setattr("app.scans.analyze_image", _fake_analyze)
    buf = io.BytesIO()
    Image.new("RGB", (10, 10), color="red").save(buf, format="PNG")
    buf.seek(0)
    res = client.post("/scans/analyze",
                      files={"scan_image": ("skin.png", buf, "image/png")})
    assert res.status_code == 200
    result = res.json()["result"]
    assert result["condition"].startswith("Red irritated patch")
    assert "not a diagnosis" in result["disclaimer"]
    assert result["uncertainty"] == "medium"


# ---------------------------------------------------------------------------
# Round 2 — roles, partners, enquiries, discovery, Family Relay, voice,
# subscriptions, single-scan endpoint (checklist §7/§8/§9/§14)
# ---------------------------------------------------------------------------

def _register_admin(monkeypatch):
    """Register a user whose email matches VAIDRA_ADMIN_EMAIL -> ADMIN."""
    import uuid
    email = f"admin_{uuid.uuid4().hex[:8]}@example.com"
    monkeypatch.setenv("VAIDRA_ADMIN_EMAIL", email)
    reg = client.post("/auth/register", json={
        "email": email, "password": "password123", "name": "Admin User"
    })
    assert reg.status_code == 201
    login = client.post("/auth/login", data={"username": email, "password": "password123"})
    assert login.status_code == 200
    return email, login.json()["access_token"]


def _register_partner(org_type="hospital", name="City General Hospital"):
    """Register a user + partner account; returns (token, partner_id)."""
    _, token = _register_user()
    res = client.post("/partners/register", json={
        "org_type": org_type, "org_name": name,
        "address": "MG Road, Bengaluru", "phone": "+919999999999",
        "specialities": "Emergency, Cardiology",
    }, headers=_auth(token))
    assert res.status_code == 201
    data = res.json()
    assert data["verification_status"] == "pending"
    assert data["org_type"] == org_type
    return token, data["id"]


# --- Roles + partners ---------------------------------------------------------
def test_partner_register_verify_and_public_listing(monkeypatch):
    admin_email, admin_token = _register_admin(monkeypatch)
    partner_token, partner_id = _register_partner()

    # Pending partner is invisible publicly (filter by this test's partner:
    # the shared test DB may hold verified partners from earlier runs).
    public = client.get("/partners/hospitals").json()
    assert all(p["id"] != partner_id for p in public)

    # Non-admin cannot use admin endpoints.
    assert client.get("/admin/partners", headers=_auth(partner_token)).status_code == 403

    # Admin lists all (including pending) and verifies.
    listed = client.get("/admin/partners", headers=_auth(admin_token))
    assert listed.status_code == 200
    assert any(p["id"] == partner_id for p in listed.json())
    verify = client.post(f"/admin/partners/{partner_id}/verify", headers=_auth(admin_token))
    assert verify.status_code == 200
    assert verify.json()["verification_status"] == "verified"

    # Now public: shows with availability fields absent (never reported).
    public = client.get("/partners/hospitals").json()
    mine = [p for p in public if p["id"] == partner_id]
    assert len(mine) == 1
    assert mine[0]["org_name"] == "City General Hospital"
    assert mine[0]["icu_beds_available"] is None
    assert mine[0]["verification_status"] == "verified"

    # Partner reports availability -> public listing reflects exactly that.
    avail = client.put("/partners/me/availability", json={
        "er_status": "open", "icu_beds_available": 3, "general_beds_available": 12,
    }, headers=_auth(partner_token))
    assert avail.status_code == 200
    public = client.get("/partners/hospitals").json()
    mine = [p for p in public if p["id"] == partner_id]
    assert mine[0]["er_status"] == "open"
    assert mine[0]["icu_beds_available"] == 3
    assert mine[0]["general_beds_available"] == 12

    # Profile update works.
    upd = client.put("/partners/me", json={"phone": "+917777777777"}, headers=_auth(partner_token))
    assert upd.status_code == 200
    assert upd.json()["phone"] == "+917777777777"

    # Bad org_type and duplicate registration rejected.
    _, token2 = _register_user()
    assert client.post("/partners/register", json={
        "org_type": "clinic", "org_name": "X",
    }, headers=_auth(token2)).status_code == 400
    assert client.post("/partners/register", json={
        "org_type": "pharmacy", "org_name": "Second Org",
    }, headers=_auth(partner_token)).status_code == 400


def test_partner_reject_stays_invisible(monkeypatch):
    _, admin_token = _register_admin(monkeypatch)
    _, partner_id = _register_partner(org_type="pharmacy", name="MedPlus Store")
    rej = client.post(f"/admin/partners/{partner_id}/reject", headers=_auth(admin_token))
    assert rej.status_code == 200
    assert rej.json()["verification_status"] == "rejected"
    public = client.get("/partners/pharmacies").json()
    assert all(p["id"] != partner_id for p in public)
    # Verify of a missing partner -> 404.
    assert client.post("/admin/partners/999999/verify", headers=_auth(admin_token)).status_code == 404


# --- Enquiries ------------------------------------------------------------------
def test_enquiries_verified_only_and_request_only(monkeypatch):
    _, admin_token = _register_admin(monkeypatch)
    partner_token, partner_id = _register_partner()
    _, user_token = _register_user()

    # Unverified partner: enquiry refused.
    assert client.post("/enquiries", json={
        "partner_id": partner_id, "kind": "general", "message": "Hello",
    }, headers=_auth(user_token)).status_code == 400

    client.post(f"/admin/partners/{partner_id}/verify", headers=_auth(admin_token))

    # Appointment request -> stored, but clearly request-only.
    res = client.post("/enquiries", json={
        "partner_id": partner_id, "kind": "appointment_request",
        "message": "Need a cardiology appointment tomorrow",
    }, headers=_auth(user_token))
    assert res.status_code == 201
    assert "not a confirmed booking" in res.json()["note"]
    assert res.json()["status"] == "open"

    # General enquiry has no appointment note.
    res2 = client.post("/enquiries", json={
        "partner_id": partner_id, "kind": "general", "message": "What are your hours?",
    }, headers=_auth(user_token))
    assert res2.status_code == 201
    assert res2.json()["note"] is None

    # Bad kind rejected; enquiry to missing partner -> 404.
    assert client.post("/enquiries", json={
        "partner_id": partner_id, "kind": "booking", "message": "x",
    }, headers=_auth(user_token)).status_code == 400
    assert client.post("/enquiries", json={
        "partner_id": 999999, "kind": "general", "message": "x",
    }, headers=_auth(user_token)).status_code == 404

    # Mine lists both; partner sees both; a non-partner user gets 404.
    mine = client.get("/enquiries/mine", headers=_auth(user_token)).json()
    assert len(mine) == 2
    seen = client.get("/partners/enquiries", headers=_auth(partner_token)).json()
    assert len(seen) == 2
    assert client.get("/partners/enquiries", headers=_auth(user_token)).status_code == 404


# --- Discovery: ambulances / blood banks / diagnostics (mocked) ----------------
def test_discover_new_endpoints_mocked(monkeypatch):
    monkeypatch.setattr("app.discover.requests.post",
                        lambda *a, **k: _FakeOverpassResponse())
    for path, amenity in (("/discover/ambulances", "ambulances"),
                          ("/discover/blood-banks", "blood-banks"),
                          ("/discover/diagnostics", "diagnostics")):
        res = client.get(path, params={"lat": 12.9716, "lng": 77.5946})
        assert res.status_code == 200, path
        data = res.json()
        assert data["amenity"] == amenity
        assert data["count"] == 2
        assert data["results"][0]["verification_status"] == "unverified_osm"
        assert "never invents them" in data["results"][0]["note"]
        for r in data["results"]:
            assert set(r.keys()) == {"name", "lat", "lng", "distance_m", "address",
                                     "verification_status", "note"}


def test_discover_new_endpoints_down_returns_503(monkeypatch):
    import requests as _rq

    def _boom(*a, **k):
        raise _rq.exceptions.ConnectionError("down")

    monkeypatch.setattr("app.discover.requests.post", _boom)
    res = client.get("/discover/blood-banks", params={"lat": 12.9716, "lng": 77.5946})
    assert res.status_code == 503


# --- Family Relay ---------------------------------------------------------------
def test_family_group_join_incident_flow():
    _, token_a = _register_user()  # owner
    _, token_b = _register_user()  # member
    _, token_c = _register_user()  # outsider

    # Create group: owner auto-member, invite code issued.
    g = client.post("/family/groups", json={"name": "Loni Family"}, headers=_auth(token_a))
    assert g.status_code == 201
    group = g.json()
    assert group["invite_code"]
    assert len(group["members"]) == 1
    gid = group["id"]

    # Bad invite code -> 404; join works; joining twice -> 400.
    assert client.post("/family/groups/join", json={"invite_code": "NOPE1234"},
                       headers=_auth(token_b)).status_code == 404
    joined = client.post("/family/groups/join", json={"invite_code": group["invite_code"]},
                         headers=_auth(token_b))
    assert joined.status_code == 200
    assert len(joined.json()["members"]) == 2
    assert client.post("/family/groups/join", json={"invite_code": group["invite_code"]},
                       headers=_auth(token_b)).status_code == 400

    # Outsider cannot see incidents or post updates.
    assert client.get(f"/family/groups/{gid}/incidents", headers=_auth(token_c)).status_code == 403

    # Member reports an incident.
    inc = client.post(f"/family/groups/{gid}/incidents", json={
        "title": "Father fell at home", "description": "Conscious, leg pain",
        "hospital_destination": "City General Hospital",
    }, headers=_auth(token_b))
    assert inc.status_code == 201
    incident = inc.json()
    assert incident["status"] == "active"
    assert incident["hospital_destination"] == "City General Hospital"
    iid = incident["id"]

    # Outsider update -> 403; member update -> 200 with timeline entry.
    assert client.post(f"/family/incidents/{iid}/updates", json={"message": "Ambulance called"},
                       headers=_auth(token_c)).status_code == 403
    upd = client.post(f"/family/incidents/{iid}/updates", json={"message": "Reached hospital"},
                      headers=_auth(token_b))
    assert upd.status_code == 200
    assert len(upd.json()["updates"]) == 1
    assert upd.json()["updates"][0]["message"] == "Reached hospital"

    # Outsider cannot resolve; reporter can.
    assert client.post(f"/family/incidents/{iid}/resolve", headers=_auth(token_c)).status_code == 403
    res = client.post(f"/family/incidents/{iid}/resolve", headers=_auth(token_b))
    assert res.status_code == 200
    assert res.json()["status"] == "resolved"

    # Location-sharing consent flag: each member sets only their own.
    ls = client.put(f"/family/groups/{gid}/location-sharing",
                    json={"can_share_location": True}, headers=_auth(token_b))
    assert ls.status_code == 200
    assert ls.json()["can_share_location"] is True
    # Owner's flag is still False — setting yours never changes another's.
    groups_a = client.get("/family/groups", headers=_auth(token_a)).json()
    members = {m["user_id"]: m for m in groups_a[0]["members"]}
    assert members[groups_a[0]["owner_id"]]["can_share_location"] is False

    # Owner cannot leave; member can, then loses access.
    assert client.post(f"/family/groups/{gid}/leave", headers=_auth(token_a)).status_code == 400
    assert client.post(f"/family/groups/{gid}/leave", headers=_auth(token_b)).status_code == 204
    assert client.get(f"/family/groups/{gid}/incidents", headers=_auth(token_b)).status_code == 403
    assert client.get("/family/groups", headers=_auth(token_b)).json() == []


# --- Voice assist -----------------------------------------------------------------
def test_voice_assist_escalation_and_guide():
    danger = client.post("/voice/assist", json={"text": "chest pain, can't breathe"})
    assert danger.status_code == 200
    d = danger.json()
    assert d["escalation"] == "CALL_112_NOW"
    assert d["call_112"] is True
    assert d["guide"] is None

    mild = client.post("/voice/assist", json={"text": "small nosebleed after blowing my nose"})
    assert mild.status_code == 200
    m = mild.json()
    assert m["escalation"] == "SELF_CARE_GUIDANCE"
    assert m["guide_id"] == "nosebleed"
    assert m["guide"] is not None
    assert m["guide"]["title"] == "Nosebleed"
    assert m["guide"]["steps"]


# --- Subscriptions ------------------------------------------------------------------
def test_subscriptions_plans_subscribe_cancel():
    _, token = _register_user()
    headers = _auth(token)

    plans = client.get("/subscriptions/plans").json()
    assert len(plans) == 3
    by_plan = {p["plan"]: p for p in plans}
    assert "no payment charged" in by_plan["PERSONAL_PREMIUM"]["price_text"]
    assert "Hypothesis" in by_plan["FAMILY_PREMIUM"]["price_text"]
    assert "never paywalled" in by_plan["PERSONAL_BASIC"]["description"]

    # No subscription yet -> 404; cancel with none -> 404.
    assert client.get("/subscriptions/me", headers=headers).status_code == 404
    assert client.post("/subscriptions/cancel", headers=headers).status_code == 404

    # Paid plan: pending_payment, valid 30 days out, never active.
    sub = client.post("/subscriptions/subscribe", json={"plan": "PERSONAL_PREMIUM"}, headers=headers)
    assert sub.status_code == 200
    assert sub.json()["status"] == "pending_payment"
    assert sub.json()["valid_until"] is not None

    # Free plan: active at once, no expiry.
    basic = client.post("/subscriptions/subscribe", json={"plan": "PERSONAL_BASIC"}, headers=headers)
    assert basic.status_code == 200
    assert basic.json()["status"] == "active"
    assert basic.json()["valid_until"] is None

    # Invalid plan rejected.
    assert client.post("/subscriptions/subscribe", json={"plan": "GOLD"}, headers=headers).status_code == 400

    # Cancel.
    cancelled = client.post("/subscriptions/cancel", headers=headers)
    assert cancelled.status_code == 200
    assert cancelled.json()["status"] == "cancelled"


# --- Single-scan endpoint -------------------------------------------------------------
def test_get_scan_by_id_owner_isolation(monkeypatch):
    def _fake_analyze(path):
        return {
            "condition": "Red irritated patch (preliminary guidance only, not a diagnosis)",
            "confidence": 70.0,
            "severity": "MINOR",
            "steps": ["Keep the area clean and dry."],
            "warnings": ["See a doctor if it spreads."],
            "disclaimer": "Preliminary visual guidance only — not a diagnosis.",
            "uncertainty": "medium",
        }

    monkeypatch.setattr("app.scans.analyze_image", _fake_analyze)
    _, token_a = _register_user()
    _, token_b = _register_user()

    buf = io.BytesIO()
    Image.new("RGB", (10, 10), color="red").save(buf, format="PNG")
    buf.seek(0)
    created = client.post("/scans/analyze",
                          files={"scan_image": ("skin.png", buf, "image/png")},
                          headers=_auth(token_a))
    assert created.status_code == 200
    scan_id = created.json()["id"]

    # Owner can read it; another user gets 404; no token gets 401.
    got = client.get(f"/scans/{scan_id}", headers=_auth(token_a))
    assert got.status_code == 200
    assert got.json()["id"] == scan_id
    assert got.json()["result"]["condition"].startswith("Red irritated patch")
    assert client.get(f"/scans/{scan_id}", headers=_auth(token_b)).status_code == 404
    assert client.get(f"/scans/{scan_id}").status_code == 401
    assert client.get("/scans/999999", headers=_auth(token_a)).status_code == 404


