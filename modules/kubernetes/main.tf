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
        # קונטקסט אבטחה ברמת הפוד - מניעת ריצה כ-Root והגבלת Capabilities
        security_context {
          run_as_non_root = true
          run_as_user     = 101
          fs_group        = 101
        }

        container {
          image = "nginx:1.25.3" # שימוש בגרסה קשיחה במקום latest
          name  = "nginx"

          port { container_port = 80 }

          # קונטקסט אבטחה ברמת הקונטיינר
          security_context {
            allow_privilege_escalation = false
            read_only_root_filesystem  = false # Nginx צריך לכתוב לקבצים זמניים מסוימים בריצה
            capabilities {
              drop = ["ALL"]
            }
          }

          # הגדרת משאבים קשיחה (חוסך נפילות זיכרון)
          resources {
            limits = {
              cpu    = "500m"
              memory = "512Mi"
            }
            requests = {
              cpu    = "250m"
              memory = "256Mi"
            }
          }

          # בדיקות תקינות וחיות של השרת
          liveness_probe {
            http_get {
              path = "/"
              port = 80
            }
            initial_delay_seconds = 15
            period_seconds        = 20
          }

          readiness_probe {
            http_get {
              path = "/"
              port = 80
            }
            initial_delay_seconds = 5
            period_seconds        = 10
          }

          volume_mount {
            name       = "config-volume"
            mount_path = "/etc/nginx/conf.d"
            read_only  = true
          }
        }

        container {
          name  = "nginx-exporter"
          image = "nginx/nginx-prometheus-exporter:1.0.0" # גרסה קשיחה
          args  = ["-nginx.scrape-uri", "http://localhost:80/stub_status"]
          port { container_port = 9113 }

          security_context {
            allow_privilege_escalation = false
            capabilities {
              drop = ["ALL"]
            }
          }

          resources {
            limits = {
              cpu    = "200m"
              memory = "256Mi"
            }
            requests = {
              cpu    = "100m"
              memory = "128Mi"
            }
          }
        }

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