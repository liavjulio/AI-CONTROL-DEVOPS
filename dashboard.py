import streamlit as st
import requests
import psycopg2
import pandas as pd
import subprocess
import docker
import os
from dotenv import load_dotenv

load_dotenv()

st.set_page_config(page_title="DevOps AI Control Plane", page_icon="🚀", layout="wide")


st.sidebar.title("🛠️ Infra Control Plane")
st.sidebar.markdown("Real-time Docker container status:")
def get_active_alerts_count():
    try:
        response = requests.get("http://localhost:9093/api/v2/alerts", timeout=2)
        if response.status_code == 200:
            alerts = response.json()
            return len(alerts)
        return 0
    except:
        return "N/A"

st.sidebar.markdown("---")
st.sidebar.title("🚨 Incident Management")
alert_count = get_active_alerts_count()

if alert_count == "N/A":
    st.sidebar.write("**Active Alerts:** ⚪ Connection Offline")
elif alert_count > 0:
    st.sidebar.write(f"**Active Alerts:** 🔴 {alert_count} Infrastructure Incidents")
else:
    st.sidebar.write("**Active Alerts:** 🟢 0 Active Alerts (System Healthy)")
    
def check_container_status():
    try:
        client = docker.from_env()
        
        target_containers = {
            "postgres-db": "PostgreSQL Database",
            "localstack-main": "LocalStack (AWS SQS)",
            "grafana": "Grafana Dashboards",
            "prometheus": "Prometheus Metrics",
            "loki": "Loki Log Aggregator",
            "liav-web-server": "Nginx Reverse Proxy"
        }
        
        status_dict = {}
        for container_name, display_name in target_containers.items():
            try:
                container = client.containers.get(container_name)
                if container.status == "running":
                    status_dict[display_name] = "🟢 Active"
                else:
                    status_dict[display_name] = f" Leadership Status: {container.status.upper()}"
            except docker.errors.NotFound:
                status_dict[display_name] = "🔴 Offline"
                
        return status_dict
    except Exception as e:
        st.sidebar.error("❌ Failed to communicate with Docker Daemon")
        return {}

statuses = check_container_status()
for name, status in statuses.items():
    st.sidebar.write(f"**{name}:** {status}")

st.sidebar.markdown("---")

if st.sidebar.button("🔄 Refresh System Status", use_container_width=True):
    st.rerun()



st.title("🚀 Central DevOps AI Agent Dashboard")
st.markdown("Unified control plane for managing shared context memory and underlying multi-container infrastructure.")

tab1, tab2 = st.tabs(["🧠 AI Context Memory", "📊 Observability & Metrics"])

with tab1:
    st.markdown("### 🧠 Shared Memory Logs (PostgreSQL backend)")
    st.markdown("This table contains the persistent context and synced codebase ingested by the AI Agent via n8n.")
    
    def get_db_data():
        try:
            conn = psycopg2.connect(
                host="localhost", port="5433", database="ai_memory",
                user=os.getenv("DB_USERNAME"), password=os.getenv("DB_PASSWORD")
            )
            query = "SELECT session_id, message, created_at FROM chat_messages ORDER BY created_at DESC;"
            df = pd.read_sql(query, conn)
            conn.close()
            return df
        except Exception as e:
            st.error(f"❌ Database Connection Error: {e}")
            return None

    btn_col1, btn_col2 = st.columns(2)
    
    with btn_col1:
        if st.button("🔄 Refresh Data Grid", use_container_width=True):
            st.rerun()
            
    with btn_col2:
        if st.button("⚡ Trigger Codebase Sync", use_container_width=True):
            with st.spinner("⏳ Dispatching sync script and updating vector/relational context..."):
                try:
                    result = subprocess.run(["python3", "bridge.py"], capture_output=True, text=True)
                    if result.returncode == 0:
                        st.success("✅ Sync completed successfully! Ingested data is now active.")
                        st.rerun()
                    else:
                        st.error(f"❌ Script Execution Failure:\n{result.stderr}")
                except Exception as e:
                    st.error(f"❌ Execution Error: {e}")

    st.markdown("---")

    df = get_db_data()
    if df is not None and not df.empty:
        st.dataframe(df, use_container_width=True)
    else:
        st.info("The relational knowledge-base is currently empty or no messages have been logged yet.")

with tab2:
    st.markdown("### 📊 Infrastructure Performance & Logs")
    st.markdown("Direct clean panel streams fetched from Prometheus metrics and Loki aggregators.")
    
    col1, col2 = st.columns(2)
    
    with col1:
        st.markdown("#### 📈 Compute Performance (Panel 1)")
        url_panel1 = "http://localhost:3030/d-solo/local-observability/local-observability?orgId=1&from=now-15m&to=now&timezone=browser&refresh=10s&panelId=panel-1"
        st.components.v1.iframe(url_panel1, height=350, scrolling=False)
        
    with col2:
        st.markdown("#### 📉 Memory & Traffic Load (Panel 2)")
        url_panel2 = "http://localhost:3030/d-solo/local-observability/local-observability?orgId=1&from=now-15m&to=now&timezone=browser&refresh=10s&panelId=panel-2"
        st.components.v1.iframe(url_panel2, height=350, scrolling=False)
        
    st.markdown("---")
    
    st.markdown("#### 📋 Real-Time Distributed System Logs (Loki Panel 3)")
    url_panel3 = "http://localhost:3030/d-solo/local-observability/local-observability?orgId=1&from=now-15m&to=now&timezone=browser&refresh=10s&panelId=panel-3"
    st.components.v1.iframe(url_panel3, height=400, scrolling=True)