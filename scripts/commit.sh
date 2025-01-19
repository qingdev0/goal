#!/usr/local/bin/bash
set -euo pipefail

usage() {
    echo "Usage: $0 [--lazy]"
    echo "  --lazy    Amend the last commit and force push"
    exit 1
}

check_unstaged_changes() {
    if [[ -n "$(git diff)" ]]; then
        echo "Warning: You have unstaged changes!"
        read -p "Do you want to continue? [y/N] " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Commit cancelled"
            exit 0
        fi
    fi
}

lazy_commit() {
    if ! git diff --quiet; then
        echo "Error: There are unstaged changes. Please stage all changes before running this command."
        echo "Unstaged changes:"
        git --no-pager diff --name-status
        exit 1
    fi
    git commit --amend --no-edit
    git push --force
}

regular_commit() {
    git status
    check_unstaged_changes
    git commit -e
}

main() {
    if [[ $# -eq 0 ]]; then
        regular_commit
    elif [[ $# -eq 1 && $1 == "--lazy" ]]; then
        lazy_commit
    else
        usage
    fi
}

main "$@"
