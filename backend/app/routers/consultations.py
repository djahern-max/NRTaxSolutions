from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List

from app.db.session import get_db
from app.core.auth import get_current_active_user
from app.crud import crud
from app.schemas import schemas
from app.models.models import User

router = APIRouter()

@router.post("/consultations/", response_model=schemas.Consultation)
def create_consultation(
    consultation: schemas.ConsultationCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    return crud.create_consultation(db=db, consultation=consultation, user_id=current_user.id)

@router.get("/consultations/", response_model=List[schemas.Consultation])
def read_user_consultations(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    return crud.get_user_consultations(db, user_id=current_user.id)
