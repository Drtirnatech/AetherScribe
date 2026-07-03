import os
import json
import time
import argparse
import torch
import whisperx
import requests
from sqlalchemy import create_session, create_engine
from .models import Meeting, TranscriptSegment, Speaker, Base

# SQLite sync connection for the worker
DATABASE_URL_SYNC = "sqlite:///./aetherscribe.db"
engine = create_engine(DATABASE_URL_SYNC)

def update_status(meeting_id, stage, progress):
    status_file = f"storage/status_{meeting_id}.json"
    with open(status_file, "w") as f:
        json.dump({"stage": stage, "progress": progress}, f)

def process_audio(meeting_id, file_path):
    device = "cuda" if torch.cuda.is_available() else "cpu"
    batch_size = 32 # Optimized for A6000
    compute_type = "float16" if device == "cuda" else "int8"

    try:
        # 1. Transcription
        update_status(meeting_id, "Transcribing", 20)
        model = whisperx.load_model("large-v3", device, compute_type=compute_type)
        audio = whisperx.load_audio(file_path)
        result = model.transcribe(audio, batch_size=batch_size)
        
        # 2. Alignment
        update_status(meeting_id, "Aligning", 40)
        model_a, metadata = whisperx.load_align_model(language_code=result["language"], device=device)
        result = whisperx.align(result["segments"], model_a, metadata, audio, device, return_char_alignments=False)
        
        # 3. Diarization
        update_status(meeting_id, "Diarizing", 60)
        diarize_model = whisperx.DiarizationPipeline(use_auth_token=None, device=device) # User needs to provide token if using HF model
        diarize_segments = diarize_model(audio)
        result = whisperx.assign_word_speakers(diarize_segments, result)
        
        # 4. Save to DB
        update_status(meeting_id, "Saving Results", 80)
        with create_session(engine) as session:
            meeting = session.query(Meeting).filter(Meeting.id == meeting_id).first()
            for seg in result["segments"]:
                segment = TranscriptSegment(
                    meeting_id=meeting_id,
                    speaker_id=seg.get("speaker", "UNKNOWN"),
                    text=seg["text"],
                    start_time=seg["start"],
                    end_time=seg["end"],
                    words=seg.get("words", [])
                )
                session.add(segment)
            
            meeting.status = "completed"
            session.commit()
            
        # 5. Analysis (Ollama)
        update_status(meeting_id, "Analyzing", 90)
        full_transcript = " ".join([s["text"] for s in result["segments"]])
        analyze_with_ollama(meeting_id, full_transcript)
        
        update_status(meeting_id, "Completed", 100)

    except Exception as e:
        print(f"Error in worker: {e}")
        update_status(meeting_id, "Failed", 0)

def analyze_with_ollama(meeting_id, transcript):
    prompt = f"Summarize the following meeting transcript and extract action items:\n\n{transcript}"
    try:
        response = requests.post(
            "http://localhost:11434/api/generate",
            json={
                "model": "gemma2:27b", # Adjusted to likely model name
                "prompt": prompt,
                "stream": False
            }
        )
        if response.status_code == 200:
            analysis = response.json().get("response", "")
            with create_session(engine) as session:
                meeting = session.query(Meeting).filter(Meeting.id == meeting_id).first()
                meeting.summary = analysis
                session.commit()
    except Exception as e:
        print(f"Ollama error: {e}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--meeting_id", required=True)
    parser.add_argument("--file_path", required=True)
    args = parser.parse_args()
    process_audio(args.meeting_id, args.file_path)
