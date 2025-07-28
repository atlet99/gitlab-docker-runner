# Changelog: Unified GitLab Runner Registration Logic

## Version 2.0.0 - Unified Registration Logic

### 🚀 New Features

#### Unified Registration Logic
- **Automatic mode detection**: Role automatically selects between modern (token) and legacy (registration_token) approaches
- **API-first approach**: Uses GitLab API for registration when available
- **CLI fallback**: Reliable fallback to CLI commands if API is unavailable
- **Zero crutches**: No post-registration file modifications

#### Improved Architecture
- **Modular structure**: Registration logic moved to separate file `tasks/register.yml`
- **Single template**: One `config.toml.j2` handles both approaches
- **Enhanced error handling**: Clear error messages and validation
- **Configurable behavior**: Fine-grained control over unified logic settings

### 🔧 Technical Changes

#### New Files
- `tasks/register.yml` - Unified registration logic
- `example-unified-registration.yml` - Usage examples
- `example-advanced-unified-settings.yml` - Advanced settings examples
- `test-unified-logic.yml` - Test playbook
- `UNIFIED_REGISTRATION.md` - Documentation for unified logic
- `CHANGELOG_UNIFIED.md` - This file

#### Updated Files
- `tasks/main.yml` - Simplified to include `register.yml`
- `templates/config.toml.j2` - Updated to support unified logic
- `defaults/main.yml` - Added unified logic configuration variables
- `README.md` - Added documentation for unified logic

### 📋 How it works

#### Modern Mode
```yaml
# When gitlab_runner_token is provided
gitlab_runner_token: "your-authentication-token"
```
- Uses token directly in configuration
- No registration process required
- Suitable for existing runners

#### Legacy Mode
```yaml
# When gitlab_runner_registration_token is provided
gitlab_runner_registration_token: "your-registration-token"
```
1. **API-first**: Attempts to register via GitLab API
2. **CLI fallback**: If API is unavailable, uses `gitlab-runner register`
3. **Token extraction**: Extracts runner token and ID from registration process
4. **Configuration generation**: Creates final `config.toml` with extracted data

### 🎯 Benefits

#### Ease of use
- Single interface for all cases
- Automatic mode detection
- Consistent configuration

#### Reliability
- API-first with reliable fallback
- Handles network issues
- Parameter validation

#### Performance
- Fast registration via API
- Minimal number of operations
- Optimized logic

#### Production readiness
- Handles all edge cases
- Detailed logging
- Backward compatibility

### 📖 Usage Examples

#### Modern approach
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

#### Legacy approach
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

#### Automatic detection
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

### 🔄 Backward Compatibility

The new unified logic is fully backward compatible:

- **Modern approach**: Continues to work as before
- **Legacy approach**: Now uses API-first with CLI fallback
- **Configuration**: One template for all cases
- **Variables**: All existing variables are supported

### 🧪 Testing

To test the new logic, use:

```bash
# Set token for testing
export GITLAB_RUNNER_TOKEN="your-token"
# or
export GITLAB_RUNNER_REGISTRATION_TOKEN="your-registration-token"

# Run test playbook
ansible-playbook test-unified-logic.yml
```

### 📚 Documentation

- `README.md` - Main documentation with examples
- `UNIFIED_REGISTRATION.md` - Detailed documentation for unified logic
- `example-unified-registration.yml` - Extended usage examples

### 🎉 Conclusion

Unified registration logic provides:

- **Simplicity**: Single interface for all cases
- **Reliability**: API-first with reliable fallback
- **Performance**: Fast registration via API
- **Compatibility**: Works with any GitLab versions
- **Production readiness**: Handles all edge cases

This implementation fully complies with the idea from `.gitlab-runner-idea-docs.md` and provides an elegant solution for unifying GitLab Runner registration. 