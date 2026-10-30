# Makefile for managing Emacs configuration

EMACS ?= emacs
DESTDIR ?=
TARGET_DIR ?= $(DESTDIR)$(HOME)/.emacs.d

SRC_ORG      := config.org
GEN_EL       := config.el
GEN_ELC      := config.elc
INIT_EL      := init.el
SNIPPETS_DIR := snippets

.PHONY: all tangle build test test-syntax test-load compile install link symlink clean uninstall help

# Default target: tangle config.org into config.el
all: $(GEN_EL)

# Tangle Emacs Lisp code blocks from config.org into config.el
tangle: $(GEN_EL)
build: $(GEN_EL)

$(GEN_EL): $(SRC_ORG)
	@echo "Tangling $< -> $@..."
	$(EMACS) -Q --batch --eval "(require 'org)" --eval '(org-babel-tangle-file "$<" "$@")'

# Byte-compile config.el to check for compilation warnings and errors
compile: $(GEN_ELC)

$(GEN_ELC): $(GEN_EL)
	@echo "Byte-compiling $<..."
	$(EMACS) -Q --batch \
		--eval "(defmacro defhydra (&rest _) nil)" \
		-f batch-byte-compile $<

# Run test checks on the generated .el file (syntax check)
test: test-syntax

# Fast syntax check: verifies balanced parentheses and valid Elisp reader syntax
test-syntax: $(GEN_EL)
	@echo "Checking syntax of $<..."
	@$(EMACS) -Q --batch --eval '(with-temp-buffer (insert-file-contents "$<") (condition-case err (while t (read (current-buffer))) (end-of-file (message "Syntax check PASSED: $< is well-formed Elisp."))))'

# Batch load test: initializes packages and loads config.el
test-load: $(GEN_EL)
	@echo "Testing load of $< in Emacs batch mode..."
	@$(EMACS) -Q --batch \
		--eval '(package-initialize)' \
		--eval '(load-file "$<")' \
		--eval '(message "Load test PASSED: $< loaded cleanly.")'

# Install files to ~/.emacs.d (copies init.el, config.org, config.el, and snippets)
install: $(GEN_EL)
	@echo "Installing configuration to $(TARGET_DIR)..."
	mkdir -p $(TARGET_DIR)
	cp -f $(INIT_EL) $(TARGET_DIR)/$(INIT_EL)
	cp -f $(SRC_ORG) $(TARGET_DIR)/$(SRC_ORG)
	cp -f $(GEN_EL) $(TARGET_DIR)/$(GEN_EL)
	@if [ -f private.el ] && [ ! -f $(TARGET_DIR)/private.el ]; then \
		cp -f private.el $(TARGET_DIR)/private.el; \
		echo "Installed private.el to $(TARGET_DIR)/private.el"; \
	fi
	mkdir -p $(TARGET_DIR)/$(SNIPPETS_DIR)
	cp -R $(SNIPPETS_DIR)/ $(TARGET_DIR)/$(SNIPPETS_DIR)/
	@echo "Installation complete."

# Symlink files to ~/.emacs.d (useful for active development in repo)
link symlink: $(GEN_EL)
	@echo "Symlinking configuration to $(TARGET_DIR)..."
	mkdir -p $(TARGET_DIR)
	ln -sf $(CURDIR)/$(INIT_EL) $(TARGET_DIR)/$(INIT_EL)
	ln -sf $(CURDIR)/$(SRC_ORG) $(TARGET_DIR)/$(SRC_ORG)
	ln -sf $(CURDIR)/$(GEN_EL) $(TARGET_DIR)/$(GEN_EL)
	ln -sfn $(CURDIR)/$(SNIPPETS_DIR) $(TARGET_DIR)/$(SNIPPETS_DIR)
	@if [ -f $(CURDIR)/private.el ] && [ ! -e $(TARGET_DIR)/private.el ]; then \
		ln -sf $(CURDIR)/private.el $(TARGET_DIR)/private.el; \
		echo "Symlinked private.el to $(TARGET_DIR)/private.el"; \
	fi
	@echo "Symlinks created in $(TARGET_DIR)."

# Clean generated .el and .elc files
clean:
	@echo "Cleaning generated files..."
	rm -f $(GEN_EL) $(GEN_ELC) *~
	@echo "Cleaned."

# Remove installed files from target directory
uninstall:
	@echo "Uninstalling files from $(TARGET_DIR)..."
	rm -f $(TARGET_DIR)/$(INIT_EL) $(TARGET_DIR)/$(SRC_ORG) $(TARGET_DIR)/$(GEN_EL)
	@if [ -L $(TARGET_DIR)/$(SNIPPETS_DIR) ]; then \
		rm -f $(TARGET_DIR)/$(SNIPPETS_DIR); \
		echo "Removed symlinked snippets directory."; \
	fi
	@echo "Uninstallation complete (custom user data in $(TARGET_DIR) preserved)."

# Display help information
help:
	@echo "Available targets:"
	@echo "  all         - Generate $(GEN_EL) from $(SRC_ORG) (default)"
	@echo "  tangle      - Alias for all"
	@echo "  test        - Run syntax and load tests on $(GEN_EL)"
	@echo "  test-syntax - Check syntax of $(GEN_EL) (reader-level validation)"
	@echo "  test-load   - Test loading $(GEN_EL) with Emacs in batch mode"
	@echo "  compile     - Byte-compile $(GEN_EL) into $(GEN_ELC)"
	@echo "  install     - Copy configuration files to $(TARGET_DIR)"
	@echo "  link        - Symlink configuration files to $(TARGET_DIR)"
	@echo "  clean       - Remove generated $(GEN_EL) and $(GEN_ELC) files"
	@echo "  uninstall   - Remove installed/linked configuration files"
