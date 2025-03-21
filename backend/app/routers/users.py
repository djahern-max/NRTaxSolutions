from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List

from app.db.session import get_db
from app.core.auth import get_current_active_user, get_premium_user
from app.crud import crud
from app.schemas import schemas

router = APIRouter()

@router.post("/users/", response_model=schemas.User)
def create_user(user: schemas.UserCreate, db: Session = Depends(get_db)):
    db_user = crud.get_user_by_email(db, email=user.email)
    if db_user:
        raise HTTPException(status_code=400, detail="Email already registered")
    return crud.create_user(db=db, user=user)

@router.get("/users/me/", response_model=schemas.User)
async def read_users_me(current_user: schemas.User = Depends(get_current_active_user)):
    return current_user

@router.post("/users/me/premium/", response_model=schemas.User)
async def upgrade_to_premium(current_user: schemas.User = Depends(get_current_active_user), db: Session = Depends(get_db)):
    # In a real app, you would process payment here
    return crud.update_user_premium(db, email=current_user.email, is_premium=True)
