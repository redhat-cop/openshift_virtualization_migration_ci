# CI/CD Implementation for Ansible Collections

GitHub actions and reusable workflows used to implement continuous integration of Ansible collections using semantic versioning. To enable CI in your repository including a job to publish the collection to Automation Hub, add the following GitHub workflow:

```yaml
name: CI

on:
  push:
    branches: [ "main" ]
  pull_request:
    branches: [ "main" ]

  workflow_dispatch:

jobs:
  ci:
    uses: open-appdev-lab/ansible-collections-ci/.github/workflows/ci-ansible-collection.yml@main
    permissions:
      contents: write
      packages: write
    with:
      automation_hub_url: https://console.redhat.com/api/automation-hub/
    secrets:
      automation_hub_token: ${{ secrets.AUTOMATION_HUB_TOKEN }}
```

Note that the secret `AUTOMATION_HUB_TOKEN` must be added to the repository.