TF := terraform -chdir=terraform
VARS := -var-file=environments/prod/prod.tfvars

.PHONY: init fmt validate plan apply destroy deploy

init:
	$(TF) init -backend-config=environments/prod/backend.hcl

fmt:
	terraform fmt -recursive

validate:
	$(TF) validate

plan:
	$(TF) plan $(VARS)

apply:
	$(TF) apply $(VARS)

destroy:
	$(TF) destroy $(VARS)

# Deploys normally fire on their own (push to main, or a repository_dispatch
# from portfolio/ticker CI) — see README's Deploy flow. This is the manual
# trigger for the same workflow.
deploy:
	gh workflow run Deploy --repo AkashJam/infra
