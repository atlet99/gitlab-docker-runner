# Makefile for GitLab Docker Runner Ansible Role

.PHONY: help install test lint clean molecule-test molecule-converge molecule-destroy venv

# Default target
help:
	@echo "Available targets:"
	@echo "  venv           - Create virtual environment"
	@echo "  install        - Install development dependencies"
	@echo "  test           - Run all tests (lint + molecule)"
	@echo "  lint           - Run linting (ansible-lint + yamllint)"
	@echo "  molecule-test  - Run molecule tests"
	@echo "  molecule-converge - Run molecule converge only"
	@echo "  molecule-destroy - Clean up molecule instances"
	@echo "  clean          - Clean up temporary files"

# Create virtual environment
venv:
	python3 -m venv venv
	@echo "Virtual environment created. Activate it with: source venv/bin/activate"

# Install development dependencies
install:
	@if [ ! -d "venv" ]; then \
		echo "Virtual environment not found. Run 'make venv' first."; \
		exit 1; \
	fi
	. venv/bin/activate && pip install -r requirements-dev.txt
	. venv/bin/activate && ansible-galaxy collection install community.docker
	. venv/bin/activate && ansible-galaxy install geerlingguy.docker
	. venv/bin/activate && ansible-galaxy install -r requirements.yml

# Run all tests
test: lint molecule-test

# Run linting
lint:
	@if [ ! -d "venv" ]; then \
		echo "Virtual environment not found. Run 'make venv' first."; \
		exit 1; \
	fi
	. venv/bin/activate && ansible-lint
	. venv/bin/activate && yamllint .

# Run molecule tests
molecule-test:
	@if [ ! -d "venv" ]; then \
		echo "Virtual environment not found. Run 'make venv' first."; \
		exit 1; \
	fi
	. venv/bin/activate && molecule test

# Run molecule converge only
molecule-converge:
	@if [ ! -d "venv" ]; then \
		echo "Virtual environment not found. Run 'make venv' first."; \
		exit 1; \
	fi
	. venv/bin/activate && molecule converge

# Clean up molecule instances
molecule-destroy:
	@if [ ! -d "venv" ]; then \
		echo "Virtual environment not found. Run 'make venv' first."; \
		exit 1; \
	fi
	. venv/bin/activate && molecule destroy

# Clean up temporary files
clean:
	rm -rf venv
	rm -rf .pytest_cache/
	rm -rf .molecule/
	rm -rf .ansible/
	find . -type f -name "*.pyc" -delete
	find . -type d -name "__pycache__" -delete 