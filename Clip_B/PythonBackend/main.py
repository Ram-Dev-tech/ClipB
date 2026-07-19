# main.py
# ClipB Python Backend
#
# Created by ClipB Team on 2026-07-18.
# Copyright © 2026 ClipB. All rights reserved.

import uvicorn
from fastapi import FastAPI, APIRouter, Dict, Any, Body
from fastapi.middleware.cors import CORSMiddleware
from routers import ai
from services.config_service import ConfigService

app = FastAPI(
    title="ClipB Backend Service",
    description="Python AI Engine for ClipB Clipboard Manager",
    version="1.0.0"
)

# Allow requests only from localhost/local apps for security
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Local app communication
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Register routers
app.include_router(ai.router)

@app.get("/health")
def health_check():
    """Health check endpoint for the Swift client to poll on launch."""
    return {"status": "ok", "message": "ClipB Backend Service is healthy"}

@app.get("/config")
def get_config():
    """Retrieves current application settings from disk."""
    return ConfigService.load_config()

@app.post("/config")
def save_config(config: dict = Body(...)):
    """Saves new application settings from the Swift client to disk."""
    success = ConfigService.save_config(config)
    return {"status": "success" if success else "error"}

if __name__ == "__main__":
    uvicorn.run("main:app", host="127.0.0.1", port=8321, reload=False)
