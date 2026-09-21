# CI/CD Pipeline Practice: Terraform + GitHub Actions

## Architecture Overview
```
feature branch → PR → GitHub Actions Tests → Approval → Merge to main → Deploy to Azure
```

## Part 1: Repository Setup

### Directory Structure
```
your-repo/
├── .github/
│   └── workflows/
│       ├── terraform-plan.yml      (runs on feature branch)
│       └── terraform-apply.yml     (runs on main branch)
├── terraform/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── terraform.tfvars
├── app/
│   ├── index.html
│   └── package.json (if using Node.js)
└── README.md
```

## Part 2: Terraform Configuration (Free-Tier Resources)

### Option A: Azure Static Web Apps (BEST FOR FREE TIER)
- Completely free for basic usage
- Perfect for HTML/React/Vue apps
- No VM costs

### Option B: App Service (Linux Free Tier)
- 1 free App Service Plan per subscription
- Limited to 60 minutes/day
- Good for learning but has restrictions

---

## Part 3: Create Files

### 1. Terraform - main.tf
```hcl
terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
  
  # Store state in Azure Storage (free tier uses minimal storage)
  backend "azurerm" {
    resource_group_name  = "terraform-state-rg"
    storage_account_name = "YOUR_STORAGE_ACCOUNT_NAME"
    container_name       = "tfstate"
    key                  = "prod.tfstate"
  }
}

provider "azurerm" {
  features {}
  skip_provider_registration = false
}

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
  
  tags = {
    environment = var.environment
    project     = "cicd-practice"
  }
}

# Static Web App (FREE TIER)
resource "azurerm_static_web_app" "main" {
  name                = var.app_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku_tier            = "Free"
  sku_size            = "Free"
  
  tags = {
    environment = var.environment
  }
}

output "static_web_app_url" {
  value = azurerm_static_web_app.main.default_host_name
}

output "deployment_token" {
  value     = azurerm_static_web_app.main.api_key
  sensitive = true
}
```

### 2. Terraform - variables.tf
```hcl
variable "resource_group_name" {
  type        = string
  default     = "cicd-practice-rg"
  description = "Name of the resource group"
}

variable "location" {
  type        = string
  default     = "West Europe"
  description = "Azure region"
}

variable "app_name" {
  type        = string
  default     = "myapp-practice"
  description = "Name of the Static Web App (must be globally unique)"
}

variable "environment" {
  type        = string
  default     = "dev"
  description = "Environment name"
}
```

### 3. Terraform - outputs.tf
```hcl
output "resource_group_id" {
  value       = azurerm_resource_group.main.id
  description = "Resource Group ID"
}

output "app_name" {
  value       = azurerm_static_web_app.main.name
  description = "Static Web App Name"
}
```

### 4. App - app/index.html
```html
<!DOCTYPE html>
<html>
<head>
    <title>CI/CD Pipeline Practice</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            max-width: 800px;
            margin: 50px auto;
            padding: 20px;
        }
        .container {
            background: #f0f0f0;
            padding: 20px;
            border-radius: 8px;
        }
        .status {
            color: green;
            font-weight: bold;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🚀 CI/CD Pipeline Practice App</h1>
        <p class="status">✅ Deployment successful!</p>
        <p>This app was deployed via GitHub Actions + Terraform</p>
        <p>Environment: <strong>Production</strong></p>
        <p>Last updated: <span id="timestamp"></span></p>
    </div>
    <script>
        document.getElementById('timestamp').textContent = new Date().toLocaleString();
    </script>
</body>
</html>
```

---

## Part 4: GitHub Actions Workflows

### 1. Plan Workflow (terraform-plan.yml)
Runs on feature branch pull requests
```yaml
name: Terraform Plan

on:
  pull_request:
    paths:
      - 'terraform/**'
      - '.github/workflows/terraform-plan.yml'
    branches:
      - feature/*

permissions:
  pull-requests: write
  contents: read

jobs:
  plan:
    runs-on: ubuntu-latest
    
    env:
      ARM_CLIENT_ID: ${{ secrets.AZURE_CLIENT_ID }}
      ARM_CLIENT_SECRET: ${{ secrets.AZURE_CLIENT_SECRET }}
      ARM_SUBSCRIPTION_ID: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
      ARM_TENANT_ID: ${{ secrets.AZURE_TENANT_ID }}
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
      
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v2
        with:
          terraform_version: 1.5.0
      
      - name: Terraform Format Check
        run: terraform fmt -check -recursive
        working-directory: ./terraform
      
      - name: Terraform Init
        run: terraform init
        working-directory: ./terraform
      
      - name: Terraform Validate
        run: terraform validate
        working-directory: ./terraform
      
      - name: Terraform Plan
        run: terraform plan -out=tfplan
        working-directory: ./terraform
      
      - name: Comment Plan on PR
        uses: actions/github-script@v7
        with:
          script: |
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: '✅ **Terraform Plan Completed**\n\nReady for review and merge.'
            })
```

### 2. Apply Workflow (terraform-apply.yml)
Runs on main branch after merge (with approval)
```yaml
name: Terraform Apply

on:
  push:
    paths:
      - 'terraform/**'
      - 'app/**'
    branches:
      - main

permissions:
  contents: read
  id-token: write

jobs:
  apply:
    runs-on: ubuntu-latest
    environment: production  # Creates approval gate
    
    env:
      ARM_CLIENT_ID: ${{ secrets.AZURE_CLIENT_ID }}
      ARM_CLIENT_SECRET: ${{ secrets.AZURE_CLIENT_SECRET }}
      ARM_SUBSCRIPTION_ID: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
      ARM_TENANT_ID: ${{ secrets.AZURE_TENANT_ID }}
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
      
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v2
        with:
          terraform_version: 1.5.0
      
      - name: Terraform Init
        run: terraform init
        working-directory: ./terraform
      
      - name: Terraform Apply
        run: terraform apply -auto-approve
        working-directory: ./terraform
      
      - name: Get Deployment Outputs
        id: tf_output
        run: terraform output -json > outputs.json
        working-directory: ./terraform
      
      - name: Deploy App
        run: |
          echo "App deployed to: ${{ steps.tf_output.outputs.static_web_app_url }}"
```

---

## Part 5: GitHub Branch Protection Rules

In GitHub repo Settings → Branches → Add Rule:

1. **Branch name pattern**: `main`
2. ✅ **Require status checks to pass**: Select `terraform-plan`
3. ✅ **Require approval from code owners**: 1 approval
4. ✅ **Dismiss stale pull request approvals**
5. ✅ **Require conversation resolution**

---

## Part 6: Azure Setup (One-Time)

### Create Service Principal
```bash
az login

# Create service principal
az ad sp create-for-rbac \
  --name "github-cicd-sp" \
  --role Contributor \
  --scopes /subscriptions/YOUR_SUBSCRIPTION_ID

# Save the output (you'll use this for GitHub Secrets)
```

### Create State Storage (Optional but Recommended)
```bash
# Create resource group
az group create -n terraform-state-rg -l westeurope

# Create storage account
az storage account create \
  --name tfstate$(date +%s) \
  --resource-group terraform-state-rg \
  --location westeurope \
  --sku Standard_LRS

# Create container
az storage container create \
  -n tfstate \
  --account-name YOUR_STORAGE_ACCOUNT_NAME
```

---

## Part 7: GitHub Secrets Setup

In GitHub repo Settings → Secrets → New repository secret:

```
AZURE_CLIENT_ID         = (from service principal)
AZURE_CLIENT_SECRET     = (from service principal)
AZURE_SUBSCRIPTION_ID   = (your subscription ID)
AZURE_TENANT_ID         = (from service principal)
```

---

## Workflow: Making Changes

### Step 1: Create Feature Branch
```bash
git checkout -b feature/add-new-section
# Make changes to app or terraform
git add .
git commit -m "feat: add new section to homepage"
git push -u origin feature/add-new-section
```

### Step 2: Create Pull Request
- Push to GitHub
- GitHub Actions runs `terraform-plan`
- Review the plan output in PR

### Step 3: Approval & Merge
- Get code review approval
- Merge to main (1 approval required)

### Step 4: Automatic Deploy
- Merge triggers `terraform-apply`
- Requires `environment: production` approval (set in GitHub)
- Infrastructure updates
- App deploys

---

## Cost Breakdown (Monthly)
- Static Web App (Free tier): **$0**
- Storage Account (state): ~**$0.50** (minimal)
- Resource Group: **$0**
- **Total: ~$0.50/month**

---

## Common Issues & Fixes

### Issue: Terraform state lock
```bash
# Force unlock if needed
terraform force-unlock LOCK_ID
```

### Issue: App name not globally unique
- Azure Static Web App names must be globally unique
- Use: `myapp-$(date +%s)` in variables

### Issue: Service Principal permission denied
```bash
# Grant additional permissions
az role assignment create \
  --assignee PRINCIPAL_ID \
  --role "Storage Blob Data Contributor" \
  --scope /subscriptions/SUBSCRIPTION_ID
```

---

## Next Steps to Practice
1. Add a `dev` environment branch
2. Add infrastructure tests (Terratest)
3. Add application tests in the pipeline
4. Implement automated rollback on failure
5. Add Terraform cost estimation in PR comments
