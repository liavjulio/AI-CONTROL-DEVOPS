import boto3
import time
import re
import os
import subprocess

endpoint = 'http://127.0.0.1:4566'
queue_url = 'http://127.0.0.1:4566/000000000000/codex-ai-responses'

sqs = boto3.client(
    'sqs',
    endpoint_url=endpoint,
    region_name='us-east-1',
    aws_access_key_id='test',
    aws_secret_access_key='test'
)

def apply_changes_to_disk(text):
    sections = re.split(r"(?:###\s*)?FILE:\s*", text)
    if len(sections) < 2:
        return False

    changes_made = False
    for section in sections[1:]:
        try:
            lines = section.strip().split('\n')
            filename = lines[0].split()[0].strip().replace('`', '').replace("'", "").replace(":", "")
            
            code_match = re.search(r"(?:```|''')(?:[\w+]+)?\n(.*?)\n(?:```|''')", section, re.DOTALL)
            
            if code_match:
                new_content = code_match.group(1)
                
                new_content = new_content.replace('\\n', '\n').replace('\\t', '\t')
                
                with open(filename, "w", encoding="utf-8") as f:
                    f.write(new_content)
                print(f"✅ הקובץ עודכן בהצלחה: {filename}")
                changes_made = True
            else:
                if len(lines) > 1:
                    content_fallback = "\n".join(lines[1:]).strip()
                    if "import " in content_fallback or "resource " in content_fallback:
                        with open(filename, "w", encoding="utf-8") as f:
                            f.write(content_fallback)
                        print(f"✅ קובץ עודכן (ללא סוגרי קוד): {filename}")
                        changes_made = True
        except Exception as e:
            print(f"💥 שגיאה בעיבוד {filename}: {e}")
            
    return changes_made

print("🚀 המאזין התחבר בהצלחה ומחכה להודעות...")

def run_terraform():
    """מריץ פקודות טרפורם ומחזיר את התוצאה"""
    print("🚀 מפעיל Terraform Apply...")
    try:
        subprocess.run(["terraform", "init", "-no-color"], capture_output=True, text=True)
        
        result = subprocess.run(
            ["terraform", "apply", "-auto-approve", "-no-color"],
            capture_output=True,
            text=True,
            check=True
        )
        print("✅ Terraform הושלם בהצלחה!")
        return f"Terraform Success:\n{result.stdout[-500:]}" 
    except subprocess.CalledProcessError as e:
        print(f"❌ שגיאה ב-Terraform: {e.stderr}")
        return f"Terraform Error:\n{e.stderr}"
    
while True:
    try:
        response = sqs.receive_message(
            QueueUrl=queue_url,
            MaxNumberOfMessages=1,
            WaitTimeSeconds=2
        )

        if 'Messages' in response:
            for message in response['Messages']:
                body = message['Body']
                
                if apply_changes_to_disk(body):
                    
                    tf_result = ""
                    if "### RUN_TERRAFORM" in body:
                        tf_result = run_terraform()
                    
                    if "### SYNC_REQUIRED" in body or "### RUN_TERRAFORM" in body:
                        print("🔄 מפעיל bridge.py לעדכון ה-AI בתוצאות...")
                        try:
                            subprocess.run(["python3", "bridge.py"], check=True)
                            print("✅ סינכרון הושלם.")
                        except Exception as e:
                            print(f"⚠️ שגיאה בסינכרון: {e}")
                    else:
                        print("ℹ️ לא נדרש סינכרון חוזר (המשך עבודה ללא שליחת Context).")
                else:
                    print("ℹ️ הסקריפט לא הצליח לחתוך את הקובץ מהטקסט הזה.")
                    
                sqs.delete_message(QueueUrl=queue_url, ReceiptHandle=message['ReceiptHandle'])
        else:
            print(".", end="", flush=True)
            
    except Exception as e:
        print(f"\n❌ שגיאה בחיבור: {e}")
        time.sleep(2)
    
    time.sleep(0.5)