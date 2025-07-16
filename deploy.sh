#!/bin/bash

# =============================================================================
# N8N DEPLOYMENT SCRIPT WITH VERSION CHECKING
# =============================================================================
# This script provides interactive n8n version management and deployment.
# It checks the current version against the latest available version from
# Docker Hub and allows you to choose whether to upgrade before deploying.
#
# Usage: ./deploy.sh
# Prerequisites: curl, jq, terraform
# =============================================================================

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to get current version from n8n.tf
get_current_version() {
    grep -E 'container_image.*n8nio/n8n:' n8n.tf | sed -E 's/.*n8nio\/n8n:([^"]*).*/\1/'
}

# Function to get latest version from Docker Hub
get_latest_version() {
    curl -s "https://registry.hub.docker.com/v2/repositories/n8nio/n8n/tags/?page_size=100" | \
    jq -r '.results[] | select(.name | test("^[0-9]+\\.[0-9]+\\.[0-9]+$")) | .name' | \
    sort -V | tail -1
}

# Function to update version in n8n.tf
update_version() {
    local new_version=$1
    sed -i "s/container_image = \"n8nio\/n8n:[^\"]*\"/container_image = \"n8nio\/n8n:$new_version\"/" n8n.tf
}

echo -e "${GREEN}🔍 Checking n8n version...${NC}"

# Get current and latest versions
current_version=$(get_current_version)
latest_version=$(get_latest_version)

echo -e "Current version: ${YELLOW}$current_version${NC}"
echo -e "Latest version:  ${YELLOW}$latest_version${NC}"

# Check if update is available
if [ "$current_version" != "$latest_version" ]; then
    echo -e "${YELLOW}⚠️  A newer version is available!${NC}"
    echo -e "You are on version ${RED}$current_version${NC}, there's version ${GREEN}$latest_version${NC} available."
    echo ""
    echo "Do you want to:"
    echo "1) Stay with current version ($current_version)"
    echo "2) Upgrade to latest version ($latest_version)"
    echo "3) Cancel deployment"
    echo ""
    read -p "Enter your choice (1-3): " choice
    
    case $choice in
        1)
            echo -e "${GREEN}✅ Staying with current version $current_version${NC}"
            ;;
        2)
            echo -e "${GREEN}⬆️  Upgrading to version $latest_version${NC}"
            update_version "$latest_version"
            echo -e "${GREEN}✅ Updated n8n.tf to version $latest_version${NC}"
            ;;
        3)
            echo -e "${RED}❌ Deployment cancelled${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}❌ Invalid choice. Deployment cancelled${NC}"
            exit 1
            ;;
    esac
else
    echo -e "${GREEN}✅ You are already on the latest version!${NC}"
fi

echo ""
echo -e "${GREEN}🚀 Running terraform apply...${NC}"
terraform apply

echo ""
echo -e "${GREEN}✅ Deployment complete!${NC}"
echo -e "n8n URL: https://$(terraform output -raw cloudfront_domain)"