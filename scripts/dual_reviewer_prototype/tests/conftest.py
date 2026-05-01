# conftest.py — pytest 共通 fixture / 設定
import sys
from pathlib import Path

PROTOTYPE_ROOT = Path(__file__).resolve().parents[1]
BOOTSTRAP_PATH = PROTOTYPE_ROOT / "skills" / "dr-init" / "bootstrap.py"
SCHEMAS_DIR = PROTOTYPE_ROOT / "schemas"
PATTERNS_DIR = PROTOTYPE_ROOT / "patterns"
PROMPTS_DIR = PROTOTYPE_ROOT / "prompts"
FRAMEWORK_DIR = PROTOTYPE_ROOT / "framework"
CONFIG_DIR = PROTOTYPE_ROOT / "config"
TERMINOLOGY_DIR = PROTOTYPE_ROOT / "terminology"
EXTENSIONS_DIR = PROTOTYPE_ROOT / "extensions"
SKILLS_DIR = PROTOTYPE_ROOT / "skills"
