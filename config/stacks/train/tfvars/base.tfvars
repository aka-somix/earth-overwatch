stack_tags = {
    "stack" = "training1"
}

datasets_bucket = <%= output('storage.datasets_bucket', mock: {'id': 'mock', 'arn': 'mock'}) %>
