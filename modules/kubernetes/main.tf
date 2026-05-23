terraform {
  required_version = ">= 1.6.6"
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0.0"
    }
  }
}

resource "kubernetes_namespace" "apps" {
  metadata {
    name = "production-apps"
  }
}

resource "kubernetes_deployment" "nginx" {
  metadata {
    name      = "liav-web-server"
    namespace = kubernetes_namespace.apps.metadata[0].name
  }
  spec {
    replicas = 2
    selector {
      match_labels = { app = "nginx" }
    }
    template {
      metadata {
        labels = { app = "nginx" }
      }
      spec {
        container {
          image = "nginx:latest"
          name  = "nginx"
          port { container_port = 80 }

          # קישור הקונפיגורציה לתוך ה-Container של Nginx
          volume_mount {
            name       = "config-volume"
            mount_path = "/etc/nginx/conf.d"
            read_only  = true
          }
        }

        container {
          name  = "nginx-exporter"
          image = "nginx/nginx-prometheus-exporter:latest"
          args  = ["-nginx.scrape-uri", "http://localhost:80/stub_status"]
          port { container_port = 9113 }
        }

        # הגדרת ה-Volume שמושך את הנתונים מה-ConfigMap
        volume {
          name = "config-volume"
          config_map {
            name = kubernetes_config_map.nginx_config.metadata[0].name
          }
        }
      }
    }
  }
}
resource "kubernetes_config_map" "nginx_config" {
  metadata {
    name      = "nginx-config"
    namespace = "production-apps"
  }

  data = {
    "default.conf" = <<EOF
server {
    listen 80;
    server_name localhost;

    location / {
        root   /usr/share/nginx/html;
        index  index.html index.htm;
    }

    location /stub_status {
        stub_status on;
        access_log off;
        allow 127.0.0.1;
        deny all;
    }
}
EOF
  }
}
resource "kubernetes_service" "nginx_service" {
  metadata {
    name      = "nginx-service"
    namespace = kubernetes_namespace.apps.metadata[0].name
  }
  spec {
    selector = { app = "nginx" }
    port {
      name        = "http"
      port        = 80
      target_port = 80
    }
    port {
      name        = "metrics"
      port        = 9113
      target_port = 9113
      node_port   = 30081
    }
    type = "NodePort"
  }
}