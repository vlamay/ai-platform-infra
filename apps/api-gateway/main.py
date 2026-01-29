import os
import httpx
from fastapi import FastAPI, HTTPException, Request
from pydantic import BaseModel

app = FastAPI(title="AI Platform API Gateway")

LLM_SERVICE_URL = os.getenv("LLM_SERVICE_URL", "http://localhost:8001")

class ChatRequest(BaseModel):
    message: str
    model: str = "gpt-3.5-turbo"

@app.get("/healthz")
async def healthz():
    return {"status": "ok"}

@app.post("/v1/chat")
async def chat(request: ChatRequest):
    async with httpx.AsyncClient() as client:
        try:
            # Forwarding request to LLM Inference Service
            response = await client.post(
                f"{LLM_SERVICE_URL}/v1/chat/completions",
                json=request.dict(),
                timeout=60.0
            )
            response.raise_for_status()
            return response.json()
        except httpx.RequestError as exc:
            raise HTTPException(status_code=503, detail=f"LLM Service unavailable: {exc}")
        except httpx.HTTPStatusError as exc:
            raise HTTPException(status_code=exc.response.status_code, detail=exc.response.text)
