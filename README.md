# GitLab Docker Runner Ansible Role

This Ansible role deploys and configures GitLab Runner as a Docker container with comprehensive configuration options for CI/CD pipelines.

## Features

- **Docker-based deployment**: Runs GitLab Runner in a Docker container
- **Flexible configuration**: Extensive customization options for runner settings
- **Network management**: Support for custom Docker networks and network per build
- **Security focused**: Proper file permissions and security configurations
- **Production ready**: Includes monitoring, logging, and backup considerations
- **Dual registration support**: Supports both modern token-based and legacy registration methods

## Requirements

### Ansible
- Ansible 2.9 or higher
- Python 3.6 or higher

### Target System
- Docker installed and running
- Linux-based system (tested on Ubuntu 20.04+, CentOS 7+, RHEL 7+)

### Collections
- `community.docker` - For Docker container management
- `geerlingguy.docker` - For Docker installation (optional)

## Installation

### Using Ansible Galaxy
```bash
ansible-galaxy install git+https://github.com/atlet99/gitlab-docker-runner.git
```

### Manual Installation
1. Clone this repository
2. Copy the role to your Ansible roles directory
3. Install required collections:
```bash
ansible-galaxy collection install community.docker
ansible-galaxy install geerlingguy.docker
```

## Role Variables

### Required Variables

#### Modern Registration Method (Default)
```yaml
# GitLab Runner registration (modern method)
gitlab_runner_url: "https://gitlab.com/"
gitlab_runner_token: "your-authentication-token"
gitlab_runner_name: "my-runner"
gitlab_runner_registration_method: "modern"
```

#### Legacy Registration Method
```yaml
# GitLab Runner registration (legacy method)
gitlab_runner_url: "https://gitlab.com/"
gitlab_runner_registration_token: "your-registration-token"
gitlab_runner_name: "my-runner"
gitlab_runner_registration_method: "legacy"
```

### Registration Method Selection

The role supports two registration methods:

1. **Modern Method** (`gitlab_runner_registration_method: "modern"` - default):
   - Uses authentication token directly in `config.toml`
   - Requires `gitlab_runner_token` variable
   - More secure and recommended for new deployments

2. **Legacy Method** (`gitlab_runner_registration_method: "legacy"`):
   - Uses registration token with `gitlab-runner register` command
   - Requires `gitlab_runner_registration_token` variable
   - Compatible with older GitLab Runner versions and workflows

### Optional Variables

#### Global Settings
```yaml
# Runner version and basic settings
gitlab_runner_version: "latest"
gitlab_runner_concurrent: 4
gitlab_runner_check_interval: 3
gitlab_runner_log_level: "info"

# Container configuration
gitlab_runner_container_name: "gitlab-runner"
runner_directory: "/var/lib/gitlab-runner"
```

#### Docker Executor Settings
```yaml
# Basic Docker settings
docker_image: "alpine:latest"
docker_privileged: false
docker_pull_policy: "if-not-present"

# Advanced Docker settings
docker_cpus: ""
docker_memory: ""
docker_volumes:
  - "/var/run/docker.sock:/var/run/docker.sock"
  - "/cache:/cache"
```

#### Network Configuration
```yaml
# Network settings
runner_network_per_build: false
docker_network_mode: "bridge"

# Custom network (optional)
docker_network: "my-runner-network"
docker_network_subnet: "192.168.100.0/24"
docker_network_gateway: "192.168.100.1"
```

#### Cache Configuration
```yaml
# Cache settings
cache_type: "" # "s3", "gcs", "azure", etc.
cache_path: ""
cache_shared: false

# S3 cache example
cache_s3_server_address: "s3.amazonaws.com"
cache_s3_access_key: "your-access-key"
cache_s3_secret_key: "your-secret-key"
cache_s3_bucket_name: "my-cache-bucket"
```

## Example Playbook

### Modern Registration Method (Default)
```yaml
---
- hosts: gitlab-runners
  roles:
    - role: gitlab-docker-runner
      vars:
        gitlab_runner_url: "https://gitlab.company.com/"
        gitlab_runner_token: "{{ vault_gitlab_token }}"
        gitlab_runner_name: "production-runner"
        gitlab_runner_registration_method: "modern"
        gitlab_runner_tags:
          - "docker"
          - "production"
```

### Legacy Registration Method
```yaml
---
- hosts: gitlab-runners
  roles:
    - role: gitlab-docker-runner
      vars:
        gitlab_runner_url: "https://gitlab.company.com/"
        gitlab_runner_registration_token: "{{ vault_gitlab_registration_token }}"
        gitlab_runner_name: "legacy-runner"
        gitlab_runner_registration_method: "legacy"
        gitlab_runner_tags:
          - "docker"
          - "legacy"
```

### Advanced Configuration
```yaml
---
- hosts: gitlab-runners
  roles:
    - role: gitlab-docker-runner
      vars:
        # GitLab Runner settings
        gitlab_runner_url: "https://gitlab.company.com/"
        gitlab_runner_token: "{{ vault_gitlab_token }}"
        gitlab_runner_name: "advanced-runner"
        gitlab_runner_concurrent: 10
        gitlab_runner_tags:
          - "docker"
          - "kubernetes"
          - "production"
        
        # Docker executor settings
        docker_image: "ubuntu:20.04"
        docker_privileged: true
        docker_volumes:
          - "/var/run/docker.sock:/var/run/docker.sock"
          - "/cache:/cache"
          - "/builds:/builds"
        
        # Network configuration
        runner_network_per_build: true
        docker_network: "gitlab-runner-network"
        docker_network_subnet: "172.20.0.0/16"
        
        # Cache configuration
        cache_type: "s3"
        cache_s3_server_address: "s3.amazonaws.com"
        cache_s3_access_key: "{{ vault_s3_access_key }}"
        cache_s3_secret_key: "{{ vault_s3_secret_key }}"
        cache_s3_bucket_name: "gitlab-runner-cache"
```

## Configuration File

The role generates a `config.toml` file based on the Jinja2 template in `templates/config.toml.j2`. This file contains all the GitLab Runner configuration settings.

### Key Configuration Sections

1. **Global Settings**: Concurrent jobs, check interval, log level
2. **Session Server**: For job artifacts and cache
3. **Runner Configuration**: URL, token, tags, executor settings
4. **Docker Executor**: Image, volumes, network, security settings
5. **Cache Configuration**: S3, GCS, or local cache settings

### Registration Method Differences

#### Modern Method
- Token is written directly to `config.toml`
- Runner starts immediately with full configuration
- More secure as token is not exposed in command line

#### Legacy Method
- Minimal `config.toml` is generated
- Runner is registered using `gitlab-runner register` command
- Registration token is used during registration process
- Runner restarts after successful registration

## Security Considerations

### Sensitive Data
- Store tokens and credentials in Ansible Vault
- Use environment variables for sensitive configuration
- Never commit secrets to version control

### Token Security
- **Modern method**: Authentication token is stored in `config.toml` with restricted permissions (0600)
- **Legacy method**: Registration token is used only during registration and not stored permanently

### Container Security
- Run containers with minimal required privileges
- Use specific image versions instead of `latest`
- Implement proper network isolation
- Set appropriate file permissions

### Network Security
- Use custom networks for isolation
- Implement proper firewall rules
- Use TLS for GitLab communication

## Monitoring and Logging

### Log Configuration
```yaml
gitlab_runner_log_level: "info" # debug, info, warn, error
gitlab_runner_log_format: "runner"
```

### Health Checks
The role includes basic health checks for:
- Docker installation
- Network connectivity
- Container status

### Monitoring Integration
- Prometheus metrics (if enabled)
- Container resource usage
- Job execution statistics

## Troubleshooting

### Common Issues

1. **Docker not installed**
   ```bash
   # Install Docker first
   ansible-playbook -i inventory playbook.yml --tags docker
   ```

2. **Network connectivity issues**
   ```bash
   # Check network configuration
   docker network ls
   docker network inspect gitlab-runner-network
   ```

3. **Permission denied errors**
   ```bash
   # Check file permissions
   ls -la /var/lib/gitlab-runner/
   ```

4. **Runner registration fails**
   - Verify GitLab URL and token
   - Check network connectivity to GitLab
   - Ensure GitLab instance is accessible

5. **Legacy registration issues**
   - Verify registration token is valid
   - Check that registration token has not expired
   - Ensure GitLab instance supports the registration method

6. **400 Bad Request errors**
   - Check registration token validity
   - Verify GitLab URL is correct and accessible
   - Ensure runner has proper network access
   - Check SSL/TLS certificates if using HTTPS

### Debug Mode
```bash
# Run with verbose output
ansible-playbook -i inventory playbook.yml -vvv

# Check mode (dry run)
ansible-playbook -i inventory playbook.yml --check
```

### Registration Method Debugging

#### Modern Method
```bash
# Check config.toml content
cat /var/lib/gitlab-runner/config.toml

# Check runner logs
docker logs gitlab-runner
```

#### Legacy Method
```bash
# Check registration process
docker logs gitlab-runner | grep -i register

# Check final config.toml
cat /var/lib/gitlab-runner/config.toml
```

### Diagnostic Scripts

The role includes multiple diagnostic scripts to help troubleshoot issues:

```bash
# Basic diagnostic script
./scripts/diagnose-runner.sh [container-name]

# Legacy registration specific diagnostic
./scripts/diagnose-legacy-registration.sh [container-name]

# Detailed debug script for legacy registration
./scripts/debug-legacy-registration.sh [container-name]

# Examples
./scripts/diagnose-runner.sh gitlab-runner
./scripts/diagnose-legacy-registration.sh gitlab-runner
./scripts/debug-legacy-registration.sh gitlab-runner
```

#### Diagnostic Script Features

**Basic Diagnostic Script** (`diagnose-runner.sh`):
- Container status and logs
- Configuration file validity (checks inside container)
- Network connectivity
- Docker socket access
- GitLab connectivity
- Runner registration status
- Common error patterns

**Legacy Registration Diagnostic** (`diagnose-legacy-registration.sh`):
- Registration-specific checks
- Authentication token validation
- Registration process analysis
- Configuration file analysis
- Runner status verification

**Debug Script** (`debug-legacy-registration.sh`):
- Comprehensive container analysis
- Full log examination
- Detailed configuration analysis
- Token format validation
- Network connectivity tests
- Error pattern detection
- Detailed recommendations

### 400 Bad Request Error Resolution

If you're getting `400 Bad Request` errors with legacy registration:

1. **Check registration token**:
   ```bash
   # Verify token in GitLab admin panel
   # Ensure token hasn't expired
   # Check token permissions
   ```

2. **Verify GitLab URL**:
   ```bash
   # Test connectivity from runner host
   curl -I https://git.testenv.com
   
   # Check SSL certificates
   openssl s_client -connect git.testenv.com:443
   ```

3. **Check runner configuration**:
   ```bash
   # View current config
   cat /var/lib/gitlab-runner/config.toml
   
   # Check runner status
   docker exec gitlab-runner gitlab-runner verify
   ```

4. **Network troubleshooting**:
   ```bash
   # Check DNS resolution
   nslookup git.testenv.com
   
   # Check firewall rules
   iptables -L
   ```

5. **Re-register runner**:
   ```bash
   # Remove old config
   rm /var/lib/gitlab-runner/config.toml
   
   # Restart container to trigger re-registration
   docker restart gitlab-runner
   ```

## Development

### Testing
```bash
# Run ansible-lint
ansible-lint

# Run molecule tests
molecule test

# Test against specific platforms
molecule test --platform ubuntu-20.04
```

### Contributing
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

For issues and questions:
- Create an issue on GitHub
- Check the troubleshooting section
- Review GitLab Runner documentation

## Changelog

### Version 1.2.0
- Fixed legacy registration process to properly handle authentication token generation
- Improved container lifecycle management for legacy registration
- Enhanced diagnostic capabilities with multiple specialized scripts
- Added comprehensive error detection and reporting
- Improved validation of registration process
- Enhanced troubleshooting documentation

### Version 1.1.0
- Added support for legacy registration method using `registration_token`
- Added `gitlab_runner_registration_method` variable to choose between modern and legacy methods
- Enhanced documentation for both registration approaches
- Improved error handling for registration process
- Added diagnostic script for troubleshooting
- Enhanced validation and error reporting

### Version 1.0.0
- Initial release
- Basic GitLab Runner deployment
- Docker executor support
- Network configuration
- Cache support (S3, GCS, Azure)
- Security configurations
- Monitoring and logging
