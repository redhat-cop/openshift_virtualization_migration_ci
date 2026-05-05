# Ansible Collection CI/CD Workflow

### Purpose

This reusable workflow automates the lifecycle of an Ansible collection, including secret scanning, linting, testing with `tox-ansible`, manual release creation, and publishing to Red Hat Automation Hub.

### Workflow Architecture

The workflow execution is gated by stages:

1. **Secrets**: Scan commits for secrets.
2. **Preparation**: Validate access tokens.
3. **Testing**: Executes linting and the test suite using the provided tox configuration.
4. **Report**: Upload code quality report to artifacts.
5. **Release** (manual trigger): Creates a release branch with updated version and changelog, then opens a PR.
6. **Publish** (automatic): Triggered by push events with release commit messages. Rebuilds artifacts, manages tags, and publishes to GitHub and Automation Hub.

**Release Process**: 
- Trigger via `workflow_dispatch` with `trigger_release: true`
- Creates a release branch with updated `galaxy.yml` and `CHANGELOG.md`
- Opens a PR for review (or auto-merges if `auto_merge: true`)
- When PR is merged, the push event triggers automatic publishing
- Publishing detects release commits by message pattern: `chore(release): X.Y.Z`

The workflow uses a custom-built container image including all the required tooling used for testing and release automation. Release commits to protected target branches are supported by means of a GitHub App used to bypass protection rules.
---

### API Interface

#### Inputs

| Name                        | Type      | Default | Description |
| --------------------------- | --------- | ------- | ----------- |
| `trigger_release`           | `boolean` | `false` | Set to `true` to create a release PR via workflow_dispatch. |
| `auto_merge`                | `boolean` | `false` | Enable auto-merge for release PR (squash merge). |
| `target_branch`             | `string`  | `main`  | The branch that triggers release and publish logic. |
| `ref`                       | `string`  | None    | The reference used on checkout code. |
| `repo`                      | `string`  | None    | The repository used on checkout code. |
| `image`                     | `string`  | `ghcr.io/redhat-cop/openshift_virtualization_migration_ci/ci-python-env:latest` | Container image containing CI tooling. |
| `test_requirements`         | `string`  | `test-requirements.txt` | Path to Python packages required for testing. |
| `ansible_requirements`      | `string`  | `requirements-dev.yml` | Path to Ansible collection dependencies. |
| `tox_config_file`           | `string`  | `tox-ansible.ini` | Configuration file for Tox. |
| `automation_hub_url`        | `string`  | `https://console.redhat.com/api/automation-hub/` | API URL for the Automation Hub. |
| `automation_hub_repository` | `string`  | `staging` | Target repository in Automation Hub. |
| `publish_to_automation_hub` | `boolean` | `false` | Set to `true` to enable publishing to Automation Hub. |

#### Secrets

| Name | Required | Description |
| ------------------------- | ------- | ----------------------------------------------------------------------------------- |
| `automation_hub_token`    | **Yes** | Authentication token for pulling dependencies from and uploading to Automation Hub. |
| `release_app_id`          | **No**  | ID of GitHub App used to bypass branch protection of target branch.                 |
| `release_app_private_key` | **No**  | Private key of GitHub App used to bypass branch protection of target branch.        |

---

### Technical Details

#### How Publishing Works

When a release PR is merged to the target branch:

1. **Commit Detection**: The workflow detects release commits by matching the pattern `chore(release): X.Y.Z`
2. **Tag Management**: The tag created on the release branch is moved to the squash merge commit on the target branch
3. **Artifact Rebuild**: The collection is rebuilt from the target branch (artifacts don't persist between workflow runs)
4. **GitHub Release**: Created with auto-generated release notes from commits and PRs
5. **Automation Hub**: Published using the rebuilt artifact (if enabled)

#### Tag Placement

The release process uses squash merge, which creates a new commit SHA on the target branch. The workflow automatically:
- Deletes the tag from the release branch
- Recreates it on the squash merge commit
- This ensures the tag points to the correct commit in the target branch history

#### Retry Safety

The publish stage is designed to be retry-safe:
- Checks if GitHub release already exists before creating
- Rebuilds artifacts from source (no dependency on previous runs)
- Handles existing tags gracefully

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

  pull_request_target:
    types: [opened, synchronize, reopened]
  
  workflow_dispatch:
    inputs:
      trigger_release:
        type: boolean
        default: false
        description: 'Create release PR'
      auto_merge:
        type: boolean
        default: false
        description: 'Enable auto-merge for release PR'
  
jobs:
  ci:
    uses: redhat-cop/openshift_virtualization_migration_ci/.github/workflows/ci-ansible-collection.yml@v2
    permissions:
      contents: write
      packages: write
      security-events: write
      actions: read
      pull-requests: write
    with:
      ref: ${{ github.sha }}
      repo: ${{ github.repository }}
      target_branch: 'main'
      trigger_release: ${{ inputs.trigger_release || false }}
      auto_merge: ${{ inputs.auto_merge || false }}
      ansible_requirements: "requirements-dev.yml"
      test_requirements: "test-requirements.txt"
      tox_config_file: "tox-ansible.ini"
      automation_hub_url: https://console.redhat.com/api/automation-hub/
      publish_to_automation_hub: true
    secrets:
      automation_hub_token: ${{ secrets.AUTOMATION_HUB_TOKEN }}
      release_app_id: ${{ secrets.RELEASE_APP_ID }}
      release_app_private_key: ${{ secrets.RELEASE_APP_PRIVATE_KEY }}
```

### Creating Releases

**Manual Release** (with review):
```bash
gh workflow run ci.yml -f trigger_release=true -f auto_merge=false
```
This creates a release branch and PR. Review and merge when ready.

**Auto-Merge Release** (quick):
```bash
gh workflow run ci.yml -f trigger_release=true -f auto_merge=true
```
This creates a release PR that auto-merges when CI passes.

When the release PR is merged, publishing to GitHub and Automation Hub happens automatically.
