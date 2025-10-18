# Définir le shell à utiliser
SHELL := /bin/bash

# Couleurs pour l'output
BLUE := \033[0;34m
GREEN := \033[0;32m
YELLOW := \033[1;33m
RED := \033[0;31m
NC := \033[0m

# Répertoires importants
PROJECT_ROOT := $(shell pwd)
SCRIPTS_DIR := $(PROJECT_ROOT)/scripts
TESTS_DIR := $(PROJECT_ROOT)/tests
TEMPLATES_DIR := $(PROJECT_ROOT)/templates

# ============================================================================
# CIBLES PAR DÉFAUT
# ============================================================================

.DEFAULT_GOAL := help

.PHONY: help
help:
	@echo "$(BLUE)╔════════════════════════════════════════════════════╗$(NC)"
	@echo "$(BLUE)║  Instant Release - TDD Framework                  ║$(NC)"
	@echo "$(BLUE)╚════════════════════════════════════════════════════╝$(NC)"
	@echo ""
	@echo "$(YELLOW)📋 TESTS UNITAIRES (Bash, Local):$(NC)"
	@echo "  $(GREEN)make test-unit$(NC)              Run all unit tests"
	@echo "  $(GREEN)make test-unit-debug$(NC)        Run with debug output"
	@echo "  $(GREEN)make test-bump-type$(NC)         Run only bump type tests"
	@echo "  $(GREEN)make test-version$(NC)           Run only version tests"
	@echo "  $(GREEN)make test-changelog$(NC)         Run only changelog tests"
	@echo "  $(GREEN)make test-tag$(NC)               Run only tag tests"
	@echo ""
	@echo "$(YELLOW)🐳 TESTS D'INTÉGRATION (Docker):$(NC)"
	@echo "  $(GREEN)make docker-build$(NC)           Build Docker test image"
	@echo "  $(GREEN)make docker-test$(NC)            Run tests in Docker"
	@echo "  $(GREEN)make test-integration$(NC)       Build + Run in Docker"
	@echo ""
	@echo "$(YELLOW)🎯 SCÉNARIOS RAPIDES (No Docker):$(NC)"
	@echo "  $(GREEN)make scenario-simple$(NC)        Simple release workflow"
	@echo "  $(GREEN)make scenario-breaking$(NC)      Breaking changes release"
	@echo "  $(GREEN)make scenario-tag-conflict$(NC)  Tag conflict handling"
	@echo ""
	@echo "$(YELLOW)🔧 OUTILS & MAINTENANCE:$(NC)"
	@echo "  $(GREEN)make install-deps$(NC)           Install required tools"
	@echo "  $(GREEN)make lint$(NC)                   Lint bash scripts"
	@echo "  $(GREEN)make format$(NC)                 Format bash scripts"
	@echo "  $(GREEN)make clean$(NC)                  Clean temp files"
	@echo "  $(GREEN)make clean-docker$(NC)           Remove Docker image"
	@echo "  $(GREEN)make clean-all$(NC)              Full cleanup"
	@echo ""

# ============================================================================
# VARIABLES D'ENVIRONNEMENT
# ============================================================================

# Exporter pour que les scripts enfants les reçoivent
export PROJECT_ROOT
export SCRIPTS_DIR
export TESTS_DIR
export DEBUG ?= false
export DRY_RUN ?= false

# ============================================================================
# UNIT TESTS
# ============================================================================

.PHONY: test-unit test-unit-debug test-bump-type test-version test-changelog test-tag

test-unit:
	@echo "$(BLUE)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(NC)"
	@echo "$(BLUE)Running Unit Tests$(NC)"
	@echo "$(BLUE)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(NC)"
	@cd $(PROJECT_ROOT) && bash $(TESTS_DIR)/unit/run_all_tests.sh

test-unit-debug:
	@echo "$(BLUE)Running Unit Tests (Debug Mode)$(NC)"
	@cd $(PROJECT_ROOT) && DEBUG=true bash $(TESTS_DIR)/unit/run_all_tests.sh

test-bump-type:
	@echo "$(BLUE)Testing: Detect Bump Type$(NC)"
	@cd $(PROJECT_ROOT) && bash $(TESTS_DIR)/unit/versioning/test_detect_bump_type.sh

test-version:
	@echo "$(BLUE)Testing: Calculate Version$(NC)"
	@cd $(PROJECT_ROOT) && bash $(TESTS_DIR)/unit/versioning/test_calculate_version.sh

test-changelog:
	@echo "$(BLUE)Testing: Generate Changelog$(NC)"
	@cd $(PROJECT_ROOT) && bash $(TESTS_DIR)/unit/changelog/test_generate_changelog.sh

test-tag:
	@echo "$(BLUE)Testing: Create Tag$(NC)"
	@cd $(PROJECT_ROOT) && bash $(TESTS_DIR)/unit/release/test_create_tag.sh

# ============================================================================
# INTEGRATION TESTS
# ============================================================================

.PHONY: docker-build docker-test test-integration

docker-build:
	@echo "$(BLUE)Building Docker test image...$(NC)"
	@docker build -t instantrelease-test:latest $(TESTS_DIR)/integration/

docker-test: docker-build
	@echo "$(BLUE)Running integration tests in Docker...$(NC)"
	@docker run --rm \
		-v $(PROJECT_ROOT):/action \
		-e DEBUG=true \
		-e PROJECT_ROOT=/action \
		instantrelease-test:latest

test-integration: docker-build docker-test
	@echo "$(GREEN)✓ Integration tests complete$(NC)"

# ============================================================================
# QUICK SCENARIOS
# ============================================================================

.PHONY: scenario-simple scenario-breaking scenario-tag-conflict

scenario-simple:
	@echo "$(BLUE)Running Scenario: Simple Release$(NC)"
	@cd $(PROJECT_ROOT) && bash $(TESTS_DIR)/integration/scenarios/test_scenario_simple_release.sh

scenario-breaking:
	@echo "$(BLUE)Running Scenario: Breaking Changes$(NC)"
	@cd $(PROJECT_ROOT) && bash $(TESTS_DIR)/integration/scenarios/test_scenario_breaking_changes.sh

scenario-tag-conflict:
	@echo "$(BLUE)Running Scenario: Tag Conflicts$(NC)"
	@cd $(PROJECT_ROOT) && bash $(TESTS_DIR)/integration/scenarios/test_scenario_tag_conflicts.sh

# ============================================================================
# TOOLS & MAINTENANCE
# ============================================================================

.PHONY: install-deps lint format clean clean-docker clean-all

install-deps:
	@echo "$(BLUE)Installing dependencies...$(NC)"
	@command -v shellcheck >/dev/null 2>&1 || { echo "Installing shellcheck..."; apt-get update && apt-get install -y shellcheck; }
	@command -v shfmt >/dev/null 2>&1 || { echo "Installing shfmt..."; apt-get update && apt-get install -y shfmt; }
	@echo "$(GREEN)✓ Dependencies installed$(NC)"

lint:
	@echo "$(BLUE)Linting bash scripts...$(NC)"
	@for file in $$(find $(SCRIPTS_DIR) $(TESTS_DIR) -name "*.sh" -type f); do \
		echo "Checking: $$file"; \
		shellcheck -x "$$file" || true; \
	done
	@echo "$(GREEN)✓ Lint complete$(NC)"

format:
	@echo "$(BLUE)Formatting bash scripts...$(NC)"
	@find $(SCRIPTS_DIR) $(TESTS_DIR) -name "*.sh" -type f -exec shfmt -i 4 -w {} \;
	@echo "$(GREEN)✓ Format complete$(NC)"

clean:
	@echo "$(BLUE)Cleaning up temporary files...$(NC)"
	@rm -rf /tmp/test-repo-*
	@rm -f .audit.log
	@echo "$(GREEN)✓ Cleanup complete$(NC)"

clean-docker:
	@echo "$(BLUE)Removing Docker test image...$(NC)"
	@docker rmi instantrelease-test:latest 2>/dev/null || true
	@echo "$(GREEN)✓ Docker image removed$(NC)"

clean-all: clean clean-docker
	@echo "$(GREEN)✓ Full cleanup complete$(NC)"

# ============================================================================
# COMPOSITE TARGETS
# ============================================================================

.PHONY: test-all test-quick

test-quick: test-unit scenario-simple
	@echo "$(GREEN)✓ Quick tests complete$(NC)"

test-all: test-unit test-integration
	@echo "$(GREEN)✓ All tests complete$(NC)"