# File Name: setup_backend.sh
# Description: Backend setup script for RyzeNRTax application

#!/bin/bash

# Set text colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Get project name from environment or use default
PROJECT_NAME=${PROJECT_NAME:-"ryze-nrtax"}

# Error handling function
handle_error() {
    echo -e "${RED}Error: $1${NC}"
    exit 1
}

echo -e "${GREEN}========================================================"
echo -e "       Setting up ${PROJECT_NAME} Backend"
echo -e "========================================================${NC}"

# Create project directory structure
echo -e "\n${YELLOW}Creating backend directory structure...${NC}"
mkdir -p backend || handle_error "Failed to create backend directory"
cd backend || handle_error "Failed to change to backend directory"

# Set up Python virtual environment
echo -e "\n${YELLOW}Setting up Python virtual environment...${NC}"
python3 -m venv venv || handle_error "Failed to create virtual environment"
source venv/bin/activate || handle_error "Failed to activate virtual environment"

# Set up backend
echo -e "\n${YELLOW}Installing backend dependencies...${NC}"
pip install fastapi uvicorn sqlalchemy psycopg2-binary pydantic python-jose[cryptography] passlib[bcrypt] python-multipart || handle_error "Failed to install dependencies"
pip freeze > requirements.txt || handle_error "Failed to create requirements.txt"

# Create backend directory structure
echo -e "\n${YELLOW}Creating backend file structure...${NC}"
mkdir -p app/{routers,models,schemas,crud,core,db} || handle_error "Failed to create app directory structure"
touch app/__init__.py app/main.py
touch app/routers/__init__.py app/models/__init__.py app/schemas/__init__.py
touch app/crud/__init__.py app/core/__init__.py app/db/__init__.py

# Create database migration script
echo -e "\n${YELLOW}Creating database initialization script...${NC}"
cat > app/db/init_db.py << 'EOFDB'
from sqlalchemy import create_engine, MetaData, Table, Column, Integer, String, Text, Boolean, DateTime, ForeignKey
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.sql import func

DATABASE_URL = "postgresql://localhost/ryze_nrtax_db"
engine = create_engine(DATABASE_URL)
metadata = MetaData()
Base = declarative_base()

def init_db():
    Base.metadata.create_all(bind=engine)

if __name__ == "__main__":
    init_db()
    print("Database tables created.")
EOFDB

# Generate all backend files
echo -e "\n${YELLOW}Generating backend files...${NC}"

# Generate models.py
cat > app/models/models.py << 'EOFMODELS'
from sqlalchemy import Boolean, Column, ForeignKey, Integer, String, Text, DateTime
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

from app.db.init_db import Base

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    email = Column(String, unique=True, index=True)
    hashed_password = Column(String)
    is_active = Column(Boolean, default=True)
    is_premium = Column(Boolean, default=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    consultations = relationship("Consultation", back_populates="user")

class TaxGuide(Base):
    __tablename__ = "tax_guides"

    id = Column(Integer, primary_key=True, index=True)
    title = Column(String, index=True)
    content = Column(Text)
    is_premium = Column(Boolean, default=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

class Consultation(Base):
    __tablename__ = "consultations"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    subject = Column(String)
    message = Column(Text)
    status = Column(String, default="pending")  # pending, scheduled, completed
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    user = relationship("User", back_populates="consultations")

class FAQ(Base):
    __tablename__ = "faqs"

    id = Column(Integer, primary_key=True, index=True)
    question = Column(String)
    answer = Column(Text)
    category = Column(String)
    is_premium = Column(Boolean, default=False)
EOFMODELS

# Update models/__init__.py
echo "from app.models.models import User, TaxGuide, Consultation, FAQ" > app/models/__init__.py || handle_error "Failed to create models/__init__.py"

# Generate schemas.py
cat > app/schemas/schemas.py << 'EOFSCHEMAS'
from typing import List, Optional
from datetime import datetime
from pydantic import BaseModel, EmailStr

# User schemas
class UserBase(BaseModel):
    email: EmailStr

class UserCreate(UserBase):
    password: str

class User(UserBase):
    id: int
    is_active: bool
    is_premium: bool
    created_at: datetime

    class Config:
        orm_mode = True

# TaxGuide schemas
class TaxGuideBase(BaseModel):
    title: str
    content: str
    is_premium: bool

class TaxGuideCreate(TaxGuideBase):
    pass

class TaxGuide(TaxGuideBase):
    id: int
    created_at: datetime
    updated_at: Optional[datetime]

    class Config:
        orm_mode = True

# Consultation schemas
class ConsultationBase(BaseModel):
    subject: str
    message: str

class ConsultationCreate(ConsultationBase):
    pass

class Consultation(ConsultationBase):
    id: int
    user_id: int
    status: str
    created_at: datetime

    class Config:
        orm_mode = True

# FAQ schemas
class FAQBase(BaseModel):
    question: str
    answer: str
    category: str
    is_premium: bool

class FAQCreate(FAQBase):
    pass

class FAQ(FAQBase):
    id: int

    class Config:
        orm_mode = True

# Token schemas
class Token(BaseModel):
    access_token: str
    token_type: str

class TokenData(BaseModel):
    email: Optional[str] = None
EOFSCHEMAS

# Update schemas/__init__.py
echo "from app.schemas.schemas import User, UserCreate, UserBase, TaxGuide, TaxGuideCreate, TaxGuideBase, Consultation, ConsultationCreate, ConsultationBase, FAQ, FAQCreate, FAQBase, Token, TokenData" > app/schemas/__init__.py || handle_error "Failed to create schemas/__init__.py"

# Generate auth.py
cat > app/core/auth.py << 'EOFAUTH'
from datetime import datetime, timedelta
from typing import Optional
from jose import JWTError, jwt
from passlib.context import CryptContext
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.models.models import User
from app.schemas.schemas import TokenData

# to get a string like this run:
# openssl rand -hex 32
SECRET_KEY = "09d25e094faa6ca2556c818166b7a9563b93f7099f6f0f4caa6cf63b88e8d3e7"
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 30

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="token")

def verify_password(plain_password, hashed_password):
    return pwd_context.verify(plain_password, hashed_password)

def get_password_hash(password):
    return pwd_context.hash(password)

def authenticate_user(db: Session, email: str, password: str):
    user = db.query(User).filter(User.email == email).first()
    if not user or not verify_password(password, user.hashed_password):
        return False
    return user

def create_access_token(data: dict, expires_delta: Optional[timedelta] = None):
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=15)
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt

async def get_current_user(token: str = Depends(oauth2_scheme), db: Session = Depends(get_db)):
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        email: str = payload.get("sub")
        if email is None:
            raise credentials_exception
        token_data = TokenData(email=email)
    except JWTError:
        raise credentials_exception
    user = db.query(User).filter(User.email == token_data.email).first()
    if user is None:
        raise credentials_exception
    return user

async def get_current_active_user(current_user: User = Depends(get_current_user)):
    if not current_user.is_active:
        raise HTTPException(status_code=400, detail="Inactive user")
    return current_user

async def get_premium_user(current_user: User = Depends(get_current_active_user)):
    if not current_user.is_premium:
        raise HTTPException(status_code=403, detail="Premium feature requires subscription")
    return current_user
EOFAUTH

# Generate session.py
cat > app/db/session.py << 'EOFSESSION'
from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker

DATABASE_URL = "postgresql://localhost/ryze_nrtax_db"

engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
EOFSESSION

# Generate crud.py
cat > app/crud/crud.py << 'EOFCRUD'
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
EOFCRUD

# Generate router files
# auth.py
cat > app/routers/auth.py << 'EOFROUTER1'
from datetime import timedelta
from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.core.auth import authenticate_user, create_access_token, ACCESS_TOKEN_EXPIRE_MINUTES
from app.schemas.schemas import Token

router = APIRouter()

@router.post("/token", response_model=Token)
async def login_for_access_token(form_data: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(get_db)):
    user = authenticate_user(db, form_data.username, form_data.password)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"sub": user.email}, expires_delta=access_token_expires
    )
    return {"access_token": access_token, "token_type": "bearer"}
EOFROUTER1

# users.py
cat > app/routers/users.py << 'EOFROUTER2'
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
EOFROUTER2

# tax_guides.py
cat > app/routers/tax_guides.py << 'EOFROUTER3'
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
EOFROUTER3

# consultations.py
cat > app/routers/consultations.py << 'EOFROUTER4'
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
EOFROUTER4

# faqs.py
cat > app/routers/faqs.py << 'EOFROUTER5'
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
EOFROUTER5

# Update routers/__init__.py
echo "from app.routers import auth, users, tax_guides, consultations, faqs" > app/routers/__init__.py

# Generate main.py
cat > app/main.py << 'EOFMAIN'
from fastapi import FastAPI, Depends
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.routers import auth, users, tax_guides, consultations, faqs
from app.models import models
from app.db.init_db import engine

# Create database tables
models.Base.metadata.create_all(bind=engine)

app = FastAPI(title="Ryze NRTax API", description="API for Non-Resident Tax Information and Services")

# Configure CORS
origins = [
    "http://localhost",
    "http://localhost:3000",
    "http://localhost:8000",
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(auth.router, tags=["authentication"])
app.include_router(users.router, prefix="/api", tags=["users"])
app.include_router(tax_guides.router, prefix="/api", tags=["tax_guides"])
app.include_router(consultations.router, prefix="/api", tags=["consultations"])
app.include_router(faqs.router, prefix="/api", tags=["faqs"])

@app.get("/", tags=["root"])
async def root():
    return {"message": "Welcome to Ryze NRTax API for Non-Resident Tax Information and Services"}

# Add sample data if needed for development
@app.on_event("startup")
async def startup_event():
    db = next(get_db())
    # Check if data already exists
    tax_guides = db.query(models.TaxGuide).all()
    if not tax_guides:
        # Create sample tax guides
        db.add(models.TaxGuide(
            title="US-China Tax Treaty Overview",
            content="The United States and China have established a tax treaty to avoid double taxation...",
            is_premium=False
        ))
        db.add(models.TaxGuide(
            title="Form 1040-NR Guide for International Students",
            content="As an international student, you'll likely need to file Form 1040-NR...",
            is_premium=False
        ))
        db.add(models.TaxGuide(
            title="Scholarship Taxation for Non-Residents",
            content="Scholarships and fellowships granted to non-residents may be subject to different tax rules...",
            is_premium=False
        ))
        db.add(models.TaxGuide(
            title="Advanced Tax Planning for Non-Residents",
            content="This premium guide covers advanced tax planning strategies...",
            is_premium=True
        ))
        
        # Create sample FAQs
        db.add(models.FAQ(
            question="Do I need to file a US tax return as an international student?",
            answer="Yes, most international students will need to file at least one tax form, even if they didn't earn income...",
            category="Filing Requirements",
            is_premium=False
        ))
        db.add(models.FAQ(
            question="What is Form 8843?",
            answer="Form 8843 is a statement for exempt individuals with a medical condition or students...",
            category="Forms",
            is_premium=False
        ))
        db.add(models.FAQ(
            question="How does the US-China tax treaty affect my taxes?",
            answer="The US-China tax treaty may provide exemptions or reduced rates for certain types of income...",
            category="Tax Treaties",
            is_premium=False
        ))
        db.add(models.FAQ(
            question="What tax deductions can international students claim?",
            answer="As a non-resident, you may be eligible for certain deductions...",
            category="Deductions",
            is_premium=True
        ))
        
        db.commit()
EOFMAIN

# Make all scripts executable
chmod +x app/db/init_db.py || handle_error "Failed to set permissions for init_db.py"

echo -e "\n${GREEN}${PROJECT_NAME} backend setup completed successfully!${NC}"
cd .. || handle_error "Failed to return to parent directory"



