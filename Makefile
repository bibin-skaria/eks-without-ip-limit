SHELL := /bin/bash

.PHONY: fmt validate init plan apply destroy docs

fmt:
	terraform fmt -recursive

validate:
	terraform validate

init:
	cd env/dev && terraform init

plan:
	cd env/dev && terraform plan -out tfplan

apply:
	cd env/dev && terraform apply tfplan

destroy:
	cd env/dev && terraform destroy -auto-approve
