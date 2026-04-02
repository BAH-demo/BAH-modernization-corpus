# Analysis Engine Makefile

.PHONY: install analyze report clean help

PYTHON ?= python3
VENV_DIR ?= .venv
REPO_ROOT := $(shell cd .. && pwd)
CORPUS_DIR ?= $(REPO_ROOT)/modernization-corpus-aggregate
OUTPUT_DIR ?= $(REPO_ROOT)/corpus-analysis-results

help:
	@echo "Analysis Engine - Available targets:"
	@echo "  make install    - Install dependencies"
	@echo "  make analyze    - Run analysis on all cloned systems"
	@echo "  make report     - Generate markdown reports from analysis results"
	@echo "  make all        - Install, analyze, and generate reports"
	@echo "  make clean      - Remove analysis results"
	@echo ""
	@echo "Options:"
	@echo "  CORPUS_DIR=path  - Override corpus directory"
	@echo "  OUTPUT_DIR=path  - Override output directory"
	@echo "  SYSTEMS='sys1 sys2' - Analyze specific systems"

install:
	$(PYTHON) -m pip install -r requirements.txt

analyze:
	@echo "Running analysis engine..."
	cd $(REPO_ROOT) && $(PYTHON) -m analysis_engine.analyzer \
		--corpus-dir "$(CORPUS_DIR)" \
		--output-dir "$(OUTPUT_DIR)" \
		$(if $(SYSTEMS),--systems $(SYSTEMS),)

report:
	@echo "Generating markdown reports..."
	cd $(REPO_ROOT) && $(PYTHON) -m analysis_engine.report_generator \
		--input-dir "$(OUTPUT_DIR)" \
		--output-dir "$(OUTPUT_DIR)/reports"

all: install analyze report

clean:
	rm -rf $(OUTPUT_DIR)
	@echo "Cleaned analysis results."
