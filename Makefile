SHELL := /bin/zsh

TF ?= terraform
COMPOSE ?= docker compose
KIND ?= kind
KUBECTL ?= kubectl

.PHONY: help kind-create kind-delete up down restart init validate lint plan apply apply-no-k8s apply-with-lock-table destroy outputs smoke k8s-forward

help:
	@echo "Available targets:"
	@echo "  kind-create           Create the local kind cluster from kind-config.yaml"
	@echo "  kind-delete           Delete the local kind cluster"
	@echo "  up                    Start Docker services"
	@echo "  down                  Stop Docker services"
	@echo "  restart               Recreate Docker services"
	@echo "  init                  Initialize Terraform"
	@echo "  validate              Run terraform fmt and terraform validate"
	@echo "  lint                  Run TFLint"
	@echo "  plan                  Run terraform plan"
	@echo "  apply                 Run terraform apply"
	@echo "  apply-no-k8s          Run terraform apply with Kubernetes disabled"
	@echo "  apply-with-lock-table Run terraform apply with the DynamoDB lock table enabled"
	@echo "  destroy               Run terraform destroy"
	@echo "  outputs               Print terraform outputs"
	@echo "  smoke                 Run local smoke tests"
	@echo "  k8s-forward           Port-forward the Kubernetes service to localhost:30080"

kind-create:
	$(KIND) create cluster --name liav-infra-cluster --config kind-config.yaml

kind-delete:
	$(KIND) delete cluster --name liav-infra-cluster

up:
	$(COMPOSE) up -d --remove-orphans

down:
	$(COMPOSE) down --remove-orphans

restart:
	$(COMPOSE) up -d --force-recreate --remove-orphans

init:
	$(TF) init -backend=false -reconfigure

validate:
	$(TF) fmt -check -recursive
	$(TF) validate

lint:
	tflint --init
	tflint --recursive

plan:
	$(TF) plan

apply:
	$(TF) apply

apply-no-k8s:
	$(TF) apply -var="enable_kubernetes=false"

apply-with-lock-table:
	$(TF) apply -var="enable_dynamodb_lock_table=true"

destroy:
	$(TF) destroy

outputs:
	$(TF) output

smoke:
	./scripts/smoke-test.sh

k8s-forward:
	$(KUBECTL) port-forward -n production-apps service/nginx-service 30080:80
