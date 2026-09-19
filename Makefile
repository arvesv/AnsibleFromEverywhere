.DEFAULT_GOAL := help
SHELL := /bin/bash
VENV ?= .venv
PYTHON ?= $(VENV)/bin/python
ANSIBLE_PLAYBOOK ?= $(VENV)/bin/ansible-playbook
ANSIBLE_LINT ?= $(VENV)/bin/ansible-lint
ANSIBLE_GALAXY ?= $(VENV)/bin/ansible-galaxy

.PHONY: help
help: ## Show this help message
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-18s\033[0m %s\n", $$1, $$2}'

.PHONY: venv
venv: ## Create Python virtual environment if not present
	@if [ ! -d "$(VENV)" ]; then python3 -m venv $(VENV); fi

.PHONY: install
install: venv ## Install Python dependencies and Ansible collections
	$(PYTHON) -m pip install --upgrade pip
	$(PYTHON) -m pip install -r requirements.txt
	$(ANSIBLE_GALAXY) collection install -r requirements.yml -p collections

.PHONY: init-inventory
init-inventory: ## Create inventory/hosts.yml from host.template if missing
	@if [ ! -f "inventory/hosts.yml" ]; then \
		cp host.template inventory/hosts.yml; \
		echo "Created inventory/hosts.yml from host.template"; \
	else \
		echo "inventory/hosts.yml already exists"; \
	fi

.PHONY: setup
setup: install init-inventory ## Full initial environment setup (venv, deps, inventory)

.PHONY: lint
lint: ## Run ansible-lint
	$(ANSIBLE_LINT)

.PHONY: syntax
syntax: ## Verify syntax of all playbooks
	$(ANSIBLE_PLAYBOOK) --syntax-check playbooks/hello-world.yml site.yml

.PHONY: hello
hello: ## Run the Hello World playbook
	$(ANSIBLE_PLAYBOOK) playbooks/hello-world.yml

.PHONY: site
site: ## Run the site.yml playbook
	$(ANSIBLE_PLAYBOOK) site.yml

.PHONY: docker-build
docker-build: ## Build the standalone Docker runner image
	docker build -t ansible-from-everywhere:latest .

.PHONY: docker-hello
docker-hello: ## Run hello-world playbook inside Docker container
	docker run --rm -v $$(pwd):/workspace ansible-from-everywhere:latest playbooks/hello-world.yml

.PHONY: clean
clean: ## Remove temporary cache and build artifacts
	rm -rf .ansible/ *.retry ansible.log __pycache__

