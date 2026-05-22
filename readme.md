# 🚀 Unified DevOps AI Control Plane & Observability Stack

A production-ready, multi-container DevOps infrastructure that couples a **Long-Term AI Memory Engine** with a full **Observability Stack (LGTM)**. This control plane allows an AI Agent to persist context natively in PostgreSQL while providing engineers with real-time hardware telemetry, centralized logging, and proactive alerting.

---

## 🏗️ System Architecture

The project orchestrates the following microservices using Docker:
* **Central Dashboard (Streamlit):** An executive-grade UI that manages the AI memory grid, monitors live container operational health (via Docker Daemon API), and embeds clean telemetry streams.
* **AI Ingestion & Database (PostgreSQL):** Persistent relational layer storing long-term chat contexts and synced codebases routed via n8n.
* **Mock Cloud Infrastructure (LocalStack):** Simulates enterprise AWS SQS queues locally for distributed asynchronous messaging.
* **Telemetry & Metrics (Prometheus & Grafana):** Ingests host-level and container computing metrics, displaying streamlined, standalone analytical panels.
* **Log Aggregation (Loki):** Real-time, distributed log collection for rapid system auditing.

---

## ⚡ Key Features

* **Secure Configuration:** Zero hardcoded credentials. Full compliance using environment variable separation (.env).
* **Clean Telemetry Iframe Embedding:** Grafana panels are stripped of administrative navigation bars using d-solo solo-panel endpoints for a native application feel.
* **Live Docker Health Tracking:** Interactive dashboard sidebar communicating directly with docker.sock to report service states (🟢 Active / 🔴 Offline).
* **Automated Cold Starts:** LocalStack auto-provisions necessary AWS SQS infrastructure on boot using container initialization scripts (init-sqs/).

---

## 🛠️ Quick Start & Setup

### Prerequisites
* Docker Desktop installed on macOS / Linux / Windows.
* Python 3.10+ installed locally.

### 1. Clone & Organize
Clone this repository to your local machine and ensure your structure mirrors the production schema.

### 2. Environment Configuration
Duplicate the configuration template and populate your secure credentials:

cp .env.example .env

*Open .env and insert your secure database passwords, Telegram Bot tokens, and Gemini API keys.*

### 3. Spin Up the Infrastructure
Launch all microservices in detached mode:

docker-compose up -d

*LocalStack will automatically run init-sqs/init.sh to construct your active queues.*

### 4. Install Dependencies & Launch Dashboard
Install the required Python modules and execute the live control plane:

pip install -r requirements.txt
streamlit run dashboard.py

---

## 🚨 Incident Management & Production Alignment
Alerting rules are set via Prometheus to automatically dispatch system failures to alertmanager. Utilizing an automated webhook, alerts are routed straight back into your integrated messaging services (Telegram) ensuring absolute system awareness.