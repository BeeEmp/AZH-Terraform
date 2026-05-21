Markdown

# Azure Serverless Infrastructure

This repository contains the Infrastructure as Code (IaC) to deploy a fully serverless, scalable web application and database backend on Microsoft Azure using Terraform. 

## 🏗️ Architecture Overview

The infrastructure is modularized and provisions the following Azure resources:
* **Frontend Web Hosting:** Azure Storage Account configured for static website hosting (`index.html`).
* **Serverless Compute:** Azure Function App (Linux, Python 3.9) running on a dynamic Y1 Consumption Plan.
* **Database:** Azure Cosmos DB (SQL API) configured for global distribution with Session consistency.
* **Monitoring & Diagnostics:** Log Analytics Workspace and Application Insights integrated with the Function App.
* **Security (IAM):** System-assigned Managed Identity with Role-Based Access Control (RBAC) granting the Function App secure, passwordless access to Cosmos DB (`Cosmos DB Built-in Data Contributor`).

## 📂 Project Structure

```text
AZ104-Terraform/
├── frontend/                     # Static website assets
│   └── index.html                # Main portfolio landing page
├── backend/                      # Azure Function source code (Python)
├── terraform/                    # Root Terraform configuration
│   ├── .gitignore                # Security rules to ignore state files & plugins
│   ├── main.tf                   # Main resource group and module declarations
│   ├── variables.tf              # Global variables (e.g., location, unique_suffix)
│   ├── providers.tf              # Azure provider configurations
│   ├── outputs.tf                # Deployment outputs (URLs, endpoints)
│   └── modules/                  # Reusable infrastructure modules
│       ├── storage/              # Frontend static website storage module
│       │   ├── main.tf
│       │   └── variables.tf
│       └── serverless/           # Backend API, Database, and Monitoring module
│           ├── main.tf
│           └── variables.tf
└── README.md

🚀 Prerequisites

Before you begin, ensure you have the following installed and configured:

    Terraform (v1.0+)

    Azure CLI

    An active Azure Subscription

🛠️ Deployment Instructions

1. Authenticate with Azure

```bash
az login
terraform init
```

(Note: If you are using a university/tenant-specific account, you may need to append --tenant <YOUR_TENANT_ID> to the login command).

2. Initialize Terraform
Navigate to the terraform directory and download the required provider plugins:

```bash
terraform init
```

3. Preview the Infrastructure
Generate an execution plan to verify what resources will be created:

```bash
terraform plan
```

4. Deploy
Apply the configuration to provision the resources in Azure. Type yes when prompted.

```bash
terraform apply
```


5. Access Your Application
Once the deployment finishes, Terraform will output the primary endpoint for your frontend website and the Cosmos DB endpoint. Click the frontend URL to view the live site.
🔒 Security Notes

    State Files: Terraform state files (.tfstate and .tfstate.backup) contain sensitive access keys and are strictly ignored via .gitignore. Never commit these files to version control.

    Managed Identities: This project avoids hardcoded connection strings. The Azure Function securely communicates with Cosmos DB using Azure Entra ID (Managed Identities) via IAM role assignments.

    Provider Registration: If deploying on a restricted subscription (like Azure for Students), the providers.tf file is configured to skip automatic provider registration to prevent permission errors.

🧹 Clean Up

To avoid ongoing charges, destroy all resources when you are done:
Bash

```bash
terraform destroy
```
