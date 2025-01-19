TOPIC := "Available Recipes for Goal:\n"

_default:
    @just --list --unsorted --list-prefix "✨ " --list-heading '{{TOPIC}}'

run:
    go mod tidy
    go run cmd/helloworld/main.go

update-pre-commithooks:
    #!/usr/local/bin/bash
    set -euo pipefail
    pre-commit autoupdate
    pre-commit install
    git add .pre-commit-config.yaml
    if git diff --cached --quiet .pre-commit-config.yaml; then
        echo "No changes to pre-commit config"
    else
        echo "Pre-commit config updated and staged"
    fi

commit:
    @./scripts/commit.sh ${@}

lazy-commit:
    @./scripts/commit.sh --lazy

next-release:
    @./scripts/prepare_release.sh
