
# Tesi: Eco Guardian

## Dependencies 🔗
None

## Tech Stack

![Cloud](https://img.shields.io/badge/Cloud-AWS-FF9900?logo=amazon-aws&style=for-the-badge)  
![IaaC](https://img.shields.io/badge/IaC-Terraform-8A2BE2?logo=terraform&style=for-the-badge)  



## Setup 🛠️

### Requirements

* Terraform 1.5.X (or higher)
* Terragrunt 0.54.X (or higher)

### Start Contributing
Just install the requirements and clone the repository, then you should be ready to contribute to the project.

## Deploy 🌍

### Deploy from local machine
It is possible to use Terragrunt to deploy the infrastructure from configuration on every environment. 
Please note that you will still need access to AWS Account you want to deploy the solution to.

Below the steps for deploying locally:

1. Open a terminal into the `infra/` folder
2. From the AWS SSO page, click on the account you want to deploy to, then click on `Access keys 🔑`
3. Copy the credentials and paste them in your terminal
4. Initialize terragrunt running:
```sh
terragrunt run-all init
```
1. If you are switching from another environment, this command may break due to your local cache, in this case run:
```sh
terragrunt run-all init --reconfigure
```
1. Apply the configuration from the IaC code
```sh
terragrunt run-all apply
```

### Deploy from CI
**TODO** *Steps to deploy the solution in each environment (if CI pipeline just specify where is it)*
