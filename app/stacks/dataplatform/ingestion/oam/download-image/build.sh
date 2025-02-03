#!/bin/bash

echo "📦 Building Python Environment directly in Lambda function"

pip install -r requirements.txt -t ./src/.ext --platform manylinux2014_x86_64 --implementation cp --only-binary=:all: --upgrade

echo "✅ Python packages built"
