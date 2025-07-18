#!/bin/bash

# GitLab Runner Diagnostic Script
# This script helps diagnose common issues with GitLab Runner

set -e

CONTAINER_NAME="${1:-gitlab-runner}"
RUNNER_DIR="${2:-/var/lib/gitlab-runner}"

echo "=== GitLab Runner Diagnostic Script ==="
echo "Container: $CONTAINER_NAME"
echo "Runner directory: $RUNNER_DIR"
echo ""

# Check if container exists and is running
echo "1. Checking container status..."
if docker ps | grep -q "$CONTAINER_NAME"; then
    echo "✓ Container $CONTAINER_NAME is running"
    CONTAINER_STATUS=$(docker inspect --format='{{.State.Status}}' "$CONTAINER_NAME")
    echo "  Status: $CONTAINER_STATUS"
else
    echo "✗ Container $CONTAINER_NAME is not running"
    if docker ps -a | grep -q "$CONTAINER_NAME"; then
        echo "  Container exists but is stopped"
        docker ps -a | grep "$CONTAINER_NAME"
    else
        echo "  Container does not exist"
    fi
    exit 1
fi

echo ""

# Check container logs
echo "2. Checking container logs..."
echo "Last 20 lines of logs:"
docker logs --tail 20 "$CONTAINER_NAME" 2>&1 || echo "Failed to get logs"

echo ""

# Check config.toml
echo "3. Checking config.toml..."
if [ -f "$RUNNER_DIR/config.toml" ]; then
    echo "✓ Config file exists"
    echo "Permissions: $(ls -la "$RUNNER_DIR/config.toml")"
    echo ""
    echo "Config content:"
    cat "$RUNNER_DIR/config.toml"
else
    echo "✗ Config file not found at $RUNNER_DIR/config.toml"
fi

echo ""

# Check network connectivity
echo "4. Checking network connectivity..."
if docker exec "$CONTAINER_NAME" ping -c 1 8.8.8.8 >/dev/null 2>&1; then
    echo "✓ Internet connectivity OK"
else
    echo "✗ No internet connectivity"
fi

echo ""

# Check Docker socket access
echo "5. Checking Docker socket access..."
if docker exec "$CONTAINER_NAME" docker ps >/dev/null 2>&1; then
    echo "✓ Docker socket access OK"
else
    echo "✗ Cannot access Docker socket"
fi

echo ""

# Check GitLab connectivity
echo "6. Checking GitLab connectivity..."
if [ -f "$RUNNER_DIR/config.toml" ]; then
    GITLAB_URL=$(grep -E '^[[:space:]]*url[[:space:]]*=' "$RUNNER_DIR/config.toml" | head -1 | sed 's/.*= *"\([^"]*\)".*/\1/')
    if [ -n "$GITLAB_URL" ]; then
        echo "GitLab URL from config: $GITLAB_URL"
        if docker exec "$CONTAINER_NAME" curl -s --connect-timeout 10 "$GITLAB_URL" >/dev/null 2>&1; then
            echo "✓ GitLab connectivity OK"
        else
            echo "✗ Cannot connect to GitLab"
        fi
    else
        echo "? GitLab URL not found in config"
    fi
fi

echo ""

# Check runner status
echo "7. Checking runner status..."
if docker exec "$CONTAINER_NAME" gitlab-runner --version >/dev/null 2>&1; then
    echo "✓ GitLab Runner binary accessible"
    echo "Version: $(docker exec "$CONTAINER_NAME" gitlab-runner --version | head -1)"
    
    if docker exec "$CONTAINER_NAME" gitlab-runner verify >/dev/null 2>&1; then
        echo "✓ Runner verification passed"
    else
        echo "✗ Runner verification failed"
        echo "Verification output:"
        docker exec "$CONTAINER_NAME" gitlab-runner verify 2>&1 || true
    fi
else
    echo "✗ GitLab Runner binary not accessible"
fi

echo ""

# Check for common issues
echo "8. Checking for common issues..."

# Check if runner is registered
if [ -f "$RUNNER_DIR/config.toml" ] && grep -q "token" "$RUNNER_DIR/config.toml"; then
    echo "✓ Runner appears to be registered (token found in config)"
else
    echo "✗ Runner may not be registered (no token in config)"
fi

# Check for SSL/TLS issues
if docker logs "$CONTAINER_NAME" 2>&1 | grep -i "ssl\|tls\|certificate" >/dev/null; then
    echo "⚠ SSL/TLS issues detected in logs"
fi

# Check for permission issues
if docker logs "$CONTAINER_NAME" 2>&1 | grep -i "permission\|denied" >/dev/null; then
    echo "⚠ Permission issues detected in logs"
fi

# Check for network issues
if docker logs "$CONTAINER_NAME" 2>&1 | grep -i "network\|connection\|timeout" >/dev/null; then
    echo "⚠ Network issues detected in logs"
fi

echo ""

echo "=== Diagnostic complete ==="
echo ""
echo "If you're still having issues, check:"
echo "1. GitLab instance is accessible from the runner host"
echo "2. Registration token is valid and not expired"
echo "3. Runner has proper permissions to access Docker socket"
echo "4. Network configuration allows runner to reach GitLab"
echo "5. SSL/TLS certificates are valid if using HTTPS" 