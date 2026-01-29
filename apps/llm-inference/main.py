import os
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import List, Optional

app = FastAPI(title="LLM Inference Service")

OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")

class Message(BaseModel):
    role: str
    content: str

class ChatCompletionRequest(BaseModel):
    model: str = "gpt-3.5-turbo"
    messages: List[Message]

@app.get("/healthz")
async def healthz():
    return {"status": "ok"}

@app.post("/v1/chat/completions")
async def chat_completions(request: ChatCompletionRequest):
    # Mock response for now to allow running without valid credentials
    # In a real scenario, we would use the openai library here:
    # client = OpenAI(api_key=OPENAI_API_KEY)
    # response = client.chat.completions.create(...)
    
    if not OPENAI_API_KEY:
        print("WARNING: No OPENAI_API_KEY set. Returning mock response.")
        
    return {
        "id": "chatcmpl-mock",
        "object": "chat.completion",
        "created": 1677652288,
        "model": request.model,
        "choices": [{
            "index": 0,
            "message": {
                "role": "assistant",
                "content": f"This is a mock response from the LLM Inference Service. You said: {request.messages[-1].content}"
            },
            "finish_reason": "stop"
        }],
        "usage": {
            "prompt_tokens": 10,
            "completion_tokens": 10,
            "total_tokens": 20
        }
    }
