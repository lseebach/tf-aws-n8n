#!/bin/bash

# =============================================================================
# N8N SCALING SCRIPT
# =============================================================================
# This script provides an interactive way to scale n8n ECS tasks up or down
# including hibernation mode (scale to 0) for cost savings.

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Function to show spinner animation
show_spinner() {
    local pid=$1
    local message=$2
    local spin='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    local i=0
    
    while kill -0 $pid 2>/dev/null; do
        printf "\r${BLUE}[INFO]${NC} $message ${spin:$i:1}"
        i=$(((i + 1) % ${#spin}))
        sleep 0.1
    done
    printf "\r${BLUE}[INFO]${NC} $message ✓\n"
}

# Function to get current desired count from terraform state
get_current_scale() {
    if [ ! -f "terraform.tfstate" ]; then
        print_warning "No terraform.tfstate found. This might be the first deployment."
        return 1
    fi
    
    # Try simple grep first (faster)
    local current_count=$(grep -o '"desired_count": [0-9]*' terraform.tfstate | head -1 | grep -o '[0-9]*' 2>/dev/null)
    
    # If grep fails, try terraform show with timeout
    if [ -z "$current_count" ]; then
        local temp_file=$(mktemp)
        
        {
            timeout 10 terraform show -json 2>/dev/null > "$temp_file"
            if [ $? -eq 0 ]; then
                current_count=$(jq -r '.values.root_module.child_modules[]? | select(.address == "module.n8n") | .resources[]? | select(.address == "module.n8n.aws_ecs_service.service") | .values.desired_count' "$temp_file" 2>/dev/null)
            fi
        } &
        
        local bg_pid=$!
        show_spinner $bg_pid "Analyzing terraform state"
        wait $bg_pid
        
        rm -f "$temp_file"
    fi
    
    if [ -z "$current_count" ] || [ "$current_count" = "null" ]; then
        print_warning "Could not determine current scale from terraform state"
        print_warning "You can still use this script to scale, but current status is unknown"
        return 1
    fi
    
    echo "$current_count"
}

# Function to get ECS service status
get_ecs_status() {
    local current_scale=$1
    
    if [ "$current_scale" -eq 0 ]; then
        echo -e "${YELLOW}HIBERNATING${NC} (0 tasks running)"
    elif [ "$current_scale" -eq 1 ]; then
        echo -e "${GREEN}ACTIVE${NC} (1 task running)"
    else
        echo -e "${GREEN}ACTIVE${NC} ($current_scale tasks running)"
    fi
}

# Function to estimate monthly costs
estimate_costs() {
    local scale=$1
    local base_cost=5  # EFS + RDS base cost
    local compute_cost_per_task=3  # Fargate Spot cost per task
    local total_cost=$((base_cost + (scale * compute_cost_per_task)))
    
    echo "~\$${total_cost}/month"
}

# Function to show current status
show_current_status() {
    echo
    echo "=========================================="
    echo "         N8N SCALING DASHBOARD"
    echo "=========================================="
    echo
    
    # Get current scale
    current_scale=$(get_current_scale)
    if [ $? -eq 0 ] && [ -n "$current_scale" ]; then
        print_status "Current Scale: $current_scale tasks"
        print_status "Status: $(get_ecs_status $current_scale)"
        print_status "Estimated Cost: $(estimate_costs $current_scale)"
    else
        print_warning "Unable to determine current scale"
        current_scale="unknown"
    fi
    
    echo
    echo "Cost Breakdown:"
    echo "  • 0 tasks: ~\$5/month  (EFS + RDS only)"
    echo "  • 1 task:  ~\$8/month  (+ Fargate Spot)"
    echo "  • 2 tasks: ~\$11/month (+ High Availability)"
    echo
    
    # Return the current scale value properly
    if [ "$current_scale" = "unknown" ]; then
        echo "$current_scale"
    else
        echo "$current_scale"
    fi
}

# Function to validate scale input
validate_scale() {
    local scale=$1
    
    if ! [[ "$scale" =~ ^[0-9]+$ ]]; then
        print_error "Scale must be a number"
        return 1
    fi
    
    if [ "$scale" -lt 0 ] || [ "$scale" -gt 10 ]; then
        print_error "Scale must be between 0 and 10"
        return 1
    fi
    
    return 0
}

# Function to apply scaling
apply_scaling() {
    local new_scale=$1
    local current_scale=$2
    
    if [ "$new_scale" -eq "$current_scale" ]; then
        print_warning "Already at desired scale ($new_scale)"
        return 0
    fi
    
    echo
    if [ "$new_scale" -eq 0 ]; then
        print_warning "Hibernating n8n (scaling to 0 tasks)"
        echo "  • All data will be preserved (EFS + RDS)"
        echo "  • n8n will be inaccessible until scaled back up"
        echo "  • Cost savings: ~$3/month"
    elif [ "$current_scale" -eq 0 ]; then
        print_status "Waking up n8n from hibernation"
        echo "  • All data will be restored"
        echo "  • n8n will be accessible in ~2-3 minutes"
    else
        print_status "Scaling from $current_scale to $new_scale tasks"
    fi
    
    echo
    read -p "Continue? (y/N): " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_status "Scaling cancelled"
        return 0
    fi
    
    echo
    print_status "Applying scaling to $new_scale tasks..."
    
    # Apply terraform with new desired_count and show progress
    {
        terraform apply -var="desired_count=$new_scale" -auto-approve
    } &
    
    local apply_pid=$!
    show_spinner $apply_pid "Updating AWS resources"
    wait $apply_pid
    local apply_result=$?
    
    if [ $apply_result -eq 0 ]; then
        print_success "Successfully scaled to $new_scale tasks"
        
        if [ "$new_scale" -eq 0 ]; then
            echo
            print_success "n8n is now hibernating"
            echo "  • Monthly cost reduced to ~$5 (EFS + RDS only)"
            echo "  • To wake up: ./scale.sh and choose scale > 0"
        elif [ "$current_scale" -eq 0 ]; then
            echo
            print_success "n8n is waking up from hibernation"
            echo "  • Wait 2-3 minutes for full availability"
            echo "  • Access via: terraform output n8n_url"
        fi
    else
        print_error "Failed to apply scaling"
        return 1
    fi
}

# Function to show scaling menu
show_scaling_menu() {
    local current_scale=$1
    
    echo "=========================================="
    echo "         SCALING OPTIONS"
    echo "=========================================="
    echo
    echo "Quick Options:"
    echo "  0) Hibernate (0 tasks) - Save costs"
    echo "  1) Standard (1 task)   - Normal operation"
    echo "  2) High-Availability (2 tasks) - Redundancy"
    echo
    echo "Custom scaling: Enter any number 0-10"
    echo
    echo "Tips:"
    echo "  • Use 0 for hibernation when not using n8n"
    echo "  • Use 1 for normal operation (recommended)"
    echo "  • Use 2+ for high availability (may cause webhook issues)"
    echo
    
    while true; do
        echo -n "Enter desired scale (0-10) or 'q' to quit: "
        read -r input
        
        if [ "$input" = "q" ] || [ "$input" = "quit" ]; then
            print_status "Goodbye!"
            exit 0
        fi
        
        if validate_scale "$input"; then
            apply_scaling "$input" "$current_scale"
            break
        fi
    done
}

# Main function
main() {
    # Check if terraform is available
    if ! command -v terraform &> /dev/null; then
        print_error "Terraform is not installed or not in PATH"
        exit 1
    fi
    
    # Check if we're in the right directory
    if [ ! -f "n8n.tf" ]; then
        print_error "This script must be run from the terraform directory containing n8n.tf"
        exit 1
    fi
    
    # Check if jq is available for JSON parsing
    if ! command -v jq &> /dev/null; then
        print_error "jq is required for this script. Please install it:"
        echo "  Ubuntu/Debian: sudo apt-get install jq"
        echo "  macOS: brew install jq"
        exit 1
    fi
    
    # Show current status and capture current scale
    current_scale=$(show_current_status)
    
    # Show scaling menu
    show_scaling_menu "$current_scale"
}

# Run main function
main "$@"