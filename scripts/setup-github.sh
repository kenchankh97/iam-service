#!/bin/bash
# GitHub Repository Setup Script
# Run this after authenticating with: gh auth login

set -e

# Configuration
REPO_NAME="iam-service"
REPO_DESCRIPTION="Authentik IAM Service - Centralized Identity and Access Management"
VISIBILITY="private"  # Change to "public" if needed

echo "Creating GitHub repository: $REPO_NAME"

# Create repository on GitHub
gh repo create "$REPO_NAME" \
    --description "$REPO_DESCRIPTION" \
    --"$VISIBILITY" \
    --source=. \
    --remote=origin \
    --push

echo ""
echo "Repository created successfully!"
echo "URL: $(gh repo view --json url -q .url)"
echo ""
echo "Next steps:"
echo "1. Go to Railway (https://railway.app)"
echo "2. Create a new project"
echo "3. Add PostgreSQL service"
echo "4. Add Redis service"
echo "5. Deploy from GitHub: $REPO_NAME"
echo "6. Set environment variables in Railway"
