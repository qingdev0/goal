TOPIC := "Available Recipes for Goal:\n"

_default:
    @just --list --unsorted --list-prefix "✨ " --list-heading '{{TOPIC}}'

commit:
    #!/usr/bin/env bash
    git status
    echo -n "Enter commit message: "
    read commit_message
    git commit -m "${commit_message}"
    git tag v0.1.2
    git push origin v0.1.2


run:
    go mod tidy
    go run cmd/helloworld/main.go
