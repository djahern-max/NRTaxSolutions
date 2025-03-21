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
