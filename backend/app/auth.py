from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.db import get_db
from app import models, schemas, utils
from fastapi.security import OAuth2PasswordRequestForm
from fastapi import Body

router = APIRouter(prefix="/auth", tags=["auth"])

@router.post("/register", status_code=201)
def register(user: schemas.UserCreate, db: Session = Depends(get_db)):
    existing = db.query(models.User).filter(models.User.email == user.email).first()
    if existing:
        raise HTTPException(status_code=400, detail="Email already registered")
    hashed = utils.get_password_hash(user.password)
    u = models.User(
        email=user.email, 
        hashed_password=hashed, 
        name=user.name,
        age=user.age,
        gender=user.gender,
        conditions=user.conditions,
        allergies=user.allergies,
        address=user.address
    )
    db.add(u)
    db.commit()
    db.refresh(u)
    return {"id": u.id, "email": u.email, "name": u.name}

@router.post("/login", response_model=schemas.Token)
def login(form_data: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(get_db)):
    user = db.query(models.User).filter(models.User.email == form_data.username).first()
    if not user or not utils.verify_password(form_data.password, user.hashed_password):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid credentials")
    token = utils.create_access_token(user.id)
    return {"access_token": token, "token_type": "bearer"}

@router.get("/profile")
def get_profile(
    db: Session = Depends(get_db),
    current_user_id: int = Depends(utils.get_current_user_id)
):
    user = db.query(models.User).filter(models.User.id == current_user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    return {
        "id": user.id,
        "email": user.email,
        "name": user.name,
        "age": user.age,
        "gender": user.gender,
        "conditions": user.conditions,
        "allergies": user.allergies,
        "address": user.address,
        "location_lat": user.location_lat,
        "location_lng": user.location_lng
    }

@router.put("/profile")
def update_profile(
    user_update: schemas.UserUpdate, 
    db: Session = Depends(get_db),
    current_user_id: int = Depends(utils.get_current_user_id) # Assuming utils has this
):
    user = db.query(models.User).filter(models.User.id == current_user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    if user_update.name is not None: user.name = user_update.name
    if user_update.age is not None: user.age = user_update.age
    if user_update.gender is not None: user.gender = user_update.gender
    if user_update.conditions is not None: user.conditions = user_update.conditions
    if user_update.allergies is not None: user.allergies = user_update.allergies
    if user_update.address is not None: user.address = user_update.address
    if user_update.location_lat is not None: user.location_lat = user_update.location_lat
    if user_update.location_lng is not None: user.location_lng = user_update.location_lng

    db.commit()
    return {"status": "updated"}
