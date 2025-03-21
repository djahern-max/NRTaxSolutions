from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List

from app.db.session import get_db
from app.core.auth import get_current_active_user, get_premium_user
from app.crud import crud
from app.schemas import schemas
from app.models.models import User

router = APIRouter()

@router.get("/faqs/", response_model=List[schemas.FAQ])
def read_faqs(skip: int = 0, limit: int = 100, db: Session = Depends(get_db), current_user: User = None):
    premium_only = False
    if current_user and current_user.is_premium:
        premium_only = True
    return crud.get_faqs(db, skip=skip, limit=limit, premium_only=premium_only)

@router.get("/faqs/category/{category}", response_model=List[schemas.FAQ])
def read_faq_by_category(category: str, db: Session = Depends(get_db)):
    return crud.get_faq_by_category(db, category=category)

@router.post("/faqs/", response_model=schemas.FAQ)
def create_faq(faq: schemas.FAQCreate, db: Session = Depends(get_db)):
    # In a real app, this would be admin-only
    return crud.create_faq(db=db, faq=faq)
