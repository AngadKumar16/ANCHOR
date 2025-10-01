from fastapi import FastAPI

app = FastAPI()

@app.get("/")
async def root():
    return {"status": "ok", "msg": "Backend running"}


from .auth import router as auth_router
app.include_router(auth_router)
