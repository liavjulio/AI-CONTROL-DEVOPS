import os
import requests
from dotenv import load_dotenv

load_dotenv()   
URL = "https://extent-cartwheel-stereo.ngrok-free.dev/webhook/dev-agent"
PROJECT_PATH = "." 
MAX_FILE_SIZE = 1 * 1024 * 1024 

FORBIDDEN_FILES = {'terraform.tfstate', '.env', 'secrets.json', 'package-lock.json'}
FORBIDDEN_DIRS = {'node_modules', '.git', '.terraform', '__pycache__', '.venv'}

def get_ai_ready_context(project_path):
    output = []
    allowed_extensions = {'.tf', '.yaml', '.yml', '.py', '.js', '.json', '.txt'}
    abs_path = os.path.abspath(project_path)
    
    for root, dirs, files in os.walk(abs_path):
        dirs[:] = [d for d in dirs if d not in FORBIDDEN_DIRS and not d.startswith('.')]
        
        for file in files:
            file_path = os.path.join(root, file)
            
            if os.path.islink(file_path) or file in FORBIDDEN_FILES:
                continue
                
            ext = os.path.splitext(file)[1].lower()
            if ext in allowed_extensions:
                rel_path = os.path.relpath(file_path, abs_path)
                try:
                    if os.path.getsize(file_path) > MAX_FILE_SIZE:
                        continue
                        
                    with open(file_path, 'r', encoding='utf-8') as f:
                        content = f.read().strip()
                        if content:
                            output.append(f"### FILE: {rel_path}\n```\n{content}\n```\n")
                except Exception as e:
                    print(f"⚠️ Could not read {rel_path}: {e}")
                    
    return "\n".join(output)

if __name__ == "__main__":
    context_text = get_ai_ready_context(PROJECT_PATH)
    data = {
        "session_id": os.getenv("SESSION_ID"),
        "action": "sync_project",
        "project_name": os.path.basename(os.getcwd()),
        "files": context_text
    }

    try:
        response = requests.post(URL, json=data, timeout=120)
        response.raise_for_status()
        print(f"✅ Project Synced! Status: {response.status_code}")
    except requests.exceptions.RequestException as e:
        print(f"❌ Failed to sync: {e}")