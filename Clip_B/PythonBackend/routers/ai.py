# ai.py
# ClipB Python Backend
#
# Created by ClipB Team on 2026-07-18.
# Copyright © 2026 ClipB. All rights reserved.

from fastapi import APIRouter, HTTPException, Depends
from typing import Optional
from models.schemas import (
    AISettings,
    SummarizeRequest,
    ExplainRequest,
    ImproveRequest,
    GrammarRequest,
    TranslateRequest,
    CodeActionRequest,
    GeneralChatRequest,
    AISimpleResponse
)
from services.ai_service import AIService
from services.config_service import ConfigService

router = APIRouter(prefix="/ai", tags=["AI Integration"])

def get_effective_settings(req_settings: Optional[AISettings]) -> AISettings:
    """Helper to merge request-level overrides with the system-wide configuration."""
    config = ConfigService.load_config()
    
    # Resolve system defaults
    default_settings = AISettings(
        provider=config.get("aiProvider", "openrouter"),
        api_key=config.get("aiApiKey", "") or None,
        endpoint=config.get("aiEndpoint", "") or None,
        model_name=config.get("aiModelName", "") or None,
        temperature=config.get("aiTemperature", 0.7)
    )
    
    if not req_settings:
        return default_settings
        
    return AISettings(
        provider=req_settings.provider if req_settings.provider else default_settings.provider,
        api_key=req_settings.api_key if req_settings.api_key is not None else default_settings.api_key,
        endpoint=req_settings.endpoint if req_settings.endpoint is not None else default_settings.endpoint,
        model_name=req_settings.model_name if req_settings.model_name is not None else default_settings.model_name,
        temperature=req_settings.temperature if req_settings.temperature is not None else default_settings.temperature
    )

# MARK: - AI Action Routes

@router.post("/summarize", response_model=AISimpleResponse)
async def summarize(request: SummarizeRequest):
    settings = get_effective_settings(request.settings)
    try:
        response = await AIService.summarize(request.text, settings)
        return AISimpleResponse(**response)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/explain", response_model=AISimpleResponse)
async def explain(request: ExplainRequest):
    settings = get_effective_settings(request.settings)
    try:
        response = await AIService.explain(request.text, settings)
        return AISimpleResponse(**response)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/improve", response_model=AISimpleResponse)
async def improve(request: ImproveRequest):
    settings = get_effective_settings(request.settings)
    try:
        response = await AIService.improve(request.text, settings)
        return AISimpleResponse(**response)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/grammar", response_model=AISimpleResponse)
async def grammar(request: GrammarRequest):
    settings = get_effective_settings(request.settings)
    try:
        response = await AIService.grammar(request.text, settings)
        return AISimpleResponse(**response)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/translate", response_model=AISimpleResponse)
async def translate(request: TranslateRequest):
    settings = get_effective_settings(request.settings)
    try:
        response = await AIService.translate(request.text, request.target_language, settings)
        return AISimpleResponse(**response)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/code", response_model=AISimpleResponse)
async def code_action(request: CodeActionRequest):
    settings = get_effective_settings(request.settings)
    try:
        response = await AIService.process_code_action(request.code, request.action, settings)
        return AISimpleResponse(**response)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/chat", response_model=AISimpleResponse)
async def general_chat(request: GeneralChatRequest):
    settings = get_effective_settings(request.settings)
    system = (
        "You are an assistant inside ClipB, a clipboard manager. Be brief and direct. "
        "The user will type a prompt, and you should answer it. Keep formatting clean."
    )
    if request.context:
        system += f"\nHere is context from their current clipboard: \n```\n{request.context}\n```"
    
    try:
        response = await AIService.generate_response(system, request.prompt, settings)
        return AISimpleResponse(**response)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
