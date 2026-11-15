
from fastapi import FastAPI
from datetime import datetime, timezone

app = FastAPI(
    title="Pulse Platform API",
    description="Backend API for Pulse Platform",
    version="1.0.0"
)


@app.get("/")
def root():
    return {
        "application": "Pulse Platform API",
        "status": "running",
        "message": "Welcome to Pulse API"
    }


@app.get("/api/")
def api_home():
    return {
        "service": "Pulse API",
        "status": "healthy"
    }


@app.get("/api/health")
def health_check():
    return {
        "service": "Pulse API",
        "status": "healthy",
        "timestamp": datetime.now(timezone.utc).isoformat()
    }
