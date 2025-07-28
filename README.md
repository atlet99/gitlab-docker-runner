# GitLab Docker Runner Ansible Role

This Ansible role deploys and configures GitLab Runner as a Docker container with comprehensive configuration options for CI/CD pipelines.

## Features

- **Docker-based deployment**: Runs GitLab Runner in a Docker container
- **Unified registration logic**: Intelligent support for both modern (token) and legacy (registration_token) approaches
- **Flexible configuration**: Extensive customization options for runner settings
- **Network management**: Support for custom Docker networks and network per build
- **Security focused**: Proper file permissions and security configurations
- **Production ready**: Includes monitoring, logging, and backup considerations
- **API-first approach**: Uses GitLab API for registration when available, with CLI fallback
- **Complete GitLab Runner support**: All configuration options supported via command-line arguments and templates
- **Optimized deployment**: No post-registration file editing or container restarts
- **Advanced Docker features**: GPU support, custom build directories, services, and more

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
```

#### Legacy Registration Method
```yaml
# GitLab Runner registration (legacy method)
gitlab_runner_url: "https://gitlab.com/"
gitlab_runner_registration_token: "your-registration-token"
gitlab_runner_name: "my-runner"
```

### Unified Registration Logic

The role implements intelligent unified registration logic that automatically handles both modern and legacy approaches:

#### Modern Approach (Token-based)
When `gitlab_runner_token` is provided:
- Uses the token directly in the configuration
- No registration process needed
- Suitable for existing runners or when you have the authentication token

#### Legacy Approach (Registration Token)
When `gitlab_runner_registration_token` is provided:
1. **API-first**: Attempts to register via GitLab API (`POST /api/v4/runners`)
2. **CLI fallback**: If API is unavailable, falls back to `gitlab-runner register` command
3. **Token extraction**: Extracts runner token and ID from the registration process
4. **Configuration generation**: Creates final `config.toml` with extracted data

#### Automatic Mode Detection
The role automatically detects the mode based on available variables:
- **Modern mode**: When `gitlab_runner_token` is provided
- **Legacy mode**: When `gitlab_runner_registration_token` is provided
- **Validation**: Ensures at least one token is available

#### Advanced Unified Logic Settings
The role provides fine-grained control over the unified logic:

```yaml
# Enable/disable unified logic (default: true)
gitlab_runner_unified_logic_enabled: true

# API registration timeout in seconds (default: 30)
gitlab_runner_api_timeout: 30

# Enable API-first approach (default: true)
gitlab_runner_api_first_enabled: true

# Enable CLI fallback when API fails (default: true)
gitlab_runner_cli_fallback_enabled: true

# Validate GitLab URL before registration (default: true)
gitlab_runner_validate_url: true

# Cleanup temporary containers after CLI fallback (default: true)
gitlab_runner_cleanup_temp_containers: true
```

#### Benefits of Unified Logic
- **Single configuration**: One template handles both approaches
- **API efficiency**: Uses GitLab API when available for faster registration
- **Fallback reliability**: CLI fallback ensures compatibility
- **Zero crutches**: No post-registration file modifications needed
- **Production ready**: Handles network issues and API failures gracefully
- **Configurable**: Fine-grained control over behavior

### Optional Variables

#### Global Settings
```yaml
# Runner version and basic settings
gitlab_runner_version: "latest"
gitlab_runner_concurrent: 4
gitlab_runner_check_interval: 3
gitlab_runner_log_level: "info"
gitlab_runner_log_format: "runner"
gitlab_runner_shutdown_timeout: 30
gitlab_runner_connection_max_age: "15m"

# Container configuration
gitlab_runner_container_name: "gitlab-runner"
runner_directory: "/var/lib/gitlab-runner"
```

#### Runner Behavior Settings
```yaml
# Runner behavior configuration
gitlab_runner_maximum_timeout: 0
gitlab_runner_run_untagged: true
gitlab_runner_locked: false
gitlab_runner_access_level: "not_protected"
gitlab_runner_paused: false
gitlab_runner_maintenance_note: ""

# Request concurrency limit
gitlab_runner_request_concurrency: 1
```

#### Runner Scripts and Configuration
```yaml
# Pre/post execution scripts
gitlab_runner_pre_get_sources_script: ""
gitlab_runner_post_get_sources_script: ""
gitlab_runner_pre_build_script: ""
gitlab_runner_post_build_script: ""

# Debug and security settings
gitlab_runner_debug_trace_disabled: false
gitlab_runner_safe_directory_checkout: true
gitlab_runner_clean_git_config: true
gitlab_runner_shell: ""

# Advanced settings
gitlab_runner_custom_build_dir_enabled: true
gitlab_runner_clone_url: ""
gitlab_runner_unhealthy_requests_limit: 0
gitlab_runner_unhealthy_interval: "0s"
gitlab_runner_job_status_final_update_retry_limit: 0
```

#### Docker Executor Settings
```yaml
# Basic Docker settings
docker_image: "alpine:latest"
docker_privileged: false
docker_pull_policy: "if-not-present"
docker_helper_image: ""
docker_helper_image_flavor: "alpine"
docker_helper_image_autoset_arch_and_os: false

# Resource limits
docker_cpus: ""
docker_memory: ""
docker_memory_swap: ""
docker_memory_reservation: ""
docker_cpu_shares: ""
docker_cpuset_cpus: ""
docker_cpuset_mems: ""

# Security and capabilities
docker_cap_add: []
docker_cap_drop: []
docker_security_opt: []
docker_services_security_opt: []
docker_oom_kill_disable: false
docker_oom_score_adjust: ""

# Network configuration
docker_network_mode: "bridge"
docker_use_host_network: false
docker_network_mtu: 0
docker_enable_ipv6: false
docker_extra_hosts: []
docker_dns: []
docker_dns_search: []

# Volumes and storage
docker_volumes:
  - "/var/run/docker.sock:/var/run/docker.sock"
  - "/cache:/cache"
docker_volumes_from: []
docker_cache_dir: ""
docker_volume_driver: ""
docker_volume_driver_ops: {}

# Advanced Docker features
docker_gpus: ""
docker_devices: []
docker_device_cgroup_rules: []
docker_tmpfs: {}
docker_services_tmpfs: {}
docker_sysctls: {}
docker_ulimit: {}
docker_container_labels: {}

# Allowed images and services
docker_allowed_images: []
docker_allowed_services: []
docker_allowed_pull_policies: ["if-not-present", "always"]
docker_allowed_privileged_images: []
docker_allowed_privileged_services: []
docker_allowed_users: []

# Service configuration
docker_services_limit: -1
docker_service_memory: ""
docker_service_memory_swap: ""
docker_service_memory_reservation: ""
docker_service_cpus: ""
docker_service_cpu_shares: ""
docker_service_cpuset_cpus: ""
docker_service_gpus: ""
docker_service_cgroup_parent: ""

# Additional settings
docker_hostname: ""
docker_user: ""
docker_group_add: []
docker_mac_address: ""
docker_ipcmode: ""
docker_runtime: ""
docker_isolation: ""
docker_links: []
docker_wait_for_services_timeout: 30
docker_disable_cache: false
docker_disable_entrypoint_overwrite: false
```

#### Docker Services Configuration
```yaml
# Docker services for jobs
docker_services:
  - name: "postgres:13"
    alias: "postgres"
    environment:
      - "POSTGRES_PASSWORD=password"
  - name: "redis:6"
    alias: "cache"
    command: ["redis-server", "--appendonly", "yes"]
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

# Or use default bridge network (recommended for most cases)
docker_network: ""  # Leave empty to use default bridge
```

**Note**: If you don't specify a custom network, the runner will use the default Docker bridge network.

#### Cache Configuration
```yaml
# Cache settings
cache_type: "" # "s3", "gcs", "azure", etc.
cache_path: ""
cache_shared: false
cache_max_uploaded_archive_size: 0

# S3 cache configuration
cache_s3_server_address: "s3.amazonaws.com"
cache_s3_access_key: "your-access-key"
cache_s3_secret_key: "your-secret-key"
cache_s3_bucket_name: "my-cache-bucket"
cache_s3_bucket_location: ""
cache_s3_insecure: false
cache_s3_authentication_type: "access-key"
cache_s3_server_side_encryption: ""
cache_s3_server_side_encryption_key_id: ""
cache_s3_dual_stack: true
cache_s3_accelerate: false
cache_s3_path_style: false
cache_s3_role_arn: ""
cache_s3_upload_role_arn: ""

# GCS cache configuration
cache_gcs_access_id: ""
cache_gcs_private_key: ""
cache_gcs_credentials_file: ""
cache_gcs_bucket_name: ""

# Azure cache configuration
cache_azure_account_name: ""
cache_azure_account_key: ""
cache_azure_container_name: ""
cache_azure_storage_domain: ""
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
        gitlab_runner_tags:
          - "docker"
          - "production"
```

### Legacy Registration Method (Optimized)
```yaml
---
- hosts: gitlab-runners
  roles:
    - role: gitlab-docker-runner
      vars:
        gitlab_runner_url: "https://gitlab.company.com/"
        gitlab_runner_registration_token: "{{ vault_gitlab_registration_token }}"
        gitlab_runner_name: "legacy-runner"
        gitlab_runner_tags:
          - "docker"
          - "legacy"
        # All settings are applied immediately via --template-config
        gitlab_runner_concurrent: 10
        gitlab_runner_request_concurrency: 2
        gitlab_runner_run_untagged: false
        gitlab_runner_locked: false
```

### Advanced Configuration with All Features
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
        gitlab_runner_request_concurrency: 2
        gitlab_runner_tags:
          - "docker"
          - "kubernetes"
          - "production"
        gitlab_runner_run_untagged: false
        gitlab_runner_locked: false
        gitlab_runner_access_level: "not_protected"
        
        # Docker executor settings
        docker_image: "ubuntu:20.04"
        docker_privileged: true
        docker_volumes:
          - "/var/run/docker.sock:/var/run/docker.sock"
          - "/cache:/cache"
          - "/builds:/builds"
        docker_memory: "4g"
        docker_cpus: "2"
        docker_gpus: "all"
        
        # Advanced Docker settings
        docker_allowed_images: ["ubuntu:*", "alpine:*", "node:*"]
        docker_allowed_services: ["postgres:*", "redis:*", "mysql:*"]
        docker_helper_image_flavor: "ubuntu"
        docker_container_labels:
          environment: "production"
          team: "devops"
        
        # Docker services
        docker_services:
          - name: "postgres:13"
            alias: "postgres"
            environment:
              - "POSTGRES_PASSWORD=password"
              - "POSTGRES_DB=test"
          - name: "redis:6"
            alias: "cache"
        
        # Network configuration
        runner_network_per_build: true
        docker_network: "gitlab-runner-network"
        docker_network_subnet: "172.20.0.0/16"
        
        # Cache configuration
        cache_type: "s3"

### Unified Logic Examples

#### Example 1: Modern Token-based Registration
```yaml
---
- name: Deploy GitLab Runner with modern token
  hosts: all
  become: true
  vars:
    gitlab_runner_url: "https://gitlab.com/"
    gitlab_runner_token: "{{ lookup('env', 'GITLAB_RUNNER_TOKEN') }}"
    gitlab_runner_name: "modern-runner"
    gitlab_runner_tags: ["modern", "docker", "unified"]
    gitlab_runner_concurrent: 2

  roles:
    - gitlab-docker-runner
```

#### Example 2: Legacy Registration with API Fallback
```yaml
---
- name: Deploy GitLab Runner with registration token
  hosts: all
  become: true
  vars:
    gitlab_runner_url: "https://gitlab.com/"
    gitlab_runner_registration_token: "{{ lookup('env', 'GITLAB_RUNNER_REGISTRATION_TOKEN') }}"
    gitlab_runner_name: "legacy-runner"
    gitlab_runner_tags: ["legacy", "docker", "unified"]
    gitlab_runner_concurrent: 2
    gitlab_runner_run_untagged: true
    gitlab_runner_locked: false
    gitlab_runner_access_level: "not_protected"

  roles:
    - gitlab-docker-runner
```

#### Example 3: Environment-based Registration Selection
```yaml
---
- name: Deploy GitLab Runner with unified logic
  hosts: all
  become: true
  vars:
    gitlab_runner_url: "https://gitlab.com/"
    gitlab_runner_name: "unified-runner"
    gitlab_runner_tags: ["unified", "docker"]
    gitlab_runner_concurrent: 2

  roles:
    - gitlab-docker-runner
  # The role automatically detects the mode:
  # - Modern if GITLAB_RUNNER_TOKEN is set
  # - Legacy if GITLAB_RUNNER_REGISTRATION_TOKEN is set
```

#### Example 4: Advanced Configuration with S3 Cache
```yaml
---
- name: Deploy advanced GitLab Runner
  hosts: all
  become: true
  vars:
    gitlab_runner_url: "https://gitlab.com/"
    gitlab_runner_token: "{{ lookup('env', 'GITLAB_RUNNER_TOKEN') }}"
    gitlab_runner_name: "advanced-runner"
    gitlab_runner_container_name: "gitlab-runner-advanced"
    gitlab_runner_tags: ["advanced", "s3-cache", "unified"]
    gitlab_runner_concurrent: 4
    
    # Docker settings
    docker_privileged: true
    docker_shm_size: 134217728  # 128 MB
    docker_pull_policy: "always"
    
    # S3 cache configuration
    cache_type: "s3"
    cache_shared: true
    cache_s3_server_address: "{{ lookup('env', 'S3_ENDPOINT') | default('s3.amazonaws.com') }}"
    cache_s3_access_key: "{{ lookup('env', 'S3_ACCESS_KEY') }}"
    cache_s3_secret_key: "{{ lookup('env', 'S3_SECRET_KEY') }}"
    cache_s3_bucket_name: "{{ lookup('env', 'S3_BUCKET') }}"
    cache_s3_insecure: false
    
    # Network settings
    docker_use_host_network: false
    docker_network: "gitlab-runner-advanced-network"
    docker_network_subnet: "192.168.200.0/24"
    docker_network_gateway: "192.168.200.1"
    
    # Logging and timeouts
    gitlab_runner_log_level: "info"
    gitlab_runner_log_format: "json"
    gitlab_runner_check_interval: 5
    gitlab_runner_shutdown_timeout: 60

  roles:
    - gitlab-docker-runner
```
        cache_s3_server_address: "s3.amazonaws.com"
        cache_s3_access_key: "{{ vault_s3_access_key }}"
        cache_s3_secret_key: "{{ vault_s3_secret_key }}"
        cache_s3_bucket_name: "gitlab-runner-cache"
        cache_s3_bucket_location: "us-east-1"
        cache_shared: true
        cache_max_uploaded_archive_size: 5368709120  # 5GB
        
        # Custom build directory
        gitlab_runner_custom_build_dir_enabled: true
        
        # Pre/post scripts
        gitlab_runner_pre_build_script: "echo 'Starting build...'"
        gitlab_runner_post_build_script: "echo 'Build completed'"
```

## Configuration File

The role generates a `config.toml` file based on the Jinja2 template in `templates/config.toml.j2`. This file contains all the GitLab Runner configuration settings.

### Key Configuration Sections

1. **Global Settings**: Concurrent jobs, check interval, log level, shutdown timeout
2. **Session Server**: For job artifacts and cache
3. **Runner Configuration**: URL, token, tags, executor settings, scripts
4. **Docker Executor**: Complete Docker configuration with all supported options
5. **Cache Configuration**: S3, GCS, Azure cache settings
6. **Custom Build Directory**: Support for custom build paths
7. **Docker Services**: Additional services for jobs

### Registration Method Differences

#### Modern Method
- Token is written directly to `config.toml`
- Runner starts immediately with full configuration
- More secure as token is not exposed in command line

#### Legacy Method (Optimized)
- **NEW**: Uses `--template-config` to apply all settings immediately
- Complete `config.toml` is generated before registration
- All settings are applied via command-line arguments during registration
- **NO POST-REGISTRATION EDITING**: No file modifications or container restarts needed
- Registration token is used only during registration process

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
- Use allowed images and services lists

### Network Security
- Use custom networks for isolation
- Implement proper firewall rules
- Use TLS for GitLab communication

### Host Network Mode
For better connectivity to local services (like S3-compatible storage), you can use host network mode:

```yaml
# Use host network for containers
docker_use_host_network: true

# This will:
# - Use host network for job containers
# - Allow direct access to host network interfaces
# - Improve connectivity to local services
# - Override docker_network_mode setting
```

**Note**: Host network mode provides better connectivity but reduces network isolation.

## Monitoring and Logging

### Log Configuration
```yaml
gitlab_runner_log_level: "info" # debug, info, warn, error
gitlab_runner_log_format: "runner" # runner, text, json
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

## Advanced Features

### GPU Support
```yaml
# Enable GPU support for jobs
docker_gpus: "all"
# Or specify specific GPUs
docker_gpus: "0,1"
```

### Custom Build Directories
```yaml
# Enable custom build directory feature
gitlab_runner_custom_build_dir_enabled: true
```

### Docker Services
```yaml
# Define services for jobs
docker_services:
  - name: "postgres:13"
    alias: "postgres"
    environment:
      - "POSTGRES_PASSWORD=password"
  - name: "redis:6"
    alias: "cache"
    command: ["redis-server", "--appendonly", "yes"]
```

### Pre/Post Scripts
```yaml
# Scripts executed before/after operations
gitlab_runner_pre_get_sources_script: "git config --global user.name 'CI Bot'"
gitlab_runner_post_get_sources_script: "echo 'Sources retrieved'"
gitlab_runner_pre_build_script: "echo 'Starting build...'"
gitlab_runner_post_build_script: "echo 'Build completed'"
```

### Resource Limits
```yaml
# Set resource limits for containers
docker_memory: "4g"
docker_cpus: "2"
docker_cpu_shares: 1024
docker_memory_swap: "8g"
docker_memory_reservation: "2g"
```

## S3 Cache Configuration

### Complete S3 Cache Support
The role now supports all S3 cache features:

```yaml
# S3 cache configuration
cache_type: "s3"
cache_s3_server_address: "s3.amazonaws.com"
cache_s3_access_key: "your-access-key"
cache_s3_secret_key: "your-secret-key"
cache_s3_bucket_name: "gitlab-cache"
cache_s3_bucket_location: "us-east-1"
cache_s3_insecure: false
cache_s3_authentication_type: "access-key"
cache_s3_server_side_encryption: "AES256"
cache_s3_server_side_encryption_key_id: "alias/my-key"
cache_s3_dual_stack: true
cache_s3_accelerate: false
cache_s3_path_style: false
cache_s3_role_arn: "arn:aws:iam::123456789012:role/cache-role"
cache_s3_upload_role_arn: "arn:aws:iam::123456789012:role/upload-role"
```

### GCS Cache Support
```yaml
# GCS cache configuration
cache_type: "gcs"
cache_gcs_access_id: "service-account@project.iam.gserviceaccount.com"
cache_gcs_private_key: "-----BEGIN PRIVATE KEY-----\n..."
cache_gcs_bucket_name: "gitlab-cache"
# Or use credentials file
cache_gcs_credentials_file: "/path/to/credentials.json"
```

### Azure Cache Support
```yaml
# Azure cache configuration
cache_type: "azure"
cache_azure_account_name: "storageaccount"
cache_azure_account_key: "account-key"
cache_azure_container_name: "gitlab-cache"
cache_azure_storage_domain: "blob.core.windows.net"
```

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

#### Legacy Method (Optimized)
```bash
# Check registration process
docker logs gitlab-runner | grep -i register

# Check final config.toml
cat /var/lib/gitlab-runner/config.toml

# Verify all settings were applied
docker exec gitlab-runner gitlab-runner verify
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

### Version 1.3.0
- **MAJOR IMPROVEMENT**: Complete GitLab Runner configuration support
- **NEW**: Added support for all GitLab Runner command-line arguments
- **NEW**: Added `--template-config` for immediate application of all settings
- **NEW**: Support for GPU containers, custom build directories, Docker services
- **NEW**: Complete S3, GCS, and Azure cache configuration support
- **NEW**: Advanced Docker features (memory limits, CPU shares, ulimits, etc.)
- **NEW**: Pre/post execution scripts support
- **NEW**: Runner behavior settings (run_untagged, locked, access_level, etc.)
- **OPTIMIZATION**: Removed all post-registration file editing and container restarts
- **OPTIMIZATION**: All settings applied immediately during registration
- **ENHANCEMENT**: Comprehensive variable documentation and organization
- **ENHANCEMENT**: Improved template structure with all configuration sections
- **ENHANCEMENT**: Better error handling and validation

### Version 1.2.0
- Fixed legacy registration process to properly handle authentication token generation
- Improved container lifecycle management for legacy registration
- Enhanced diagnostic capabilities with multiple specialized scripts
- Added comprehensive error detection and reporting
- Improved validation of registration process
- Enhanced troubleshooting documentation

### Version 1.1.0
- Added support for legacy registration method using `registration_token`
- **BREAKING**: Removed `gitlab_runner_registration_method` variable - method is now automatically selected based on token presence
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
 