# AetherScribe Design Document

**Date:** 2026-07-03
**Status:** Approved
**Project Goal:** Build a professional-grade, local-first meeting transcription and analysis tool optimized for the NVIDIA RTX A6000 Ada.

## 1. System Architecture
AetherScribe uses a **Local Orchestrator** architecture to ensure VRAM isolation and UI responsiveness.

- **FastAPI Backend:** Central orchestrator for API, DB, and Worker management.
- **Sub-process AI Worker:** A dedicated process for running the WhisperX and Ollama pipelines. This ensures total VRAM release on task completion.
- **Vite + React Frontend:** A premium dark-mode interface with WebSockets for real-time telemetry.
- **Storage:** SQLite for metadata/transcripts and Local Filesystem for audio/waveforms.

## 2. AI Pipeline
Optimized for high-throughput on 48GB VRAM:
1. **Pre-processing:** FFmpeg (16kHz mono) + VAD.
2. **Transcription:** WhisperX `large-v3` with high batch sizes (32-64).
3. **Refinement:** Forced word alignment and pyannote.audio diarization.
4. **Analysis:** Ollama (`gemma4:31b`) for summarization and action item extraction.

## 3. Data Schema
- **Meetings:** Metadata, status, and summary results.
- **Transcript Segments:** Speaker-tagged text blocks with word-level JSON timestamps.
- **Speakers:** Mapping of IDs to user-defined names and UI colors.

## 4. UI/UX Design
- **Aesthetic:** Dark Mode, Glassmorphism, Deep Purple/Blue gradients.
- **Key Features:**
    - Interactive `wavesurfer.js` waveform.
    - Chat-like threaded transcript with click-to-seek functionality.
    - Real-time GPU Monitor (VRAM/Power).
    - Integrated Analysis panel for summaries and action items.

## 5. Deployment & Tech Stack
- **OS:** Windows 11 (targeted).
- **Backend:** Python 3.10+, FastAPI, WhisperX, Pyannote, Ollama.
- **Frontend:** Node.js, Vite, React, TypeScript, Tailwind CSS.
- **GPU Driver:** CUDA-accelerated libraries.
