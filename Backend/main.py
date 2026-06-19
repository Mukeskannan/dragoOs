import os
import json
import re
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from groq import Groq
from dotenv import load_dotenv
from typing import Optional

load_dotenv()

app = FastAPI()
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

client = Groq(api_key=os.getenv("GROQ_API_KEY"))

MEMORY_EXTRACTION_PROMPT = """You are a memory extraction assistant.
Extract ONLY factual personal information the user reveals about themselves.

Rules:
- Return ONLY a raw JSON object — no markdown, no backticks, no explanation
- Allowed keys: name, age, location, occupation, hobby, interest, language, goal, preference
- If nothing personal is revealed, return exactly: {}
- Values must be short strings (max 5 words)
- Never infer or guess — only extract what is explicitly stated

Examples:
User: "Hi I'm Mukesh, I live in Hyderabad"
Output: {"name": "Mukesh", "location": "Hyderabad"}

User: "What's the weather like?"
Output: {}

User: "I'm learning Flutter for my startup"
Output: {"interest": "Flutter", "goal": "building a startup"}
"""

DRAGO_SYSTEM_PROMPT = """You are Drago, a smart and helpful AI assistant.
You are direct, friendly, and knowledgeable.
Answer clearly and concisely. If you don't know something, say so honestly.
"""


# ─── Models ───────────────────────────────────────────────────────────────────

class ChatRequest(BaseModel):
    message: str
    memory_context: Optional[str] = None
    history: Optional[list[dict]] = None


class MemoryRequest(BaseModel):
    message: str


# ─── Safe JSON extractor ──────────────────────────────────────────────────────

def safe_parse_memory(raw: str) -> dict:
    if not raw or not raw.strip():
        return {}
    try:
        return json.loads(raw.strip())
    except json.JSONDecodeError:
        pass
    try:
        cleaned = re.sub(r"```(?:json)?", "", raw).replace("```", "").strip()
        return json.loads(cleaned)
    except json.JSONDecodeError:
        pass
    try:
        match = re.search(r"\{[^{}]*\}", raw, re.DOTALL)
        if match:
            return json.loads(match.group())
    except (json.JSONDecodeError, AttributeError):
        pass
    return {}


# ─── Endpoints ────────────────────────────────────────────────────────────────

@app.get("/")
def home():
    return {"status": "Drago AI running"}


@app.post("/extract-memory")
def extract_memory(data: MemoryRequest):
    try:
        response = client.chat.completions.create(
            model="llama-3.1-8b-instant",   # fast small model
            messages=[
                {"role": "system", "content": MEMORY_EXTRACTION_PROMPT},
                {"role": "user",   "content": data.message},
            ],
            temperature=0,
            max_tokens=2048,
        )
        raw = response.choices[0].message.content
        return {"memory": safe_parse_memory(raw)}

    except Exception as e:
        print(f"[extract-memory] Error: {e}")
        return {"memory": {}}


@app.post("/chat")
def chat(data: ChatRequest):
    try:
        system = DRAGO_SYSTEM_PROMPT
        if data.memory_context:
            system += f"\n\nWhat you know about this user:\n{data.memory_context}"

        messages = [{"role": "system", "content": system}]

        if data.history:
            messages.extend(data.history[-6:])  # ← was 10, now 6 turns = less tokens

        messages.append({"role": "user", "content": data.message})

        response = client.chat.completions.create(
            model="llama-3.1-8b-instant",   # ← THE KEY FIX: was 70b, now 8b instant
            messages=messages,
            temperature=0.7,
            max_tokens=512,                  # ← was 1024, now 512 = 2x faster
        )

        return {"response": response.choices[0].message.content}

    except Exception as e:
        print(f"[chat] Error: {e}")
        raise HTTPException(status_code=500, detail=str(e))