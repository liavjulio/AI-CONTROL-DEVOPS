# modules/kubernetes/outputs.tf

output "namespace_name" {
  value = kubernetes_namespace.apps.metadata[0].name
}

output "service_name" {
  value = kubernetes_service.nginx_service.metadata[0].name
}