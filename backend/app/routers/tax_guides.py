from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List

from app.db.session import get_db
from app.core.auth import get_current_active_user, get_premium_user
from app.crud import crud
from app.schemas import schemas
from app.models.models import User

router = APIRouter()

@router.get("/tax-guides/", response_model=List[schemas.TaxGuide])
def read_tax_guides(skip: int = 0, limit: int = 100, db: Session = Depends(get_db), current_user: User = None):
    premium_only = False
    if current_user and current_user.is_premium:
        premium_only = True
    return crud.get_tax_guides(db, skip=skip, limit=limit, premium_only=premium_only)

@router.get("/tax-guides/{guide_id}", response_model=schemas.TaxGuide)
def read_tax_guide(guide_id: int, db: Session = Depends(get_db), current_user: User = None):
    db_guide = crud.get_tax_guide(db, guide_id=guide_id)
    if db_guide is None:
        raise HTTPException(status_code=404, detail="Tax guide not found")
    if db_guide.is_premium and (not current_user or not current_user.is_premium):
        raise HTTPException(status_code=403, detail="Premium content requires subscription")
    return db_guide

@router.post("/tax-guides/", response_model=schemas.TaxGuide)
def create_tax_guide(guide: schemas.TaxGuideCreate, db: Session = Depends(get_db)):
    # In a real app, this would be admin-only
    return crud.create_tax_guide(db=db, guide=guide)
