COMMAND := $(filter init plan up down build,$(MAKECMDGOALS))
TARGET := $(firstword $(MAKECMDGOALS))
SUBTARGET := $(filter-out $(COMMAND) $(TARGET),$(MAKECMDGOALS))

# Declare valid commands as phony targets
.PHONY: help clean app mlpipe web init plan up down build

# Default help target
help:
	@echo "Usage:"
	@echo "  make <target> <subtarget> <command>"
	@echo ""
	@echo "Examples:"
	@echo "  make app init         # Initialize all app stacks"
	@echo "  make app up           # Apply all app stacks"
	@echo "  make app dataplatform up  # Apply the dataplatform stack within app"
	@echo "  make mlpipe init      # Initialize all mlpipe stacks"
	@echo "  make web build        # Build the web application"
	@echo ""
	@echo "Available commands:"
	@echo "  init     - Initialize resources"
	@echo "  plan     - Plan resource changes"
	@echo "  up       - Apply resources"
	@echo "  down     - Destroy resources"
	@echo "  build    - Build resources (only applicable to 'web')"

# Clean target
clean:
	./scripts/cleanup.sh

# Translate commands for app and mlpipe
APP_MLPIPE_COMMAND := $(shell echo $(COMMAND) | sed -e 's/up/apply/' -e 's/down/destroy/')

# App target
app:
	@if [ "$(COMMAND)" = "" ]; then \
		echo "Error: No command specified. Use 'init', 'plan', 'up', 'down', or 'build'."; \
		exit 1; \
	elif [ "$(COMMAND)" = "build" ]; then \
		echo "Command 'build' does nothing for app."; \
	elif [ "$(SUBTARGET)" = "" ]; then \
		echo "Running: terragrunt run-all $(APP_MLPIPE_COMMAND) in app/stacks"; \
		(cd app/stacks && terragrunt run-all $(APP_MLPIPE_COMMAND)); \
	else \
		echo "Running: terragrunt run-all $(APP_MLPIPE_COMMAND) in app/stacks/$(SUBTARGET)"; \
		(cd app/stacks/$(SUBTARGET) && terragrunt run-all $(APP_MLPIPE_COMMAND)); \
	fi

# MLPIPE target
mlpipe:
	@if [ "$(COMMAND)" = "" ]; then \
		echo "Error: No command specified. Use 'init', 'plan', 'up', 'down', or 'build'."; \
		exit 1; \
	elif [ "$(COMMAND)" = "build" ]; then \
		echo "Command 'build' does nothing for mlpipe."; \
	elif [ "$(SUBTARGET)" = "" ]; then \
		echo "Running: terragrunt run-all $(APP_MLPIPE_COMMAND) in mlpipe/stacks"; \
		(cd mlpipe/stacks && terragrunt run-all $(APP_MLPIPE_COMMAND)); \
	else \
		echo "Running: terragrunt run-all $(APP_MLPIPE_COMMAND) in mlpipe/stacks/$(SUBTARGET)"; \
		(cd mlpipe/stacks/$(SUBTARGET) && terragrunt run-all $(APP_MLPIPE_COMMAND)); \
	fi

# Web target
web:
	@if [ "$(COMMAND)" = "" ]; then \
		echo "Error: No command specified. Use 'init', 'plan', 'up', 'down', or 'build'."; \
		exit 1; \
	elif [ "$(COMMAND)" = "init" ]; then \
		echo "Running: pnpm install in web"; \
		(cd web && pnpm install); \
	elif [ "$(COMMAND)" = "plan" ]; then \
		echo "Command 'plan' does nothing for web."; \
	elif [ "$(COMMAND)" = "up" ]; then \
		echo "Running: pnpm dev in web"; \
		(cd web && pnpm dev); \
	elif [ "$(COMMAND)" = "down" ]; then \
		echo "Command 'down' does nothing for web."; \
	elif [ "$(COMMAND)" = "build" ]; then \
		echo "Running: pnpm build in web"; \
		(cd web && pnpm build); \
	fi

# Prevent make from treating commands or subtargets as standalone targets
%:
	@true
