from fastapi import APIRouter, HTTPException
from pydantic import BaseModel

router = APIRouter(prefix="/auth", tags=["auth"])

class LoginRequest(BaseModel):
    username: str
    password: str

@router.post("/login")
async def login(req: LoginRequest):
    # TODO: replace with real authentication logic
    if req.username == "demo" and req.password == "demo":
        return {"token": "fake-token-for-demo"}
    raise HTTPException(status_code=401, detail="Invalid credentials")

@router.get("/me")
async def me():
    return {"id": 1, "username": "demo"}
