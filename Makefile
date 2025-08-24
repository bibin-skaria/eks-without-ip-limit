SHELL := /bin/bash

# Default environment
ENV ?= dev

# Validate environment parameter
VALID_ENVS := dev uat prod
ifeq ($(filter $(ENV),$(VALID_ENVS)),)
$(error Invalid environment: $(ENV). Valid environments: $(VALID_ENVS))
endif

.PHONY: help fmt validate init plan apply destroy clean docs all-fmt all-validate

# Default target
help:
	@echo "Available targets:"
	@echo "  fmt         - Format Terraform code for specified environment (default: dev)"
	@echo "  validate    - Validate Terraform syntax for specified environment"
	@echo "  init        - Initialize Terraform for specified environment"
	@echo "  plan        - Create execution plan for specified environment"
	@echo "  apply       - Apply changes for specified environment"
	@echo "  destroy     - Destroy infrastructure for specified environment"
	@echo "  clean       - Clean Terraform state and cache files for specified environment"
	@echo "  all-fmt     - Format all environments"
	@echo "  all-validate - Validate all environments"
	@echo ""
	@echo "Usage examples:"
	@echo "  make init ENV=dev"
	@echo "  make plan ENV=uat"
	@echo "  make apply ENV=prod"
	@echo "  make destroy ENV=dev"
	@echo ""
	@echo "Current environment: $(ENV)"

fmt:
	@echo "Formatting Terraform code for $(ENV) environment..."
	cd env/$(ENV) && terraform fmt
	@echo "Formatting all modules..."
	terraform fmt -recursive modules/

validate:
	@echo "Validating Terraform configuration for $(ENV) environment..."
	cd env/$(ENV) && terraform validate

init:
	@echo "Initializing Terraform for $(ENV) environment..."
	cd env/$(ENV) && terraform init

plan:
	@echo "Creating execution plan for $(ENV) environment..."
	cd env/$(ENV) && terraform plan -out=tfplan-$(ENV)

apply:
	@echo "Applying changes for $(ENV) environment..."
	cd env/$(ENV) && terraform apply tfplan-$(ENV)

destroy:
	@echo "WARNING: This will destroy all resources in $(ENV) environment!"
	@read -p "Are you sure? Type 'yes' to continue: " confirm && [ "$$confirm" = "yes" ]
	cd env/$(ENV) && terraform destroy

clean:
	@echo "Cleaning Terraform cache and state files for $(ENV) environment..."
	cd env/$(ENV) && rm -rf .terraform .terraform.lock.hcl tfplan-* terraform.tfstate.backup

all-fmt:
	@echo "Formatting all environments..."
	@for env in $(VALID_ENVS); do \
		echo "Formatting $$env..."; \
		cd env/$$env && terraform fmt; \
		cd ../..; \
	done
	@echo "Formatting all modules..."
	terraform fmt -recursive modules/

all-validate:
	@echo "Validating all environments..."
	@for env in $(VALID_ENVS); do \
		echo "Validating $$env..."; \
		cd env/$$env && terraform validate && echo "$$env: ✓ Valid" || echo "$$env: ✗ Invalid"; \
		cd ../..; \
	done
