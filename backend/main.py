from fastapi import FastAPI, Depends, UploadFile, File, BackgroundTasks
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.ext.asyncio import AsyncSession
from .database import get_db, init_db
from . import models
import shutil
import os
import uuid

app = FastAPI(title="AetherScribe API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

UPLOAD_DIR = "storage/audio"
os.makedirs(UPLOAD_DIR, exist_ok=True)

@app.on_event("startup")
async def startup():
    await init_db()

@app.get("/")
async def root():
    return {"message": "AetherScribe API is running"}

@app.post("/upload")
async def upload_audio(
    background_tasks: BackgroundTasks,
    file: UploadFile = File(...),
    db: AsyncSession = Depends(get_db)
):
    file_id = str(uuid.uuid4())
    file_extension = file.filename.split(".")[-1]
    file_path = os.path.join(UPLOAD_DIR, f"{file_id}.{file_extension}")
    
    with open(file_path, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)
        
    meeting = models.Meeting(
        id=file_id,
        title=file.filename,
        audio_file_path=file_path,
        status="pending"
    )
    db.add(meeting)
    await db.commit()
    
    from .worker_manager import start_worker
    start_worker(file_id, file_path)
    
    return {"meeting_id": file_id, "status": "processing"}
