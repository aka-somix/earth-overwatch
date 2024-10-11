
# TERRAGRUNT PROJECT SCAFFOLD

**TODO** *A brief description of what this project does*

![Version Badge](https://img.shields.io/badge/version-UNRELEASED-green?logo=bitbucket) 


## Tech Stack

![Cloud](https://img.shields.io/badge/Cloud-AWS-FF9900?logo=amazon-aws&style=for-the-badge)  
![IaaC](https://img.shields.io/badge/IaaC-Terraform-8A2BE2?logo=terraform&style=for-the-badge)
![Service](https://img.shields.io/badge/CI-Bitbucket-0052CC?logo=bitbucket&style=for-the-badge)


## Installation 🛠️

### Requirements
**TODO** *Add here libraries and tools that needs to be installed in order to run locally*

* Terraform 1.5.X (or higher)
* Terragrunt 0.54.X (or higher)
* ...

### Start Contributing
**Remove if useless**  
**TODO** Add here instruction about the steps needed before start contributing the repository

#### Example (DELETE ME)
Install my-project with yarn

```bash
  cd my-project
  yarn
```

## Deploy 🌍
**TODO** *Steps to deploy the solution in each environment (if CI pipeline just specify where is it)*

### Deploy from local machine
It is possible to use Terragrunt to deploy the infrastructure from configuration on every environment. 
Please note that you will still need access to AWS Account you want to deploy the solution to.

Below the steps for deploying locally:

1. Fire up a terminal into the `live/` folder
2. From the AWS SSO page, click on the account you want to deploy to, then click on `Access keys 🔑`
3. Copy the credentials and paste them in your terminal
4. Export the environment variable, the list of available environments is available in the`live/_envs/` folder  
```sh
export ENV={env}
```
5. Initialize terragrunt running:
```sh
terragrunt run-all init
```
6. If you are switching from another environment, this command may break due to your local cache, in this case run:
```sh
terragrunt run-all init --reconfigure
```
7. Apply the configuration from the IaC code
```sh
terragrunt run-all apply
```