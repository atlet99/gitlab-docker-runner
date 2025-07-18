#!/bin/bash

# GitLab Runner Legacy Registration Debug Script
# This script provides detailed debugging information for legacy registration issues

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

echo -e "${BLUE}=== GitLab Runner Legacy Registration Debug ===${NC}"
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

# Check if container exists and get its state
echo -e "${BLUE}1. Container Analysis${NC}"
if docker ps -a --format "table {{.Names}}" | grep -q "^${CONTAINER_NAME}$"; then
    print_status "OK" "Container '${CONTAINER_NAME}' exists"
    
    # Get detailed container info
    CONTAINER_STATE=$(docker inspect --format='{{.State.Status}}' "${CONTAINER_NAME}")
    CONTAINER_EXIT_CODE=$(docker inspect --format='{{.State.ExitCode}}' "${CONTAINER_NAME}")
    CONTAINER_STARTED=$(docker inspect --format='{{.State.StartedAt}}' "${CONTAINER_NAME}")
    CONTAINER_FINISHED=$(docker inspect --format='{{.State.FinishedAt}}' "${CONTAINER_NAME}")
    
    echo -e "${BLUE}   Container State: ${CONTAINER_STATE}${NC}"
    echo -e "${BLUE}   Exit Code: ${CONTAINER_EXIT_CODE}${NC}"
    echo -e "${BLUE}   Started: ${CONTAINER_STARTED}${NC}"
    if [ "$CONTAINER_FINISHED" != "0001-01-01T00:00:00Z" ]; then
        echo -e "${BLUE}   Finished: ${CONTAINER_FINISHED}${NC}"
    fi
    
    if [ "$CONTAINER_STATE" = "running" ]; then
        print_status "OK" "Container is running"
    elif [ "$CONTAINER_STATE" = "exited" ]; then
        if [ "$CONTAINER_EXIT_CODE" = "0" ]; then
            print_status "OK" "Container exited successfully"
        else
            print_status "ERROR" "Container exited with code ${CONTAINER_EXIT_CODE}"
        fi
    else
        print_status "WARNING" "Container state: ${CONTAINER_STATE}"
    fi
else
    print_status "ERROR" "Container '${CONTAINER_NAME}' does not exist"
    exit 1
fi
echo

# Check container logs in detail
echo -e "${BLUE}2. Container Logs Analysis${NC}"
echo -e "${BLUE}   Full container logs:${NC}"
docker logs "${CONTAINER_NAME}" 2>&1 | sed 's/^/   /' || print_status "ERROR" "Failed to get container logs"
echo

# Check if config file exists and analyze it
echo -e "${BLUE}3. Configuration File Analysis${NC}"
if docker exec "${CONTAINER_NAME}" test -f "${CONFIG_FILE}" 2>/dev/null; then
    print_status "OK" "Configuration file exists"
    
    # Get file size and permissions
    FILE_SIZE=$(docker exec "${CONTAINER_NAME}" stat -c%s "${CONFIG_FILE}" 2>/dev/null || echo "unknown")
    FILE_PERMS=$(docker exec "${CONTAINER_NAME}" stat -c%a "${CONFIG_FILE}" 2>/dev/null || echo "unknown")
    echo -e "${BLUE}   File size: ${FILE_SIZE} bytes${NC}"
    echo -e "${BLUE}   File permissions: ${FILE_PERMS}${NC}"
    
    # Check if file is empty
    if [ "$FILE_SIZE" = "0" ]; then
        print_status "ERROR" "Configuration file is empty"
    else
        print_status "OK" "Configuration file has content"
    fi
    
    # Show file content
    echo -e "${BLUE}   Configuration content:${NC}"
    docker exec "${CONTAINER_NAME}" cat "${CONFIG_FILE}" 2>/dev/null | sed 's/^/   /' || print_status "ERROR" "Failed to read configuration file"
else
    print_status "ERROR" "Configuration file does not exist"
fi
echo

# Check for authentication token specifically
echo -e "${BLUE}4. Authentication Token Analysis${NC}"
if docker exec "${CONTAINER_NAME}" test -f "${CONFIG_FILE}" 2>/dev/null; then
    if docker exec "${CONTAINER_NAME}" grep -q "^  token = " "${CONFIG_FILE}" 2>/dev/null; then
        TOKEN_LINE=$(docker exec "${CONTAINER_NAME}" grep "^  token = " "${CONFIG_FILE}" 2>/dev/null)
        TOKEN_VALUE=$(echo "$TOKEN_LINE" | sed 's/^  token = "\(.*\)"$/\1/')
        
        if [ -n "$TOKEN_VALUE" ] && [ "$TOKEN_VALUE" != "" ]; then
            print_status "OK" "Authentication token is present"
            print_status "OK" "Token: ${TOKEN_VALUE:0:10}...${TOKEN_VALUE: -10}"
            
            # Check token format (should be a long alphanumeric string)
            if [[ "$TOKEN_VALUE" =~ ^[a-zA-Z0-9]{20,}$ ]]; then
                print_status "OK" "Token format appears valid"
            else
                print_status "WARNING" "Token format may be invalid"
            fi
        else
            print_status "ERROR" "Authentication token is empty"
        fi
    else
        print_status "ERROR" "Authentication token not found in configuration"
        print_status "WARNING" "This indicates the registration process failed"
        
        # Check for other tokens or registration attempts
        echo -e "${BLUE}   Checking for other token-related entries:${NC}"
        docker exec "${CONTAINER_NAME}" grep -i "token" "${CONFIG_FILE}" 2>/dev/null | sed 's/^/   /' || echo "   No token-related entries found"
    fi
else
    print_status "ERROR" "Cannot check token - configuration file not accessible"
fi
echo

# Check runner status and verification
echo -e "${BLUE}5. Runner Status Analysis${NC}"
if docker exec "${CONTAINER_NAME}" gitlab-runner list 2>/dev/null; then
    print_status "OK" "Runner is properly registered"
else
    print_status "ERROR" "Runner is not properly registered"
    echo -e "${YELLOW}   This usually means the registration process failed${NC}"
fi
echo

echo -e "${BLUE}6. Runner Verification${NC}"
if docker exec "${CONTAINER_NAME}" gitlab-runner verify 2>/dev/null; then
    print_status "OK" "Runner verification passed"
else
    print_status "ERROR" "Runner verification failed"
    echo -e "${YELLOW}   This indicates connectivity or configuration issues${NC}"
fi
echo

# Check network connectivity
echo -e "${BLUE}7. Network Connectivity Analysis${NC}"
# Extract URL from config
if docker exec "${CONTAINER_NAME}" grep -q "^  url = " "${CONFIG_FILE}" 2>/dev/null; then
    GITLAB_URL=$(docker exec "${CONTAINER_NAME}" grep "^  url = " "${CONFIG_FILE}" | sed 's/^  url = "\(.*\)"$/\1/')
    echo -e "${BLUE}   GitLab URL from config: ${GITLAB_URL}${NC}"
    
    # Test basic connectivity
    if docker exec "${CONTAINER_NAME}" curl -I "${GITLAB_URL}" --connect-timeout 10 --max-time 30 2>/dev/null | grep -q "HTTP/"; then
        print_status "OK" "GitLab URL is accessible"
        
        # Get HTTP response details
        HTTP_RESPONSE=$(docker exec "${CONTAINER_NAME}" curl -I "${GITLAB_URL}" --connect-timeout 10 --max-time 30 2>/dev/null | head -1)
        echo -e "${BLUE}   HTTP Response: ${HTTP_RESPONSE}${NC}"
    else
        print_status "ERROR" "GitLab URL is not accessible"
        
        # Try to get more details about the failure
        echo -e "${BLUE}   Testing with verbose output:${NC}"
        docker exec "${CONTAINER_NAME}" curl -v "${GITLAB_URL}" --connect-timeout 10 --max-time 30 2>&1 | sed 's/^/   /' || true
    fi
else
    print_status "WARNING" "Could not extract GitLab URL from configuration"
fi
echo

# Check Docker socket access
echo -e "${BLUE}8. Docker Integration Analysis${NC}"
if docker exec "${CONTAINER_NAME}" test -S /var/run/docker.sock; then
    print_status "OK" "Docker socket is accessible"
    
    # Test Docker API
    if docker exec "${CONTAINER_NAME}" docker version >/dev/null 2>&1; then
        print_status "OK" "Docker API is working"
        
        # Check Docker info
        echo -e "${BLUE}   Docker version:${NC}"
        docker exec "${CONTAINER_NAME}" docker version 2>/dev/null | sed 's/^/   /' || true
    else
        print_status "ERROR" "Docker API is not working"
    fi
else
    print_status "ERROR" "Docker socket is not accessible"
fi
echo

# Analyze registration process
echo -e "${BLUE}9. Registration Process Analysis${NC}"
if docker exec "${CONTAINER_NAME}" grep -q "^  token = " "${CONFIG_FILE}" 2>/dev/null; then
    print_status "OK" "Registration appears to be successful"
else
    print_status "ERROR" "Registration appears to have failed"
    
    # Check for common error patterns in logs
    echo -e "${BLUE}   Checking logs for common error patterns:${NC}"
    
    # Check for 400 Bad Request
    if docker logs "${CONTAINER_NAME}" 2>&1 | grep -i "400 bad request" >/dev/null; then
        print_status "ERROR" "Found 400 Bad Request error in logs"
        echo -e "${YELLOW}   This usually indicates invalid registration token or URL${NC}"
    fi
    
    # Check for network errors
    if docker logs "${CONTAINER_NAME}" 2>&1 | grep -i "connection refused\|timeout\|network" >/dev/null; then
        print_status "ERROR" "Found network-related errors in logs"
        echo -e "${YELLOW}   This indicates connectivity issues${NC}"
    fi
    
    # Check for SSL/TLS errors
    if docker logs "${CONTAINER_NAME}" 2>&1 | grep -i "ssl\|tls\|certificate" >/dev/null; then
        print_status "ERROR" "Found SSL/TLS-related errors in logs"
        echo -e "${YELLOW}   This indicates certificate issues${NC}"
    fi
    
    # Check for authentication errors
    if docker logs "${CONTAINER_NAME}" 2>&1 | grep -i "unauthorized\|forbidden\|401\|403" >/dev/null; then
        print_status "ERROR" "Found authentication errors in logs"
        echo -e "${YELLOW}   This indicates token or permission issues${NC}"
    fi
fi
echo

# Provide detailed recommendations
echo -e "${BLUE}10. Detailed Recommendations${NC}"
if docker exec "${CONTAINER_NAME}" grep -q "^  token = " "${CONFIG_FILE}" 2>/dev/null; then
    print_status "OK" "Runner is properly configured and should be working"
    echo -e "${GREEN}   Next steps:${NC}"
    echo -e "${GREEN}   - Check GitLab UI to verify runner is online${NC}"
    echo -e "${GREEN}   - Test with a simple CI/CD job${NC}"
    echo -e "${GREEN}   - Monitor runner logs for any issues${NC}"
else
    print_status "WARNING" "Runner needs attention"
    echo -e "${YELLOW}   Immediate actions:${NC}"
    echo -e "${YELLOW}   1. Verify registration token is valid and not expired${NC}"
    echo -e "${YELLOW}   2. Check GitLab URL is correct and accessible${NC}"
    echo -e "${YELLOW}   3. Ensure network connectivity to GitLab${NC}"
    echo -e "${YELLOW}   4. Check SSL/TLS certificates if using HTTPS${NC}"
    echo -e "${YELLOW}   5. Verify GitLab instance is running and accessible${NC}"
    echo -e "${YELLOW}   6. Check GitLab logs for registration errors${NC}"
    echo -e "${YELLOW}   7. Restart the registration process${NC}"
    echo
    echo -e "${YELLOW}   Debugging steps:${NC}"
    echo -e "${YELLOW}   1. Run: docker logs ${CONTAINER_NAME}${NC}"
    echo -e "${YELLOW}   2. Check GitLab admin logs for registration attempts${NC}"
    echo -e "${YELLOW}   3. Test connectivity manually: curl -I <gitlab-url>${NC}"
    echo -e "${YELLOW}   4. Verify token in GitLab admin interface${NC}"
fi
echo

echo -e "${BLUE}=== Debug Analysis Complete ===${NC}" 