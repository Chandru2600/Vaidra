"""Nearby hospital / pharmacy discovery from OpenStreetMap (Overpass API).

REAL data only — Vaidra never invents listings, hours, beds or availability.
Every result is marked verification_status="unverified_osm" with a note
saying so. Hours, beds and availability are NOT shown at all.
"""
import math
import requests
from fastapi import APIRouter, HTTPException, Query
from app import schemas

router = APIRouter(prefix="/discover", tags=["discover"])

OVERPASS_URL = "https://overpass-api.de/api/interpreter"
OVERPASS_TIMEOUT_S = 30
MAX_RESULTS = 20
NOTE = (
    "Details from OpenStreetMap, not verified by Vaidra. "
    "Hours, beds and availability are NOT shown — Vaidra never invents them."
)


def _haversine_m(lat1: float, lng1: float, lat2: float, lng2: float) -> float:
    r = 6371000.0
    p1, p2 = math.radians(lat1), math.radians(lat2)
    dphi = math.radians(lat2 - lat1)
    dlmb = math.radians(lng2 - lng1)
    a = math.sin(dphi / 2) ** 2 + math.cos(p1) * math.cos(p2) * math.sin(dlmb / 2) ** 2
    return 2 * r * math.asin(math.sqrt(a))


def _address_from_tags(tags: dict) -> str | None:
    if tags.get("addr:full"):
        return tags["addr:full"]
    parts = [
        tags.get("addr:housenumber"),
        tags.get("addr:street"),
        tags.get("addr:suburb"),
        tags.get("addr:city"),
        tags.get("addr:postcode"),
    ]
    joined = ", ".join(p for p in parts if p)
    return joined or None


def _query_overpass(lat: float, lng: float, radius_m: int, tag_key: str, tag_value: str, label: str) -> list:
    query = f"""
    [out:json][timeout:25];
    (
      node["{tag_key}"="{tag_value}"](around:{radius_m},{lat},{lng});
      way["{tag_key}"="{tag_value}"](around:{radius_m},{lat},{lng});
    );
    out center {MAX_RESULTS};
    """
    try:
        resp = requests.post(OVERPASS_URL, data={"data": query}, timeout=OVERPASS_TIMEOUT_S)
    except requests.exceptions.RequestException:
        raise HTTPException(
            status_code=503,
            detail="Discovery service unavailable (OpenStreetMap Overpass could not be reached). Please try again later.",
        )
    if resp.status_code != 200:
        raise HTTPException(
            status_code=503,
            detail=f"Discovery service returned an error (HTTP {resp.status_code}). Please try again later.",
        )
    try:
        data = resp.json()
    except ValueError:
        raise HTTPException(
            status_code=503,
            detail="Discovery service returned an unreadable response. Please try again later.",
        )

    results = []
    for el in data.get("elements", []):
        tags = el.get("tags", {}) or {}
        el_lat = el.get("lat") or (el.get("center") or {}).get("lat")
        el_lng = el.get("lon") or (el.get("center") or {}).get("lon")
        if el_lat is None or el_lng is None:
            continue
        name = tags.get("name") or f"Unnamed {label}"
        results.append(schemas.DiscoveryResult(
            name=name,
            lat=float(el_lat),
            lng=float(el_lng),
            distance_m=round(_haversine_m(lat, lng, float(el_lat), float(el_lng)), 1),
            address=_address_from_tags(tags),
            verification_status="unverified_osm",
            note=NOTE,
        ))
    results.sort(key=lambda r: r.distance_m)
    return results[:MAX_RESULTS]


def _validate(lat: float, lng: float, radius_m: int) -> None:
    if not (-90.0 <= lat <= 90.0):
        raise HTTPException(status_code=400, detail="lat must be between -90 and 90")
    if not (-180.0 <= lng <= 180.0):
        raise HTTPException(status_code=400, detail="lng must be between -180 and 180")
    if not (100 <= radius_m <= 50000):
        raise HTTPException(status_code=400, detail="radius_m must be between 100 and 50000")


@router.get("/hospitals", response_model=schemas.DiscoveryResponse)
def discover_hospitals(
    lat: float = Query(...),
    lng: float = Query(...),
    radius_m: int = Query(5000),
):
    """Real hospitals near a point, from OpenStreetMap. No invented data."""
    _validate(lat, lng, radius_m)
    results = _query_overpass(lat, lng, radius_m, "amenity", "hospital", "hospital")
    return schemas.DiscoveryResponse(amenity="hospital", count=len(results), results=results)


@router.get("/pharmacies", response_model=schemas.DiscoveryResponse)
def discover_pharmacies(
    lat: float = Query(...),
    lng: float = Query(...),
    radius_m: int = Query(5000),
):
    """Real pharmacies near a point, from OpenStreetMap. No invented data."""
    _validate(lat, lng, radius_m)
    results = _query_overpass(lat, lng, radius_m, "amenity", "pharmacy", "pharmacy")
    return schemas.DiscoveryResponse(amenity="pharmacy", count=len(results), results=results)


@router.get("/ambulances", response_model=schemas.DiscoveryResponse)
def discover_ambulances(
    lat: float = Query(...),
    lng: float = Query(...),
    radius_m: int = Query(5000),
):
    """Real ambulance stations near a point, from OpenStreetMap.

    Discovery ONLY — no dispatch or booking. For an emergency call 112
    (or 108/102); the app already has those call buttons.
    """
    _validate(lat, lng, radius_m)
    results = _query_overpass(lat, lng, radius_m, "emergency", "ambulance_station", "ambulance station")
    return schemas.DiscoveryResponse(amenity="ambulances", count=len(results), results=results)


@router.get("/blood-banks", response_model=schemas.DiscoveryResponse)
def discover_blood_banks(
    lat: float = Query(...),
    lng: float = Query(...),
    radius_m: int = Query(5000),
):
    """Real blood donation centres near a point, from OpenStreetMap.

    Discovery ONLY — no stock or availability information. Vaidra never
    claims blood is available anywhere.
    """
    _validate(lat, lng, radius_m)
    results = _query_overpass(lat, lng, radius_m, "healthcare", "blood_donation", "blood bank")
    return schemas.DiscoveryResponse(amenity="blood-banks", count=len(results), results=results)


@router.get("/diagnostics", response_model=schemas.DiscoveryResponse)
def discover_diagnostics(
    lat: float = Query(...),
    lng: float = Query(...),
    radius_m: int = Query(5000),
):
    """Real laboratories / diagnostic centres near a point, from
    OpenStreetMap. Discovery ONLY — no tests, prices or availability."""
    _validate(lat, lng, radius_m)
    results = _query_overpass(lat, lng, radius_m, "healthcare", "laboratory", "diagnostic centre")
    return schemas.DiscoveryResponse(amenity="diagnostics", count=len(results), results=results)
