# Earth Overwatch

![Cloud](https://img.shields.io/badge/Cloud-AWS-FF9900?logo=amazon-aws&style=for-the-badge)  
![IaaC](https://img.shields.io/badge/IaaC-Terraform-8A2BE2?logo=terraform&style=for-the-badge)

## Overview
Earth Overwatch is an infrastructure-as-code (IaC) project using Terraform and Terragrunt to manage cloud deployments. The repository contains Terraform configurations for various cloud components, organized into stacks.

## Features
- Modular Terraform setup with Terragrunt.
- Configuration management using YAML files.
- Infrastructure provisioning for cloud components like Bastion hosts and Landfills API.
- Automated deployment using Makefile commands.

## Applications and Stacks
The repository is divided into **applications** (top-level folders) and **stacks** (infrastructure components managed by Terragrunt).

### Applications:
- **app**: Main application infrastructure.
- **mlpipe**: Machine learning pipeline infrastructure.
- **scripts**: Utility scripts for automations and local experimentation.
- **web**: The frontend application for Earth Overwatch.

### Stacks:
- **app/stacks/bastion**: Manages the bastion host.
- **app/stacks/components/landfills**: Infrastructure for the Landfills API.
- **app/stacks/dataplatform/infrastructure**: Core infrastructure for the data platform.
- **app/stacks/dataplatform/ingestion/oam**: Ingestion pipeline for OAM data.
- **app/stacks/dataplatform/processing**: Processing components of the data platform.
- **app/stacks/events-broker**: Event-driven messaging infrastructure.
- **app/stacks/geo**: Geospatial processing and storage.
- **app/stacks/network**: Network infrastructure.
- **mlpipe/stacks/aimodels/landfill**: AI model for landfill detection.
- **mlpipe/stacks/aimodels/yologeneric**: YOLO-based AI model.
- **mlpipe/stacks/network**: Network resources for ML pipelines.
- **mlpipe/stacks/sagemaker**: AWS SageMaker resources.
- **mlpipe/stacks/storage**: Storage layer for ML data.
- **mlpipe/stacks/utils**: Utility stacks for ML infrastructure.

## Prerequisites
- Terraform
- Terragrunt
- AWS CLI (if deploying on AWS)
- Make (for automation)
- Node  >= 18
- Python >= 3.11


## Installation
1. Clone the repository:
   ```sh
   git clone <repository-url>
   cd earth-overwatch-main
   ```
2. Initialize Terraform:
   ```sh
   make app init
   make mlpipe init
   ```

## Usage

This project uses `make` to manage infrastructure, machine learning pipelines, and web application deployment. The following commands and targets are available:

### General Syntax
```
make <target> <subtarget> <command>
```
- **target**: Specifies the main category (`app`, `mlpipe`, or `web`).
- **subtarget** (optional): Specifies a subcomponent within the target.
- **command**: Defines the action to perform (`init`, `plan`, `up`, `down`, or `build`).

### Example Commands
#### App
- Initialize all app stacks:
  ```sh
  make app init
  ```
- Apply all app stacks:
  ```sh
  make app up
  ```
- Apply a specific app subtarget (e.g., `dataplatform` stack):
  ```sh
  make app dataplatform up
  ```
- Destroy all app stacks:
  ```sh
  make app down
  ```

#### ML Pipeline (mlpipe)
- Initialize all ML pipeline stacks:
  ```sh
  make mlpipe init
  ```
- Apply all ML pipeline stacks:
  ```sh
  make mlpipe up
  ```
- Destroy all ML pipeline stacks:
  ```sh
  make mlpipe down
  ```

#### Web Application
- Initialize the web application (install dependencies):
  ```sh
  make web init
  ```
- Start the web application in development mode:
  ```sh
  make web up
  ```
- Build the web application:
  ```sh
  make web build
  ```

### Available Commands
| Command | Description                                | Applicable Targets |
| ------- | ------------------------------------------ | ------------------ |
| `init`  | Initialize resources                       | app, mlpipe, web   |
| `plan`  | Plan resource changes                      | app, mlpipe        |
| `up`    | Apply resources                            | app, mlpipe, web   |
| `down`  | Destroy resources                          | app, mlpipe        |
| `build` | Build resources (only applicable to `web`) | web                |

### Cleaning Up
To clean up the environment, run:
```sh
make clean
```
This executes `./scripts/cleanup.sh`, which removes temporary files and resources.
