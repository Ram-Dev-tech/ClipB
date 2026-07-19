# schemas.py
# ClipB Python Backend
#
# Created by ClipB Team on 2026-07-18.
# Copyright © 2026 ClipB. All rights reserved.

from pydantic import BaseModel, Field
from typing import Optional, List, Dict

# MARK: - AI Settings Config Schema (passed from Swift client or loaded from disk)

class AISettings(BaseModel):
    provider: str = Field(..., description="AI Provider name (e.g. openrouter, openai, anthropic, gemini, ollama)")
    api_key: Optional[str] = Field(None, description="API authorization key for the provider")
    endpoint: Optional[str] = Field(None, description="Custom base URL endpoint (optional)")
    model_name: Optional[str] = Field(None, description="Model identifier string")
    temperature: Optional[float] = Field(0.7, description="Sampling temperature")

# MARK: - Request Schemas

class SummarizeRequest(BaseModel):
    text: str = Field(..., description="Text content to summarize")
    settings: Optional[AISettings] = Field(None, description="Overrides for default settings")

class ExplainRequest(BaseModel):
    text: str = Field(..., description="Code or text content to explain")
    settings: Optional[AISettings] = Field(None, description="Overrides for default settings")

class ImproveRequest(BaseModel):
    text: str = Field(..., description="Text to improve writing style")
    settings: Optional[AISettings] = Field(None, description="Overrides for default settings")

class GrammarRequest(BaseModel):
    text: str = Field(..., description="Text to perform grammar correction on")
    settings: Optional[AISettings] = Field(None, description="Overrides for default settings")

class TranslateRequest(BaseModel):
    text: str = Field(..., description="Text to translate")
    target_language: str = Field(..., description="Language to translate into (e.g., Spanish, German, French, Chinese)")
    settings: Optional[AISettings] = Field(None, description="Overrides for default settings")

class CodeActionRequest(BaseModel):
    code: str = Field(..., description="Code snippet to process")
    action: str = Field(..., description="Action to perform (e.g. explain, optimize, refactor, comment, fix)")
    settings: Optional[AISettings] = Field(None, description="Overrides for default settings")

class GeneralChatRequest(BaseModel):
    prompt: str = Field(..., description="User prompt")
    context: Optional[str] = Field(None, description="Optional selected clipboard content context")
    settings: Optional[AISettings] = Field(None, description="Overrides for default settings")

# MARK: - Response Schemas

class AISimpleResponse(BaseModel):
    result: str = Field(..., description="The generated textual result from the model")
    model: str = Field(..., description="The actual model identifier that responded")
    provider: str = Field(..., description="The provider utilized")
