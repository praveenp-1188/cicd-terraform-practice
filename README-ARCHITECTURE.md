# 🏗️ CI/CD Pipeline Architecture Guide

## Overview

This practice project demonstrates a **complete CI/CD pipeline** with these components:

```
┌─────────────┐
│  Developer  │
└──────┬──────┘
       │
       ▼
┌──────────────────────┐
│   Git (GitHub)       │
│  ┌──────────────┐    │
│  │ main branch  │    │
│  │ feature/*    │    │
│  └──────────────┘    │
└──────┬───────────────┘
       │
       ▼
┌──────────────────────────┐
│  GitHub Actions (CI/CD)  │
│  ┌────────────────────┐  │
│  │ terraform-plan.yml │  │ (Runs on PR)
│  │ terraform-apply.yml│  │ (Runs on merge)
│  └────────────────────┘  │
└──────┬───────────────────┘
       │
       ▼
┌──────────────────────────┐
│  Azure Cloud Platform    │
│  ┌────────────────────┐  │
│  │ Static Web App     │  │ FREE
│  │ Resource Group     │  │ FREE
│  └────────────────────┘  │
└──────────────────────────┘
```

---

## Component Breakdown

### 1. **Git Repository (GitHub)**

#### Main Branch (`main`)
- **Purpose**: Production-ready code
- **Protected**: Cannot push directly
- **Requires**: PR + approval + test pass

#### Feature Branch (`feature/something`)
- **Purpose**: Development/testing
- **Created from**: `main`
- **Flow**: Create → Commit → Push → PR → Review → Merge

### 2. **Terraform (Infrastructure as Code)**

```
terraform/
├── main.tf          → Resource definitions
├── variables.tf     → Input variables
└── terraform.tfvars → Variable values
```

#### What Terraform Does:
1. **Define**: Infrastructure in code
2. **Plan**: Show what will change
3. **Apply**: Create/update resources
4. **Destroy**: Clean up when done

#### Key Concept: "Plan Before Apply"
```
Terraform Plan → Human Review → Terraform Apply
```

---

### 3. **GitHub Actions (CI/CD Automation)**

#### Workflow: `terraform-plan.yml` (Runs on PR)

```
Pull Request Created
        ↓
GitHub Actions Triggered
        ↓
1. Checkout code
2. Setup Terraform
3. Validate syntax
4. Run terraform plan
5. Post results as PR comment
        ↓
Developer Reviews Plan
```

**Example Output:**
```
✅ Added: 2 resources
- azurerm_resource_group
- azurerm_static_web_app
```

#### Workflow: `terraform-apply.yml` (Runs on Merge)

```
PR Merged to Main
        ↓
GitHub Actions Triggered
        ↓
Approval Gate (Production Environment)
        ↓
1. Checkout code
2. Terraform apply
3. Deploy application
4. Health check
        ↓
Resources Live in Azure
```

---

### 4. **Azure Resources**

#### Azure Static Web App (FREE)
- Hosts your HTML/JavaScript app
- Auto-assigns domain: `yourapp.azurestaticapps.net`
- Bandwidth: 100 GB/month free
- **Cost**: $0

#### Azure Resource Group
- Container for resources
- Organizes related resources
- **Cost**: $0 (free container)

---

## Workflow Examples

### Example 1: Adding New Content

```bash
# 1. Create feature branch
git checkout -b feature/add-about-page

# 2. Edit app
echo "<h2>About Us</h2>" >> app/index.html

# 3. Commit
git add app/index.html
git commit -m "feat: add about page section"

# 4. Push
git push -u origin feature/add-about-page

# 5. Create PR on GitHub
# → GitHub Actions runs terraform-plan
# → Shows: "0 changes (no infra modifications)"
# → Merge approved ✅

# 6. Merge to main
# → GitHub Actions runs terraform-apply
# → Deploys app changes to Static Web App
# → App live within 2-3 minutes 🎉
```

### Example 2: Changing Infrastructure

```bash
# 1. Create feature branch
git checkout -b feature/enable-logging

# 2. Edit Terraform
nano terraform/main.tf
# Add: Application Insights resource

# 3. Push to GitHub
git push origin feature/enable-logging

# 4. Create PR
# → GitHub Actions terraform-plan shows:
# → "Added: 1 resource (Application Insights)"

# 5. Review the plan
# → See what will be created
# → Verify it's free tier

# 6. Merge
# → terraform-apply runs
# → Application Insights created in Azure
# → Connected to Static Web App
```

---

## Key Concepts Explained

### 1. **Idempotency**

Running the same Terraform code multiple times produces the same result.

```
terraform apply (1st time) → Creates resources
terraform apply (2nd time) → No changes (resources exist)
terraform apply (3rd time) → No changes (idempotent)
```

### 2. **State Management**

Terraform tracks what exists in `terraform.tfstate` file.

```
Plan:
  What SHOULD exist: (from .tf files)
  What DOES exist: (from .tfstate)
  Difference: (what terraform-plan shows)
```

### 3. **Approval Gate**

GitHub "Environments" create a manual approval step.

```
Push to main → GitHub Actions waits
            ↓
      ⏳ Waiting for approval
            ↓
         You approve
            ↓
    GitHub Actions continues
            ↓
         Resources deployed
```

---

## File Purposes

| File | Purpose | When It Runs |
|------|---------|-------------|
| `terraform-plan.yml` | Validate Terraform changes | On every PR |
| `terraform-apply.yml` | Deploy to Azure | On merge to main |
| `main.tf` | Define Azure resources | When Terraform runs |
| `variables.tf` | Define variable inputs | When Terraform runs |
| `terraform.tfvars` | Provide variable values | When Terraform runs |
| `index.html` | Application content | When deployed |

---

## Branch Strategy (Feature Branch Workflow)

```
main (production) ← requires PR + approval
  ↑
  │ PR
  │
feature/feature-name (your work)

Rules:
1. Never commit directly to main
2. Always create PR from feature branch
3. Always get approval before merge
4. GitHub Actions validates before merge
```

---

## Cost Analysis

### What Costs Money (on Azure)?
❌ These would cost:
- Virtual Machines (any size)
- App Service Plans (paid tiers)
- Databases
- Premium services

### What's FREE?
✅ This project uses:
- Static Web App (free tier)
- Resource Groups
- GitHub Actions (free on public repos)

### Monthly Cost Breakdown
```
Static Web App:     $0.00
Resource Group:     $0.00
Storage (state):    ~$0.01 (negligible)
─────────────────────────
TOTAL:              ~$0.01/month
```

---

## Deployment Pipeline Timeline

```
Time:  Action:              Status:
──────────────────────────────────────────────────────────────
00:00  Create Feature Branch    🌱 Development starts
05:00  Git Commit             ✍️ Changes recorded
10:00  Git Push               📤 Code sent to GitHub
11:00  Create PR              📋 Review requested
12:00  GitHub Actions Plan    🤖 Terraform validates
15:00  PR Approval            ✅ Human reviews plan
20:00  Merge to Main          🔀 Changes integrated
21:00  GitHub Actions Apply   🚀 Deployment starts
22:00  Static Web App Updated 🌐 Live in Azure
23:00  Done!                  🎉 User can access
```

---

## Learning Progression

### Week 1: Basics
- [ ] Create repository
- [ ] Setup Terraform locally
- [ ] Create first feature branch
- [ ] Make PR and see terraform-plan
- [ ] Merge and see deployment

### Week 2: Understanding
- [ ] Read Terraform docs for `azurerm_static_web_app`
- [ ] Understand resource groups
- [ ] Learn what variables do
- [ ] Modify `terraform.tfvars`

### Week 3: Expanding
- [ ] Add a second resource (e.g., Application Insights)
- [ ] Create multi-environment setup (dev/prod)
- [ ] Add Terraform validation
- [ ] Add GitHub branch protection rules

### Week 4: Advanced
- [ ] Add automated tests
- [ ] Add cost estimation in PR
- [ ] Create rollback workflow
- [ ] Add monitoring/alerts

---

## Common Questions

### Q: Why use Terraform instead of manual Azure Portal?
A: 
- **Versioning**: Changes tracked in Git
- **Reproducibility**: Same code = same infrastructure
- **Automation**: Deploy without clicking 100 buttons
- **Collaboration**: Team members review changes before deployment

### Q: Why GitHub Actions?
A:
- **Free**: Unlimited public repo workflows
- **Native**: Integrates with GitHub
- **Simple**: YAML configuration
- **Secure**: Secrets management

### Q: Why use feature branches?
A:
- **Safety**: Doesn't affect production
- **Review**: Get feedback before deploying
- **Rollback**: Easy to cancel if needed
- **Testing**: Test changes before deploying

### Q: Can I break something?
A:
Yes, but recovery is easy:
```bash
# Delete everything
terraform destroy

# Or delete resource group in Azure Portal

# Redeploy by running terraform apply again
```

### Q: How do I see what's happening?
A:
1. **GitHub Actions**: Actions tab → View workflow logs
2. **Azure Portal**: View resource group and resources
3. **Terraform**: Run `terraform state list`

---

## Architecture Diagram (Detailed)

```
┌─────────────────────────────────────────────────────────────┐
│                        DEVELOPER LAPTOP                      │
│  ┌───────────────┐                                           │
│  │ Git Repository│  ← terraform/ + app/ + .github/workflows/ │
│  └───────────────┘                                           │
└────────────────────┬──────────────────────────────────────────┘
                     │
                     │ git push
                     ↓
        ┌─────────────────────────────┐
        │  GitHub (Remote Repository) │
        │  ┌───────────────────────┐  │
        │  │ main → protected      │  │
        │  │ feature/* → writable  │  │
        │  └───────────────────────┘  │
        └────┬─────────────────────────┘
             │
             │ Webhook trigger
             ↓
    ┌────────────────────────────┐
    │  GitHub Actions (CI/CD)     │
    │  ┌──────────────────────┐   │
    │  │ terraform-plan.yml   │   │ (PR workflow)
    │  │ Validates changes    │   │
    │  │ Posts results        │   │
    │  └──────────────────────┘   │
    │  ┌──────────────────────┐   │
    │  │ terraform-apply.yml  │   │ (Main workflow)
    │  │ Applies changes      │   │
    │  │ Deploys app          │   │
    │  └──────────────────────┘   │
    └────┬───────────────────────┘
         │
         │ API calls
         ↓
    ┌──────────────────────────────────┐
    │  Azure (Cloud Platform)          │
    │  ┌────────────────────────────┐  │
    │  │ Resource Group             │  │
    │  │ ├─ Static Web App          │  │
    │  │ │  └─ Your app files       │  │
    │  │ └─ Other resources         │  │
    │  │    └─ Application Insights │  │
    │  └────────────────────────────┘  │
    └──────────────────────────────────┘
         ↓
    ┌──────────────────────────────────┐
    │  User Accesses App               │
    │  myapp.azurestaticapps.net       │
    └──────────────────────────────────┘
```

---

## Summary

This pipeline demonstrates:
1. **Infrastructure as Code** → Terraform
2. **Version Control** → Git + GitHub
3. **Automated Testing** → GitHub Actions (terraform-plan)
4. **Gated Deployments** → PR approvals + environment gates
5. **Continuous Deployment** → Auto-deploy on merge
6. **Production Readiness** → Staging/approval before live

All with **zero cost** using Azure free tier! 🎉
