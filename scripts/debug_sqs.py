import boto3
import time

sqs = boto3.client('sqs', endpoint_url='http://127.0.0.1:4566', region_name='us-east-1')
queue_url = "http://127.0.0.1:4566/000000000000/codex-ai-responses"

def check_queue():
    try:
        attrs = sqs.get_queue_attributes(QueueUrl=queue_url, AttributeNames=['ApproximateNumberOfMessages'])
        visible = attrs['Attributes']['ApproximateNumberOfMessages']
        print(f"📊 הודעות שמחכות בתור: {visible}")
        return int(visible)
    except Exception as e:
        print(f"❌ שגיאה: {e}")
        return -1

def send_test_message():
    test_content = "### FILE: test_file.txt\n```\nSuccess! The bridge is working.\n```"
    try:
        sqs.send_message(QueueUrl=queue_url, MessageBody=test_content)
        print("🚀 הודעת בדיקה נשלחה!")
    except Exception as e:
        print(f"❌ שגיאה בשליחה: {e}")

if __name__ == "__main__":
    count = check_queue()
    if count == 0:
        choice = input("התור ריק. לשלוח בדיקה? (y/n): ")
        if choice.lower() == 'y':
            send_test_message()