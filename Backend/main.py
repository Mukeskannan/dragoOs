from fastapi import FastAPI
from pydantic import BaseModel
from fastapi.middleware.cors import CORSMiddleware
from groq import Groq
from dotenv import load_dotenv
import os



load_dotenv()

app = FastAPI()
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # for development only
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
client = Groq(
    api_key=os.getenv("GROQ_API_KEY")
)

class ChatRequest(BaseModel):
    message: str

@app.get("/")
def home():
    return {"message": "Drago AI Running"}

@app.post("/chat")
def chat(data: ChatRequest):

    response = client.chat.completions.create(
        model="llama-3.3-70b-versatile",
        messages=[
            {
                "role": "user",
                "content": data.message
            }
        ]
    )

    return {
        "response": response.choices[0].message.content
    }