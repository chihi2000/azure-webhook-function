# Azure Webhook Function

Automated CI/CD pipeline trigger system that bridges GitHub and Azure DevOps for infrastructure deployments.

## Overview

This Azure Function receives GitHub webhook events and automatically triggers an Azure DevOps pipeline to deploy Terraform infrastructure configurations. It provides a secure, serverless solution for GitOps-style infrastructure automation.



## Features

- **Secure Webhook Validation**: HMAC-SHA256 signature verification for all incoming webhooks
- **Azure Key Vault Integration**: Secrets managed securely using Managed Identity
- **Automated Pipeline Triggers**: Seamless integration with Azure DevOps REST API
- **Self-Hosted Agent Support**: Docker-based agent configuration included
- **Infrastructure as Code**: Terraform deployment automation

## Prerequisites

- Azure subscription with Function App
- Azure Key Vault with webhook secret stored
- Azure DevOps organization with pipeline configured
- GitHub repository with webhook configured
- Self-hosted Azure DevOps agent (optional, see `/scripts`)

## Environment Variables

Configure these in your Azure Function App settings:

```bash
AZDO_ORG_URL=https://dev.azure.com/your-org
AZDO_PROJECT_NAME=your-project
AZDO_PIPELINE_ID=your-pipeline-id
AZDO_PAT=your-personal-access-token
KEYVAULT_NAME=your-keyvault-name
WEBHOOK_SECRET_NAME=github-webhook-secret
```

## Setup

### 1. Deploy Azure Function
using portal or bash

### 2. Configure GitHub Webhook

- Go to your GitHub repository → Settings → Webhooks
- Payload URL: `https://<functionapp-name>.azurewebsites.net/api/Githubwebhook`
- Content type: `application/json`
- Secret: the webhook secret (must match Key Vault secret)
- Events: Push events

### 3. Self-Hosted Agent (Optional)

Configuration files are located in `/scripts`:

```bash
cd scripts
docker build -t azdo-agent .
docker run -d azdo-agent
```


## How It Works

1. Developer pushes code to GitHub main branch
2. GitHub sends webhook POST request with HMAC signature
3. Azure Function validates signature using secret from Key Vault
4. If valid, function triggers Azure DevOps pipeline via REST API
5. Self-hosted agent executes Terraform deployment
6. Infrastructure changes are applied to Azure




## Author 
M
