SHELL := /bin/bash

LATEXMK ?= latexmk
LATEXMK_FLAGS := -xelatex -interaction=nonstopmode -halt-on-error -file-line-error
TEXINPUTS_ENV := $(CURDIR)/themes//:$(CURDIR)/shared-assets//:$(CURDIR)//:

DOCUMENTS := $(shell find templates practice -type f -name '*.tex' -exec grep -l '\\documentclass' {} + | sort)
PDFS := $(patsubst %.tex,build/%.pdf,$(DOCUMENTS))
THEME_FILES := $(shell find themes -type f -name '*.sty')
ASSET_FILES := $(shell find shared-assets practice -type f \( -name '*.png' -o -name '*.jpg' -o -name '*.jpeg' -o -name '*.pdf' \))

.PHONY: all build audit check release-check render list assets clean

all: build

build: $(PDFS)

list:
	@printf '%s\n' $(DOCUMENTS)

.SECONDEXPANSION:
build/%.pdf: %.tex $(THEME_FILES) $(ASSET_FILES) $$(wildcard $$(dir $$*)*.tex)
	@mkdir -p ".beamer-cache/$*" "$(dir $@)"
	@echo "[xelatex] $<"
	@TEXINPUTS="$(TEXINPUTS_ENV)" $(LATEXMK) $(LATEXMK_FLAGS) \
		-outdir=".beamer-cache/$*" "$<"
	@cp ".beamer-cache/$*/$(notdir $(basename $<)).pdf" "$@"
	@echo "  -> $@"

audit: build
	@./scripts/audit-pdf.sh $(PDFS)

release-check:
	@./scripts/check-release.sh

check: release-check build
	@set -euo pipefail; \
	pattern='Overfull|Missing character|LaTeX Error|LaTeX Font Warning|Package .* Warning|Class beamer Warning'; \
	failed=0; \
	while IFS= read -r log; do \
		if grep -En "$$pattern" "$$log"; then failed=1; fi; \
	done < <(find .beamer-cache -path .beamer-cache/assets -prune -o -type f -name '*.log' -print | sort); \
	if [[ $$failed -ne 0 ]]; then \
		echo 'NJU-Beamer check failed.' >&2; exit 1; \
	fi; \
	echo 'All NJU-Beamer documents compiled without overflow, missing glyphs, font warnings, or package warnings.'
	@./scripts/audit-pdf.sh $(PDFS)

render:
	@if [[ -z "$(INPUT)" ]]; then \
		echo 'Usage: make render INPUT=path/to/slides.tex [OUTPUT=/tmp/slides.pdf]' >&2; exit 2; \
	fi
	@set -euo pipefail; \
	input="$(INPUT)"; \
	rel="$${input%.tex}"; \
	build_dir=".beamer-cache/$$rel"; \
	output="$(OUTPUT)"; \
	if [[ -z "$$output" ]]; then output="build/$$rel.pdf"; fi; \
	mkdir -p "$$build_dir" "$$(dirname "$$output")"; \
	TEXINPUTS="$(TEXINPUTS_ENV)" $(LATEXMK) $(LATEXMK_FLAGS) -outdir="$$build_dir" "$$input"; \
	cp "$$build_dir/$$(basename "$$rel").pdf" "$$output"; \
	echo "$$output"

assets:
	@./scripts/build-assets.sh

clean:
	rm -rf .beamer-cache build
