from sqlalchemy import Column, String, Float, DateTime, Text, JSON, ForeignKey
from sqlalchemy.orm import declarative_base, relationship
import datetime
import uuid

Base = declarative_base()

class Meeting(Base):
    __tablename__ = "meetings"
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    title = Column(String, nullable=False)
    audio_file_path = Column(String, nullable=False)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)
    status = Column(String, default="pending")  # pending, processing, completed, failed
    summary = Column(Text, nullable=True)
    action_items = Column(JSON, nullable=True)
    
    segments = relationship("TranscriptSegment", back_populates="meeting", cascade="all, delete-orphan")
    speakers = relationship("Speaker", back_populates="meeting", cascade="all, delete-orphan")

class TranscriptSegment(Base):
    __tablename__ = "transcript_segments"
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    meeting_id = Column(String, ForeignKey("meetings.id"))
    speaker_id = Column(String)
    text = Column(Text)
    start_time = Column(Float)
    end_time = Column(Float)
    words = Column(JSON)  # List of dicts with word, start, end
    
    meeting = relationship("Meeting", back_populates="segments")

class Speaker(Base):
    __tablename__ = "speakers"
    id = Column(String, primary_key=True)  # e.g., "SPEAKER_00"
    meeting_id = Column(String, ForeignKey("meetings.id"), primary_key=True)
    custom_name = Column(String, nullable=True)
    color = Column(String)
    
    meeting = relationship("Meeting", back_populates="speakers")
