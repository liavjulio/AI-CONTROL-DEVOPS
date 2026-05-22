'''markdown
# 🚀 Liav DevOps Infrastructure & AI Control Plane

A comprehensive, end-to-end local infrastructure project integrating Infrastructure as Code (IaC), advanced observability, and an autonomous AI agent for self-managing infrastructure.

## 🏗️ System Architecture Overview

The system is designed as a complex local development environment simulating a full-scale cloud production setup, utilizing a multi-container architecture.

### 1. Infrastructure as Code (IaC) Layer
- Terraform: Manages local AWS resources (S3, SQS, DynamoDB, EC2) via LocalStack.
- Kubernetes: Orchestrates Nginx workloads on Kind (Kubernetes in Docker) with dynamic ConfigMap and Service management.
- Security: Automated security scanning using Checkov to ensure infrastructure best practices.

### 2. AI Agent & Automation Pipeline
- n8n Workflow: The central brain. It receives webhooks from the AI, processes the logic, stores chat history in PostgreSQL, and pushes commands to the SQS queue.
- 'bridge.py': Scans the local codebase, filters forbidden files, and synchronizes the project state to the AI agent to maintain context awareness.
- 'listen to ai.py': An automated listener that monitors the SQS queue. Upon receiving instructions from the AI (via n8n), it parses the response, updates local files, and triggers 'terraform apply' automatically.

### 3. Control Plane Dashboard
- 'dashboard.py' (Streamlit): A centralized management interface providing:
    - Real-time Docker status: Monitoring the health of all containers (Postgres, LocalStack, Nginx, etc.).
    - AI Memory Management: Direct access to the PostgreSQL backend to view chat history and context logs.
    - Sync Triggers: Manual triggers for codebase synchronization.
    - Observability Panels: Embedded Grafana dashboards for performance and log analysis.

### 4. Observability Stack
- Prometheus: Collects metrics from the host node, Nginx, and the K8s cluster.
- Grafana: Visualizes system performance (CPU, Memory, Traffic) via custom dashboards.
- Loki & Promtail: Aggregates and analyzes logs from all running containers.
- Alertmanager: Sends critical infrastructure alerts (e.g., Nginx Down, High CPU) directly to Telegram.

## 🛠️ Tech Stack
- IaC: Terraform, LocalStack, Checkov.
- Orchestration: Kubernetes (Kind), Docker Compose.
- Automation: n8n (Workflow Orchestration).
- Monitoring: Prometheus, Grafana, Loki, Promtail, Alertmanager.
- Backend/AI: Python, PostgreSQL, Streamlit, Boto3.

## 🚀 Getting Started

### Prerequisites
- Docker & Docker Compose
- Kind (Kubernetes in Docker)
- Python 3.x

### Setup
1. Environment Configuration: Create a '.env' file in the root directory:
   env
   TELEGRAM BOT TOKEN=your token
   TELEGRAM CHAT ID=your chat id
   DB USERNAME=your db username
   DB PASSWORD=your db password
   SESSION ID=your session id
   
2. Launch Infrastructure:
   bash
   docker-compose up -d
   
3. Launch Dashboard:
   '''bash
   streamlit run dashboard.py
   
4. Debug SQS: Use the provided script to check the queue:
   bash
   python3 scripts/debug sqs.py
   


## 📂 Project Structure
- '/modules': Terraform modules (Network, Compute, K8s).
- '/grafana': Grafana dashboards and provisioning configurations.
- '/scripts': Utility scripts for debugging and queue management.
- 'listen to ai.py': The core automation engine.
- 'dashboard.py': The central control plane.
- 'n8n workflow.json': The n8n automation workflow definition.
- 'bridge.py': The context synchronization bridge.
- 'alert rules.yml': Prometheus alerting rules.
- 'docker-compose.yml': Multi-container orchestration definition.

## 🧠 AI Agent Workflow
The system operates on a closed-loop feedback mechanism:
1. Context Ingestion: 'bridge.py' scans the project and sends the current state to the AI Agent via n8n.
2. Decision Making: The AI Agent (Gemini) analyzes the infrastructure state and determines if changes are required.
3. Execution: If changes are needed, the AI sends a command to the SQS queue.
4. Automation: 'listen to ai.py' picks up the command, applies the code changes to the disk, and executes 'terraform apply'.
5. Verification: The system verifies the deployment and reports back to the user via Telegram.

## 📊 Observability & Alerting
- Metrics: Prometheus scrapes metrics from the host and K8s cluster.
- Visualization: Grafana provides a unified view of system health.
- Log Aggregation: Loki collects logs from all containers, allowing for deep troubleshooting.
- Alerting: Alertmanager monitors for critical thresholds (e.g., Nginx downtime) and pushes notifications to your Telegram bot.

## 🛡️ Security & Best Practices
- IaC Scanning: The project includes a '.checkov.yml' configuration to enforce security standards on Terraform code.
- Resource Limits: All containers in 'docker-compose.yml' are configured with CPU and memory limits to ensure system stability.
- Environment Isolation: Sensitive data is managed via '.env' files and not hardcoded.

## 💡 Troubleshooting
- Check SQS: If the AI is not responding, run 'python3 scripts/debug sqs.py' to see if messages are stuck in the queue.
- Check Logs: Use 'docker logs -f <container name>' to inspect specific service logs.
- Dashboard: The Streamlit dashboard is your primary tool for monitoring the AI's memory and infrastructure health.

---
Built with ❤️ for DevOps Automation.
