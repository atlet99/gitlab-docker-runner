#!/bin/bash

# GitLab Runner Legacy Registration Diagnostic Script
# This script helps diagnose issues with legacy registration method

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
CONTAINER_NAME="${1:-gitlab-runner}"
CONFIG_FILE="/etc/gitlab-runner/config.toml"

echo -e "${BLUE}=== GitLab Runner Legacy Registration Diagnostic ===${NC}"
echo

# Function to print status
print_status() {
    local status=$1
    local message=$2
    if [ "$status" = "OK" ]; then
        echo -e "${GREEN}✓${NC} $message"
    elif [ "$status" = "WARNING" ]; then
        echo -e "${YELLOW}⚠${NC} $message"
    else
        echo -e "${RED}✗${NC} $message"
    fi
}

# Check if container exists
echo -e "${BLUE}1. Container Status${NC}"
if docker ps -a --format "table {{.Names}}" | grep -q "^${CONTAINER_NAME}$"; then
    print_status "OK" "Container '${CONTAINER_NAME}' exists"
    
    # Check container state
    CONTAINER_STATE=$(docker inspect --format='{{.State.Status}}' "${CONTAINER_NAME}")
    if [ "$CONTAINER_STATE" = "running" ]; then
        print_status "OK" "Container is running"
    else
        print_status "WARNING" "Container is not running (state: ${CONTAINER_STATE})"
    fi
else
    print_status "ERROR" "Container '${CONTAINER_NAME}' does not exist"
    exit 1
fi
echo

# Check container logs
echo -e "${BLUE}2. Container Logs (last 20 lines)${NC}"
docker logs --tail 20 "${CONTAINER_NAME}" 2>&1 || print_status "ERROR" "Failed to get container logs"
echo

# Check if config file exists
echo -e "${BLUE}3. Configuration File${NC}"
if docker exec "${CONTAINER_NAME}" test -f "${CONFIG_FILE}"; then
    print_status "OK" "Configuration file exists"
    
    # Check config file content
    echo -e "${BLUE}   Configuration content:${NC}"
    docker exec "${CONTAINER_NAME}" cat "${CONFIG_FILE}" | sed 's/^/   /'
    echo
else
    print_status "ERROR" "Configuration file does not exist"
fi

# Check for authentication token
echo -e "${BLUE}4. Authentication Token Check${NC}"
if docker exec "${CONTAINER_NAME}" grep -q "^  token = " "${CONFIG_FILE}" 2>/dev/null; then
    TOKEN_LINE=$(docker exec "${CONTAINER_NAME}" grep "^  token = " "${CONFIG_FILE}")
    TOKEN_VALUE=$(echo "$TOKEN_LINE" | sed 's/^  token = "\(.*\)"$/\1/')
    if [ -n "$TOKEN_VALUE" ] && [ "$TOKEN_VALUE" != "" ]; then
        print_status "OK" "Authentication token is present"
        print_status "OK" "Token: ${TOKEN_VALUE:0:10}...${TOKEN_VALUE: -10}"
    else
        print_status "WARNING" "Authentication token is empty"
    fi
else
    print_status "ERROR" "Authentication token not found in configuration"
    print_status "WARNING" "This indicates the runner was not properly registered"
fi
echo

# Check runner status
echo -e "${BLUE}5. Runner Status${NC}"
if docker exec "${CONTAINER_NAME}" gitlab-runner list 2>/dev/null; then
    print_status "OK" "Runner is properly registered"
else
    print_status "ERROR" "Runner is not properly registered"
    echo -e "${YELLOW}   This usually means the registration process failed${NC}"
fi
echo

# Check runner verification
echo -e "${BLUE}6. Runner Verification${NC}"
if docker exec "${CONTAINER_NAME}" gitlab-runner verify 2>/dev/null; then
    print_status "OK" "Runner verification passed"
else
    print_status "ERROR" "Runner verification failed"
fi
echo

# Check network connectivity
echo -e "${BLUE}7. Network Connectivity${NC}"
# Extract URL from config
if docker exec "${CONTAINER_NAME}" grep -q "^  url = " "${CONFIG_FILE}" 2>/dev/null; then
    GITLAB_URL=$(docker exec "${CONTAINER_NAME}" grep "^  url = " "${CONFIG_FILE}" | sed 's/^  url = "\(.*\)"$/\1/')
    echo -e "${BLUE}   Testing connectivity to: ${GITLAB_URL}${NC}"
    
    if docker exec "${CONTAINER_NAME}" curl -I "${GITLAB_URL}" --connect-timeout 10 --max-time 30 2>/dev/null | grep -q "HTTP/"; then
        print_status "OK" "GitLab URL is accessible"
    else
        print_status "ERROR" "GitLab URL is not accessible"
    fi
else
    print_status "WARNING" "Could not extract GitLab URL from configuration"
fi
echo

# Check Docker socket access
echo -e "${BLUE}8. Docker Socket Access${NC}"
if docker exec "${CONTAINER_NAME}" test -S /var/run/docker.sock; then
    print_status "OK" "Docker socket is accessible"
    
    # Test Docker API
    if docker exec "${CONTAINER_NAME}" docker version >/dev/null 2>&1; then
        print_status "OK" "Docker API is working"
    else
        print_status "ERROR" "Docker API is not working"
    fi
else
    print_status "ERROR" "Docker socket is not accessible"
fi
echo

# Check registration process
echo -e "${BLUE}9. Registration Process Analysis${NC}"
if docker exec "${CONTAINER_NAME}" grep -q "^  token = " "${CONFIG_FILE}" 2>/dev/null; then
    print_status "OK" "Registration appears to be successful"
else
    print_status "ERROR" "Registration appears to have failed"
    echo -e "${YELLOW}   Common issues:${NC}"
    echo -e "${YELLOW}   - Invalid or expired registration token${NC}"
    echo -e "${YELLOW}   - Network connectivity issues${NC}"
    echo -e "${YELLOW}   - GitLab URL is incorrect${NC}"
    echo -e "${YELLOW}   - SSL/TLS certificate issues${NC}"
    echo -e "${YELLOW}   - GitLab instance is not accessible${NC}"
fi
echo

# Provide recommendations
echo -e "${BLUE}10. Recommendations${NC}"
if docker exec "${CONTAINER_NAME}" grep -q "^  token = " "${CONFIG_FILE}" 2>/dev/null; then
    print_status "OK" "Runner is properly configured and should be working"
    echo -e "${GREEN}   Next steps:${NC}"
    echo -e "${GREEN}   - Check GitLab UI to verify runner is online${NC}"
    echo -e "${GREEN}   - Test with a simple CI/CD job${NC}"
else
    print_status "WARNING" "Runner needs attention"
    echo -e "${YELLOW}   Recommended actions:${NC}"
    echo -e "${YELLOW}   1. Verify registration token is valid and not expired${NC}"
    echo -e "${YELLOW}   2. Check GitLab URL is correct and accessible${NC}"
    echo -e "${YELLOW}   3. Ensure network connectivity to GitLab${NC}"
    echo -e "${YELLOW}   4. Check SSL/TLS certificates if using HTTPS${NC}"
    echo -e "${YELLOW}   5. Restart the registration process${NC}"
    echo -e "${YELLOW}   6. Check GitLab logs for registration errors${NC}"
fi
echo

echo -e "${BLUE}=== Diagnostic Complete ===${NC}" 