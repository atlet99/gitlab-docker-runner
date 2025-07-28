# Unified GitLab Runner Registration Logic

## Overview

The `gitlab-docker-runner` role now supports unified registration logic that automatically handles both modern (token-based) and legacy (registration_token) approaches to GitLab Runner registration.

## How it works

### 1. Authentication mode determination

The role automatically determines the mode based on provided variables:

```yaml
_auth_mode: "{{ 'modern' if (gitlab_runner_token | default('')) | length > 0 else 'legacy' }}"
```

- **Modern mode**: When `gitlab_runner_token` is provided
- **Legacy mode**: When `gitlab_runner_registration_token` is provided

### 2. Modern approach (Modern)

When `gitlab_runner_token` is provided:

```yaml
- name: Mirror modern token variables to unified names
  set_fact:
    extracted_runner_token: "{{ gitlab_runner_token }}"
```

- Uses the token directly in the configuration
- No registration process required
- Suitable for existing runners or when you have the authentication token

### 3. Legacy approach (Legacy)

When `gitlab_runner_registration_token` is provided:

#### 3.1 API-first approach
```yaml
- name: Register runner via API (legacy)
  uri:
    url: "{{ gitlab_runner_url }}/api/v4/runners"
    method: POST
    body_format: json
    body:
      registration_token: "{{ gitlab_runner_registration_token }}"
      description: "{{ gitlab_runner_name }}"
      tag_list: "{{ gitlab_runner_tags | default([]) }}"
      run_untagged: "{{ gitlab_runner_run_untagged }}"
      locked: "{{ gitlab_runner_locked }}"
      access_level: "{{ gitlab_runner_access_level }}"
      maintenance_note: "{{ gitlab_runner_maintenance_note }}"
      maximum_timeout: "{{ gitlab_runner_maximum_timeout }}"
    status_code: 201
    validate_certs: true
  register: gl_runner_reg
  failed_when: false
```

#### 3.2 CLI fallback
If API is unavailable, CLI fallback is used:

```yaml
- name: Register runner via CLI (legacy fallback)
  community.docker.docker_container_exec:
    container: "{{ gitlab_runner_container_name }}-temp"
    command: >
      gitlab-runner register
      --non-interactive
      --url {{ gitlab_runner_url }}
      --registration-token {{ gitlab_runner_registration_token }}
      --name {{ gitlab_runner_name }}
      --executor shell
      --config /etc/gitlab-runner/config.tmp.toml
  register: _cli_reg
  failed_when: false
```

#### 3.3 Token extraction
```yaml
- name: Extract token from temporary config
  command: >
    awk -F'=' '/^[[:space:]]*token[[:space:]]*=/ {gsub(/[" ]/,"",$2);print $2}' {{ runner_directory }}/config.tmp.toml
  register: _parsed_token
  changed_when: false
  failed_when: false
```

### 4. Unified configuration

One `config.toml.j2` template handles both approaches:

```jinja2
{% if gitlab_runner_token and (gitlab_runner_registration_token is not defined or gitlab_runner_registration_token == "") -%}
  token = "{{ gitlab_runner_token }}"
{% endif -%}

{# LEGACY PATH (we filled extracted_* facts) #}
{% if gitlab_runner_registration_token is defined and gitlab_runner_registration_token and extracted_runner_id is defined and extracted_runner_id -%}
  id = {{ extracted_runner_id | trim }}
{% endif -%}
{% if gitlab_runner_registration_token is defined and gitlab_runner_registration_token and extracted_runner_token is defined and extracted_runner_token -%}
  token = "{{ extracted_runner_token | trim }}"
{% endif -%}
```

## Benefits of unified logic

### 1. Single configuration
- One template handles both approaches
- No code duplication
- Consistent configuration

### 2. API-first approach
- Uses GitLab API when available
- Faster registration
- Better error handling

### 3. Reliable fallback
- CLI fallback ensures compatibility
- Works even with API issues
- Handles network problems

### 4. Zero crutches
- No post-registration file modifications
- Clean and predictable logic
- Production ready

### 5. Automatic detection
- Automatically selects the right mode
- Parameter validation
- Clear error messages

## Usage examples

### Modern approach
```yaml
---
- name: Deploy with modern token
  hosts: all
  become: true
  vars:
    gitlab_runner_url: "https://gitlab.com/"
    gitlab_runner_token: "your-authentication-token"
    gitlab_runner_name: "modern-runner"
    gitlab_runner_tags: ["modern", "docker"]

  roles:
    - gitlab-docker-runner
```

### Legacy approach
```yaml
---
- name: Deploy with registration token
  hosts: all
  become: true
  vars:
    gitlab_runner_url: "https://gitlab.com/"
    gitlab_runner_registration_token: "your-registration-token"
    gitlab_runner_name: "legacy-runner"
    gitlab_runner_tags: ["legacy", "docker"]

  roles:
    - gitlab-docker-runner
```

### Automatic detection
```yaml
---
- name: Deploy with unified logic
  hosts: all
  become: true
  vars:
    gitlab_runner_url: "https://gitlab.com/"
    gitlab_runner_name: "unified-runner"
    gitlab_runner_tags: ["unified", "docker"]
    # Role automatically selects the mode

  roles:
    - gitlab-docker-runner
```

## Environment variables

For automatic mode detection, you can use environment variables:

```bash
# For modern approach
export GITLAB_RUNNER_TOKEN="your-authentication-token"

# For legacy approach
export GITLAB_RUNNER_REGISTRATION_TOKEN="your-registration-token"
```

## Error handling

### API unavailable
If GitLab API is unavailable, the role automatically switches to CLI fallback.

### Invalid tokens
The role validates token validity and provides clear error messages.

### Network issues
Includes GitLab URL accessibility check before attempting registration.

## Logging and debugging

The role provides detailed logging for debugging:

```yaml
- name: Display registration status
  debug:
    msg: "Runner '{{ gitlab_runner_name }}' registered: {{ runner_status_check.stdout != 'not_found' }}"

- name: Verify runner configuration
  shell: docker exec {{ gitlab_runner_container_name }} gitlab-runner verify
  register: runner_verify
  failed_when: false
```

## Migration from previous versions

If you used previous versions of the role, the new unified logic is fully backward compatible:

1. **Modern approach**: Continues to work as before
2. **Legacy approach**: Now uses API-first with CLI fallback
3. **Configuration**: One template for all cases

## Conclusion

Unified registration logic provides:

- **Simplicity**: One interface for all cases
- **Reliability**: API-first with reliable fallback
- **Performance**: Fast registration via API
- **Compatibility**: Works with any GitLab versions
- **Production readiness**: Handles all edge cases 