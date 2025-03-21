from sqlalchemy.orm import Session
from app.models.models import User, TaxGuide, Consultation, FAQ
from app.schemas import schemas
from app.core.auth import get_password_hash

# User CRUD operations
def get_user(db: Session, user_id: int):
    return db.query(User).filter(User.id == user_id).first()

def get_user_by_email(db: Session, email: str):
    return db.query(User).filter(User.email == email).first()

def get_users(db: Session, skip: int = 0, limit: int = 100):
    return db.query(User).offset(skip).limit(limit).all()

def create_user(db: Session, user: schemas.UserCreate):
    hashed_password = get_password_hash(user.password)
    db_user = User(email=user.email, hashed_password=hashed_password)
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    return db_user

def update_user_premium(db: Session, email: str, is_premium: bool):
    db_user = get_user_by_email(db, email)
    db_user.is_premium = is_premium
    db.commit()
    db.refresh(db_user)
    return db_user

# TaxGuide CRUD operations
def get_tax_guides(db: Session, skip: int = 0, limit: int = 100, premium_only: bool = False):
    query = db.query(TaxGuide)
    if premium_only:
        query = query.filter(TaxGuide.is_premium == True)
    return query.offset(skip).limit(limit).all()

def get_tax_guide(db: Session, guide_id: int):
    return db.query(TaxGuide).filter(TaxGuide.id == guide_id).first()

def create_tax_guide(db: Session, guide: schemas.TaxGuideCreate):
    db_guide = TaxGuide(**guide.dict())
    db.add(db_guide)
    db.commit()
    db.refresh(db_guide)
    return db_guide

# Consultation CRUD operations
def create_consultation(db: Session, consultation: schemas.ConsultationCreate, user_id: int):
    db_consultation = Consultation(**consultation.dict(), user_id=user_id)
    db.add(db_consultation)
    db.commit()
    db.refresh(db_consultation)
    return db_consultation

def get_user_consultations(db: Session, user_id: int):
    return db.query(Consultation).filter(Consultation.user_id == user_id).all()

# FAQ CRUD operations
def get_faqs(db: Session, skip: int = 0, limit: int = 100, premium_only: bool = False):
    query = db.query(FAQ)
    if premium_only:
        query = query.filter(FAQ.is_premium == True)
    return query.offset(skip).limit(limit).all()

def get_faq_by_category(db: Session, category: str):
    return db.query(FAQ).filter(FAQ.category == category).all()

def create_faq(db: Session, faq: schemas.FAQCreate):
    db_faq = FAQ(**faq.dict())
    db.add(db_faq)
    db.commit()
    db.refresh(db_faq)
    return db_faq
