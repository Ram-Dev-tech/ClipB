# ai_service.py
# ClipB Python Backend
#
# Created by ClipB Team on 2026-07-18.
# Copyright © 2026 ClipB. All rights reserved.

import os
import litellm
from typing import Dict, Any, Optional
from models.schemas import AISettings

# Disable telemetries and prompt logging if any
litellm.telemetry = False

class AIService:
    
    @staticmethod
    def get_litellm_params(settings: AISettings) -> Dict[str, Any]:
        """Resolves provider settings into parameters expected by litellm.completion."""
        provider = settings.provider.lower()
        api_key = settings.api_key
        model_name = settings.model_name
        endpoint = settings.endpoint
        temperature = settings.temperature if settings.temperature is not None else 0.7

        # 1. Determine target model name
        if not model_name:
            if provider == "openai":
                model = "gpt-4o"
            elif provider == "anthropic":
                model = "claude-3-5-sonnet-20240620"
            elif provider == "gemini":
                model = "gemini/gemini-2.5-flash"
            elif provider == "ollama":
                model = "ollama/llama3"
            elif provider == "openrouter":
                model = "openrouter/google/gemini-2.5-flash"
            else:
                model = "gpt-4o"
        else:
            # Map model name format
            if provider == "openai" and not model_name.startswith("openai/"):
                model = f"openai/{model_name}"
            elif provider == "anthropic" and not model_name.startswith("anthropic/"):
                model = f"anthropic/{model_name}"
            elif provider == "gemini" and not model_name.startswith("gemini/"):
                model = f"gemini/{model_name}"
            elif provider == "ollama" and not model_name.startswith("ollama/"):
                model = f"ollama/{model_name}"
            elif provider == "openrouter" and not model_name.startswith("openrouter/"):
                model = f"openrouter/{model_name}"
            else:
                model = model_name

        # 2. Build parameter dictionary
        params = {
            "model": model,
            "temperature": temperature,
            "messages": []
        }

        # 3. Add API credentials & base URL overrides
        if api_key:
            params["api_key"] = api_key
            
        if endpoint:
            params["api_base"] = endpoint
        elif provider == "ollama" and not endpoint:
            # Default local Ollama endpoint
            params["api_base"] = "http://localhost:11434"

        return params

    @classmethod
    async def generate_response(
        cls, 
        system_prompt: str, 
        user_content: str, 
        settings: AISettings
    ) -> Dict[str, Any]:
        """Wrapper invoking litellm.acompletion to call the configured model."""
        params = cls.get_litellm_params(settings)
        params["messages"] = [
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": user_content}
        ]

        try:
            # Run asynchronously to avoid blocking uvicorn
            response = await litellm.acompletion(**params)
            
            result_text = response.choices[0].message.content or ""
            return {
                "result": result_text.strip(),
                "model": params["model"],
                "provider": settings.provider
            }
        except Exception as e:
            # Catch details and wrap
            print(f"[ClipB-AI] Error calling model {params.get('model')}: {e}")
            raise RuntimeError(f"AI Service Error: {str(e)}")

    # MARK: - Prompts Implementation

    @classmethod
    async def summarize(cls, text: str, settings: AISettings) -> Dict[str, Any]:
        system = (
            "You are a helpful assistant integrated into a clipboard manager called ClipB. "
            "Generate a highly concise summary of the provided text. Focus on capturing the "
            "most important points, action items, or core meaning. Avoid introductory filler words. "
            "Format the output in a clean, easily readable layout (bullet points if helpful). "
            "Limit the summary to 3-5 sentences maximum."
        )
        return await cls.generate_response(system, text, settings)

    @classmethod
    async def explain(cls, text: str, settings: AISettings) -> Dict[str, Any]:
        system = (
            "You are an expert tutor and technical assistant. Provide a clear, intuitive, and "
            "concise explanation for the text or code snippet copied to the clipboard. "
            "Highlight key concepts, syntax significance, or context, making it easy to digest in seconds."
        )
        return await cls.generate_response(system, text, settings)

    @classmethod
    async def improve(cls, text: str, settings: AISettings) -> Dict[str, Any]:
        system = (
            "You are a professional editor. Rewrite the following text to make it more professional, "
            "engaging, clear, and grammatically polished. Keep the original meaning intact. "
            "Provide only the improved text output without conversational greetings or explanations."
        )
        return await cls.generate_response(system, text, settings)

    @classmethod
    async def grammar(cls, text: str, settings: AISettings) -> Dict[str, Any]:
        system = (
            "You are a grammar correction tool. Correct all spelling, punctuation, syntax, and "
            "grammatical errors in the following text. Do not rewrite style elements unnecessarily. "
            "Provide only the corrected text as the output, with no introduction or outro."
        )
        return await cls.generate_response(system, text, settings)

    @classmethod
    async def translate(cls, text: str, target_language: str, settings: AISettings) -> Dict[str, Any]:
        system = (
            f"You are a professional translator. Translate the following text into {target_language}. "
            "Maintain the correct tone, formatting, and technical terms. Provide only the translated "
            "output without adding explanations, notes, or introductions."
        )
        return await cls.generate_response(system, text, settings)

    @classmethod
    async def process_code_action(cls, code: str, action: str, settings: AISettings) -> Dict[str, Any]:
        action_prompts = {
            "explain": (
                "You are an expert developer. Provide a brief but thorough explanation of what this "
                "code does, its input/output expectations, and any important design patterns used."
            ),
            "optimize": (
                "Optimize the following code for better performance, memory footprint, or algorithmic complexity. "
                "Provide the optimized code block followed by a brief bulleted explanation of your changes."
            ),
            "refactor": (
                "Refactor the following code to improve readability, clean structure, and modern standards. "
                "Provide only the refactored code and minimal notes."
            ),
            "comment": (
                "Add clear, descriptive comments (docstrings and inline explanations) to the following code. "
                "Do not modify the underlying logic. Return the annotated code."
            ),
            "fix": (
                "Analyze the following code snippet for potential bugs, syntax errors, or runtime issues. "
                "Provide the corrected version and a concise list of fixes made."
            )
        }
        
        system = action_prompts.get(action.lower(), "You are an expert developer helping to analyze code.")
        # Ensure code format block matches
        user_content = f"```\n{code}\n```"
        return await cls.generate_response(system, user_content, settings)
