clean:
	./scripts/cleanup.sh

app-up:
	cd app/stacks && terragrunt run-all apply

mlpipe-up:
	cd mlpipe/stacks && terragrunt run-all apply
