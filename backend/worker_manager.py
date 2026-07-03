import subprocess
import os
import sys

def start_worker(meeting_id: str, file_path: str):
    # Determine the python executable (use the current one or a specific venv)
    python_exe = sys.executable
    worker_script = os.path.join(os.path.dirname(__file__), "worker.py")
    
    # Run as a detached sub-process
    process = subprocess.Popen(
        [python_exe, worker_script, "--meeting_id", meeting_id, "--file_path", file_path],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        creationflags=subprocess.CREATE_NEW_PROCESS_GROUP if os.name == 'nt' else 0
    )
    return process.pid
