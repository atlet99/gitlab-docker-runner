#!/bin/bash

# Debug script for GitLab Runner registration command
# This script helps troubleshoot registration command issues

set -e

echo "=== GitLab Runner Registration Command Debug ==="
echo

# Check if container exists
if docker ps -a --format "table {{.Names}}" | grep -q "gitlab-runner"; then
    echo "✅ GitLab Runner container exists"
    CONTAINER_NAME=$(docker ps -a --format "table {{.Names}}" | grep "gitlab-runner" | head -1)
    echo "   Container name: $CONTAINER_NAME"
else
    echo "❌ GitLab Runner container not found"
    exit 1
fi

echo

# Check container status
echo "=== Container Status ==="
docker ps -a --filter "name=gitlab-runner" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo

# Check if container is running
if docker ps --format "table {{.Names}}" | grep -q "gitlab-runner"; then
    echo "✅ Container is running"
else
    echo "❌ Container is not running"
    echo "   Starting container..."
    docker start gitlab-runner
    sleep 5
fi

echo

# Check container logs
echo "=== Recent Container Logs ==="
docker logs gitlab-runner --tail 20

echo

# Check current config
echo "=== Current Configuration ==="
if docker exec gitlab-runner test -f /etc/gitlab-runner/config.toml; then
    echo "✅ Config file exists"
    echo "   Config file content:"
    docker exec gitlab-runner cat /etc/gitlab-runner/config.toml
else
    echo "❌ Config file not found"
fi

echo

# Check registered runners
echo "=== Registered Runners ==="
docker exec gitlab-runner gitlab-runner list 2>/dev/null || echo "No runners found or command failed"

echo

# Test network connectivity
echo "=== Network Connectivity Test ==="
if docker exec gitlab-runner ping -c 1 8.8.8.8 >/dev/null 2>&1; then
    echo "✅ Internet connectivity: OK"
else
    echo "❌ Internet connectivity: FAILED"
fi

echo

# Check Docker socket access
echo "=== Docker Socket Access ==="
if docker exec gitlab-runner test -S /var/run/docker.sock; then
    echo "✅ Docker socket accessible"
else
    echo "❌ Docker socket not accessible"
fi

echo

# Check environment variables
echo "=== Environment Variables ==="
docker exec gitlab-runner env | grep -E "(GITLAB|RUNNER|DOCKER)" || echo "No relevant environment variables found"

echo

echo "=== Debug Complete ==="
echo "If you see 'network host--docker-volumes not found' error, check:"
echo "1. Command formatting in tasks/main.yml"
echo "2. Parameter order in legacy registration command"
echo "3. Extra spaces or formatting issues" 