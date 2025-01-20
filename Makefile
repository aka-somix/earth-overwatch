COMMAND := $(filter init plan apply destroy,$(MAKECMDGOALS))
TARGET := $(firstword $(MAKECMDGOALS))
SUBTARGET := $(filter-out $(COMMAND) $(TARGET),$(MAKECMDGOALS))

# Declare valid commands as phony targets
.PHONY: help clean app mlpipe init plan apply destroy

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
	@echo ""
	@echo "Available commands:"
	@echo "  init    	- Run 'terragrunt run-all init' in the target"
	@echo "  plan    	- Run 'terragrunt run-all plan' in the target"
	@echo "  apply      - Run 'terragrunt run-all apply' in the target"
	@echo "  destroy    - Run 'terragrunt run-all destroy' in the target"

# Clean target
clean:
	./scripts/cleanup.sh

# App target
app:
	@if [ "$(COMMAND)" = "" ]; then \
		echo "Error: No command specified. Use 'init', 'plan', 'apply', or 'destroy'."; \
		exit 1; \
	elif [ "$(SUBTARGET)" = "" ]; then \
		echo "Running: terragrunt run-all $(COMMAND) in app/stacks"; \
		(cd app/stacks && terragrunt run-all $(COMMAND)); \
	else \
		echo "Running: terragrunt run-all $(COMMAND) in app/stacks/$(SUBTARGET)"; \
		(cd app/stacks/$(SUBTARGET) && terragrunt run-all $(COMMAND)); \
	fi

# MLPIPE target
mlpipe:
	@if [ "$(COMMAND)" = "" ]; then \
		echo "Error: No command specified. Use 'init', 'plan', 'apply', or 'destroy'."; \
		exit 1; \
	elif [ "$(SUBTARGET)" = "" ]; then \
		echo "Running: terragrunt run-all $(COMMAND) in mlpipe/stacks"; \
		(cd mlpipe/stacks && terragrunt run-all $(COMMAND)); \
	else \
		echo "Running: terragrunt run-all $(COMMAND) in mlpipe/stacks/$(SUBTARGET)"; \
		(cd mlpipe/stacks/$(SUBTARGET) && terragrunt run-all $(COMMAND)); \
	fi

# Prevent make from treating commands or subtargets as standalone targets
%:
	@true