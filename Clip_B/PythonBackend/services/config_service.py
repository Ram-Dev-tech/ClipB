# config_service.py
# ClipB Python Backend
#
# Created by ClipB Team on 2026-07-18.
# Copyright © 2026 ClipB. All rights reserved.

import os
import json
from pathlib import Path
from typing import Dict, Any

class ConfigService:
    @staticmethod
    def get_config_dir() -> Path:
        """Returns the path to the app's Application Support directory."""
        home = Path.home()
        app_support = home / "Library" / "Application Support" / "ClipB"
        app_support.mkdir(parents=True, exist_ok=True)
        return app_support

    @classmethod
    def get_config_path(cls) -> Path:
        """Returns the path to the configuration file."""
        return cls.get_config_dir() / "config.json"

    @classmethod
    def load_config(cls) -> Dict[str, Any]:
        """Loads config from disk, returning defaults if not found."""
        config_path = cls.get_config_path()
        defaults = {
            "aiEnabled": False,
            "aiProvider": "openrouter",
            "aiApiKey": "",
            "aiEndpoint": "",
            "aiModelName": "",
            "aiTemperature": 0.7,
            "aiAutoSummarize": True,
            "aiAutoTag": True,
            "aiAutoTitle": False,
            "aiAutoOCR": True,
        }
        
        if not config_path.exists():
            return defaults
            
        try:
            with open(config_path, "r", encoding="utf-8") as f:
                loaded = json.load(f)
                # Merge defaults with loaded to ensure any new keys are populated
                for k, v in defaults.items():
                    if k not in loaded:
                        loaded[k] = v
                return loaded
        except Exception as e:
            print(f"[ClipB-Config] Warning: Failed to parse config file: {e}")
            return defaults

    @classmethod
    def save_config(cls, config: Dict[str, Any]) -> bool:
        """Saves config dict to disk."""
        config_path = cls.get_config_path()
        try:
            with open(config_path, "w", encoding="utf-8") as f:
                json.dump(config, f, indent=4, ensure_ascii=False)
            return True
        except Exception as e:
            print(f"[ClipB-Config] Error: Failed to save config to {config_path}: {e}")
            return False
