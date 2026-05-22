#!/bin/bash
awslocal sqs create-queue --queue-name codex-ai-responses --region us-east-1
echo "SQS queue 'codex-ai-responses' created successfully in LocalStack."