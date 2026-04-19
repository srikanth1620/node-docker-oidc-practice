# node-docker-oidc-practice new

Complete End-to-End Practice Run (Node.js Docker + OIDC + ACR + App Service)
Step 1: Create New Service Principal with OIDC

Go to Microsoft Entra ID → App registrations → + New registration
Name: github-oidc-node-docker-practice
Supported account types: Accounts in this organizational directory only
Click Register
Copy:
Application (Client) ID
Directory (Tenant) ID


Step 2: Add Federated Credential (OIDC)

Open the App Registration → Certificates & secrets → Federated credentials tab
Click + Add credential
Fill exactly:
Federated credential scenario: GitHub Actions deploying Azure resources
Organization: srikanth1620
Repository: node-docker-oidc-practice
Entity type: Branch
Branch name: main
Name: github-oidc-main
Description (optional): OIDC for GitHub Actions - node-docker-oidc-practice repo

Click Add

Step 3: Add GitHub Secrets (in the new repo)
In repo node-docker-oidc-practice → Settings → Secrets and variables → Actions → New repository secret:

AZURE_CLIENT_ID → Client ID from Step 1
AZURE_TENANT_ID → Tenant ID from Step 1
AZURE_SUBSCRIPTION_ID → Your Azure Subscription ID

Step 4: Assign Contributor Role at Subscription Level

Go to Subscriptions → Your subscription → Access control (IAM)
Click + Add → Add role assignment
Role: Contributor
Members: Select github-oidc-node-docker-practice
Review + assign

Step 5: Create New Resource Group

Name: node-docker-practice-rg
Region: Central US

Step 6: Create New ACR

Name: nodeoidcpracticeacr
Resource Group: node-docker-practice-rg
Region: Central US
SKU: Basic

Step 7: Assign AcrPush Role to SP on ACR

Go to ACR nodeoidcpracticeacr → Access control (IAM)
Click + Add → Add role assignment
Role: AcrPush
Members: Select github-oidc-node-docker-practice
Review + assign

Step 8: Create Dockerfile
Create Dockerfile in repo root:
dockerfileFROM node:18-alpine

WORKDIR /app

# Create a simple test file
RUN echo 'console.log("Hello from Node.js Docker demo using OIDC!");' > app.js

EXPOSE 8080

CMD ["node", "app.js"]
Step 9: Create/Update GitHub Workflow (deploy.yml)
Create .github/workflows/deploy.yml:
YAMLname: Deploy Node.js Docker App to Azure (Practice)

on:
  push:
    branches:
      - main
  workflow_dispatch:

permissions:
  contents: read
  id-token: write

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Login to Azure using OIDC
        uses: azure/login@v2
        with:
          client-id: ${{ secrets.AZURE_CLIENT_ID }}
          tenant-id: ${{ secrets.AZURE_TENANT_ID }}
          subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}

      - name: Login to ACR
        run: az acr login --name nodeoidcpracticeacr

      - name: Build and push Docker image
        uses: docker/build-push-action@v6
        with:
          context: .
          push: true
          tags: |
            nodeoidcpracticeacr.azurecr.io/node-docker-practice:${{ github.sha }}
            nodeoidcpracticeacr.azurecr.io/node-docker-practice:latest

      - name: Deploy to Azure App Service
        uses: azure/webapps-deploy@v3
        with:
          app-name: 'node-docker-practice-app'
          slot-name: 'Production'
          images: 'nodeoidcpracticeacr.azurecr.io/node-docker-practice:${{ github.sha }}'
Step 10: Create App Service

Name: node-docker-practice-app
Resource Group: node-docker-practice-rg
Publish: Docker Container
Operating System: Linux
App Service Plan: Use existing or new (S1 tier recommended)

Step 11: Enable Admin User on ACR & Configure Pull (Option 2)

Go to ACR nodeoidcpracticeacr → Access keys → Enable Admin user
Copy Username (nodeoidcpracticeacr) and one Password

Add to GitHub Secrets:

ACR_USERNAME = nodeoidcpracticeacr
ACR_PASSWORD = the long password

Then run this command:
Bashaz webapp config container set \
  --name node-docker-practice-app \
  --resource-group node-docker-practice-rg \
  --container-image-name nodeoidcpracticeacr.azurecr.io/node-docker-practice:latest \
  --container-registry-url https://nodeoidcpracticeacr.azurecr.io \
  --container-registry-user nodeoidcpracticeacr \
  --container-registry-password "YOUR_PASSWORD_HERE"
Step 12: Restart and Check Logs
Bashaz webapp restart \
  --name node-docker-practice-app \
  --resource-group node-docker-practice-rg

az webapp log tail \
  --name node-docker-practice-app \
  --resource-group node-docker-practice-rg
You should see the message:
Hello from Node.js Docker demo using OIDC!

Detailed Step-by-Step Summary

High-Level Flow

Create Service Principal with OIDC (passwordless)
Set up GitHub Secrets
Create Resource Group + ACR
Assign permissions
Create Dockerfile
Create GitHub Workflow
Create App Service
Configure App Service to pull image from ACR
Verify logs

Step 1: Create Service Principal with OIDC

Create App Registration (github-oidc-node-docker-practice)
Add Federated Credential (link GitHub repo + main branch)

Step 2: Add GitHub Secrets

AZURE_CLIENT_ID, AZURE_TENANT_ID, AZURE_SUBSCRIPTION_ID

Step 3: Create Infrastructure

New Resource Group (node-docker-practice-rg)
New ACR (nodeoidcpracticeacr)

Step 4: Assign Permissions

Contributor at Subscription level (for general access)
AcrPush on the ACR (for GitHub to push images)

Step 5: Dockerfile

Simple multi-stage or minimal Dockerfile

Step 6: GitHub Workflow

Uses OIDC login (azure/login@v2)
az acr login for push
Docker build & push
azure/webapps-deploy for deployment

Step 7: Create App Service

Name: node-docker-practice-app
Publish: Docker Container
Linux OS

Step 8: Configure Image Pull (Two Methods)
Method 1: Username/Password (Admin User)

Enable Admin User on ACR
Add ACR_USERNAME and ACR_PASSWORD in GitHub Secrets
Configure App Service with az webapp config container set
Key Point: When using admin username/password, AcrPull role is NOT required

Method 2: Managed Identity + AcrPull (OIDC way)

Enable System-assigned identity on App Service
Assign AcrPull role to that identity on the ACR
Key Point: When using Managed Identity, AcrPull role IS required


Key Points to Remember

OIDC = No client secret needed for GitHub → Azure authentication.
AcrPush = Needed for GitHub Actions to push images to ACR.
AcrPull = Needed for App Service to pull images from ACR only when using Managed Identity.
When using Admin Username/Password for pull → No AcrPull needed (simpler but less secure).
When using Managed Identity for pull → AcrPull is mandatory.
Always assign Contributor at subscription level first for the SP (to avoid "no subscriptions found" error).
Resource Group, ACR, and App Service should ideally be in the same region.
Never commit secrets in code or Dockerfile.