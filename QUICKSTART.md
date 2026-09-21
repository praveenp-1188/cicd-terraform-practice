# 🚀 Quick Start: CI/CD Pipeline with Terraform

## Prerequisites
- Azure subscription (with pay-as-you-go)
- GitHub account
- Azure CLI installed locally
- Terraform installed locally (v1.5+)

---

## Step 1: Azure Setup (One-Time)

### 1.1 Create Service Principal
```bash
# Login to Azure
az login

# Get your subscription ID
az account list --output table

# Create service principal (replace SUBSCRIPTION_ID)
az ad sp create-for-rbac \
  --name "github-terraform-sp" \
  --role Contributor \
  --scopes /subscriptions/YOUR_SUBSCRIPTION_ID
```

**Save the output!** You'll see:
```json
{
  "appId": "xxxxxxx",
  "displayName": "github-terraform-sp",
  "password": "xxxxxxx",
  "tenant": "xxxxxxx"
}
```

Map these to:
- `appId` → `AZURE_CLIENT_ID`
- `password` → `AZURE_CLIENT_SECRET`
- `tenant` → `AZURE_TENANT_ID`

### 1.2 Verify Permissions
```bash
# Test the service principal works
az login --service-principal \
  -u YOUR_CLIENT_ID \
  -p YOUR_CLIENT_SECRET \
  --tenant YOUR_TENANT_ID

# Should succeed and show your subscription
```

---

## Step 2: GitHub Repository Setup

### 2.1 Create Repository
1. Go to github.com → New Repository
2. Name it: `cicd-terraform-practice`
3. Initialize with README
4. Clone locally:
```bash
git clone https://github.com/YOUR_USERNAME/cicd-terraform-practice
cd cicd-terraform-practice
```

### 2.2 Create Directory Structure
```bash
# Create folders
mkdir -p terraform app .github/workflows

# Create main branch structure
touch terraform/main.tf
touch terraform/variables.tf
touch app/index.html
```

### 2.3 Add GitHub Secrets
1. Go to GitHub repo → Settings → Secrets and variables → Actions
2. Click "New repository secret" and add:

| Secret Name | Value |
|-------------|-------|
| `AZURE_CLIENT_ID` | appId from service principal |
| `AZURE_CLIENT_SECRET` | password from service principal |
| `AZURE_SUBSCRIPTION_ID` | Your subscription ID |
| `AZURE_TENANT_ID` | tenant from service principal |

---

## Step 3: Create Terraform Files

### 3.1 terraform/main.tf
Copy the provided `main.tf` file into `terraform/main.tf`

### 3.2 terraform/variables.tf
Copy the provided `variables.tf` file into `terraform/variables.tf`

### 3.3 terraform/terraform.tfvars
Create `terraform/terraform.tfvars`:
```hcl
resource_group_name = "cicd-practice-rg"
location             = "West Europe"
app_name             = "myapp-practice-12345"  # Must be globally unique!
environment          = "dev"
```

**Important**: Change `app_name` to something unique (e.g., add your username or timestamp)

---

## Step 4: Create GitHub Actions Workflows

### 4.1 .github/workflows/terraform-plan.yml
Copy the provided `terraform-plan.yml` file

### 4.2 .github/workflows/terraform-apply.yml
Copy the provided `terraform-apply.yml` file

### 4.3 Setup Production Environment
1. Go to GitHub repo → Settings → Environments
2. Click "New environment" → name it `production`
3. Under "Deployment branches", select "All branches"
4. Check "Required reviewers"
5. Add yourself as a reviewer

---

## Step 5: Create App Files

### 5.1 app/index.html
Copy the provided `index.html` file into `app/index.html`

### 5.2 app/staticwebapp.config.json (Optional)
Create for Static Web App configuration:
```json
{
  "routes": [
    {
      "route": "/*",
      "serve": "/index.html",
      "statusCode": 200
    }
  ],
  "navigationFallback": {
    "rewrite": "/index.html",
    "exclude": ["/images/*.{png,jpg,gif}", "/css/*"]
  }
}
```

---

## Step 6: Push to GitHub

```bash
# Add all files
git add .

# Commit
git commit -m "initial: setup terraform + github actions ci/cd pipeline"

# Push to main
git push origin main
```

---

## Step 7: Test the Pipeline

### 7.1 Create Feature Branch
```bash
git checkout -b feature/test-pipeline
```

### 7.2 Make a Small Change
Edit `app/index.html` - change something like the title or heading

### 7.3 Push and Create PR
```bash
git add app/index.html
git commit -m "feat: update app title"
git push -u origin feature/test-pipeline
```

Go to GitHub → Click "Compare & pull request"

### 7.4 Check Terraform Plan
- Wait for GitHub Actions to complete
- Review the plan in the PR comments
- Should show: `Added: 2 resources` (Resource Group + Static Web App)

### 7.5 Merge to Main
1. Click "Approve" (code review)
2. Click "Merge pull request"
3. Confirm merge

### 7.6 Approve Deployment
1. Go to Actions tab
2. Click the `terraform-apply` workflow
3. Click "Review deployments"
4. Select `production` environment
5. Click "Approve and deploy"
6. Watch the deployment complete!

### 7.7 Access Your App
1. Go back to PR/workflow run
2. Find the output URL (something like `https://myapp-practice-12345.azurestaticapps.net`)
3. Click it and see your deployed app! 🎉

---

## Common Errors & Fixes

### ❌ "appId is not a GUID"
**Cause**: You used the wrong service principal value
**Fix**: Double-check your AZURE_CLIENT_ID matches `appId` from the service principal output

### ❌ "Static Web App name already exists"
**Cause**: App name must be globally unique across Azure
**Fix**: Change `app_name` in `terraform.tfvars` to something unique with a random suffix

### ❌ "Error: Insufficient privileges"
**Cause**: Service principal doesn't have permissions
**Fix**: Re-run the role assignment:
```bash
az role assignment create \
  --assignee YOUR_CLIENT_ID \
  --role Contributor \
  --scope /subscriptions/YOUR_SUBSCRIPTION_ID
```

### ❌ "Resource already exists"
**Cause**: You ran Terraform multiple times and state isn't tracking properly
**Fix**: Delete the resource group in Azure Portal or:
```bash
az group delete --name cicd-practice-rg --yes
```

### ❌ "PR workflow didn't run"
**Cause**: Workflow file might not be recognized
**Fix**: 
- Check file paths are exactly: `.github/workflows/terraform-plan.yml`
- Commit and push the workflow files on main branch first
- Then create feature branch

---

## Cost Breakdown

| Resource | Free Tier | Monthly Cost |
|----------|-----------|--------------|
| Static Web App | Yes (100 GB bandwidth) | $0 |
| Resource Group | Free container | $0 |
| App Service Plan | Only 1 free per subscription | $0 |
| **Total** | | **~$0.00** |

✅ This setup costs nothing with free tier!

---

## Next Challenges (After You Get It Working)

1. **Add Environment Variables**: 
   - Create separate `dev` and `prod` environments
   - Deploy to different regions

2. **Add Validation**:
   - Run Terratest to test infrastructure
   - Add linting (tflint)

3. **Add Monitoring**:
   - Connect Application Insights
   - Set up alerts

4. **Auto-Rollback**:
   - Create a rollback workflow
   - Trigger on failed health checks

5. **Multi-Environment**:
   - Create `staging` branch that deploys to staging
   - Require all changes go through staging first

---

## Helpful Commands

```bash
# View Terraform plan
cd terraform
terraform plan

# Manually apply (after you understand it)
terraform apply

# View current state
terraform state list
terraform state show azurerm_static_web_app.main

# Destroy everything (careful!)
terraform destroy

# View resource group
az group list --output table
```

---

## Troubleshooting Checklist

- [ ] Azure service principal created and tested
- [ ] GitHub secrets added correctly (4 secrets)
- [ ] Repository structure correct (terraform/ and app/ folders)
- [ ] Workflow YAML files in `.github/workflows/`
- [ ] `app_name` in terraform.tfvars is globally unique
- [ ] Production environment configured in GitHub
- [ ] All files committed to main branch first
- [ ] Feature branch created from main
- [ ] No syntax errors in Terraform files (`terraform validate`)

---

## Success Criteria ✅

Your pipeline is working when:
1. Create PR → Terraform plan shows in comments
2. Merge PR → Requires approval ✅
3. Click approve → Deployment starts automatically
4. App URL becomes accessible with your content

**You did it! 🎉**
