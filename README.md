# Ansible Collection CI/CD Workflow

### Purpose

This reusable workflow automates the lifecycle of an Ansible collection, including secret scanning, environment preparation, testing with `tox-ansible`, automated version releasing, and publishing to Red Hat Automation Hub.

### Workflow Architecture

The workflow execution is gated by stages:

1. **Secrets**: Scan commits for secrets.
2. **Preparation**: Sets up the CI environment and dependencies.
3. **Testing**: Executes the test suite using the provided tox configuration.
4. **Release**: Determines the next version and creates tags (Dry-run on PRs).
5. **Publish**: Publishes the collection to GitHub and pushes it to Automation Hub upon merge to `main`.

---

### API Interface

#### Inputs

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `target_branch` | `string` | `main` | The branch that triggers release and publish logic. |
| `ref` | `string` | None | The reference used on checkout code. |
| `repo` | `string` | None | The repository used on checkout code. |
| `image` | `string` | `ghcr.io/redhat-cop/openshift_virtualization_migration_ci/ci-python-env:latest` | Container image containing CI tooling. |
| `test_requirements` | `string` | `test-requirements.txt` | Path to Python packages required for testing. |
| `ansible_requirements` | `string` | `requirements-dev.yml` | Path to Ansible collection dependencies. |
| `tox_config_file` | `string` | `tox-ansible.ini` | Configuration file for Tox. |
| `automation_hub_url` | `string` | `https://console.redhat.com/api/automation-hub/` | API URL for the Automation Hub. |
| `publish_to_automation_hub` | `boolean` | `false` | Set to `true` to enable publishing to Automation Hub. |

#### Secrets

| Name | Required | Description |
| --- | --- | --- |
| `automation_hub_token` | **Yes** | Authentication token for pulling dependencies from and uploading to Automation Hub. |

---

### Permissions & Concurrency

- **Permissions**: The workflow defaults to `contents: read` and `packages: read`. However, the **Release** and **Publish** stages require `contents: write` to manage tags and releases.
- **Concurrency**:
  - PR runs will cancel if a new commit is pushed to the same PR.
  - `main` branch runs will **not** cancel in progress to ensure release integrity.

---

### Implementation Example

```yaml
name: CI

on:
  push:
    branches: [ "main" ]
  pull_request:
    branches: [ "main" ]

  workflow_dispatch:

jobs:
  ansible-ci:
    uses: redhat-cop/openshift_virtualization_migration_ci/.github/workflows/ci-ansible-collection.yml@main
    permissions:
      contents: write
      packages: read
    with:
      target_branch: 'main'
      ref: ${{ github.sha }}
      repo: ${{ github.repository }}
      ansible_requirements: "requirements-dev.yml"
      test_requirements: "test-requirements.txt"
      tox_config_file: "tox-ansible.ini"
      automation_hub_url: https://console.redhat.com/api/automation-hub/
      publish_to_automation_hub: true
    secrets:
      automation_hub_token: ${{ secrets.AUTOMATION_HUB_TOKEN }}
```
