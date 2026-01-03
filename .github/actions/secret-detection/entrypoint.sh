#!/bin/bash

set -e

git config --global --add safe.directory /github/workspace

gitleaks git --redact -f json -r $GITHUB_WORKSPACE/secret-detection-report.json $GITHUB_WORKSPACE
