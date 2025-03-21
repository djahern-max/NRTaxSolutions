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
