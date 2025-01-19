#!/usr/local/bin/bash
set -e

#############
# Functions #
#############
# Get the current latest tag
get_current_tag() {
    local tag
    tag=$(git describe --tags --abbrev=0 2> /dev/null)
    if [[ -z ${tag} ]]; then
        echo "none"
    else
        echo "${tag}"
    fi
}

# Display commits since the given tag
show_commits_since_tag() {
    local tag=${1}
    echo -e "\nCommits since tag ${tag}:"
    if [[ ${tag} == "none" ]]; then
        git log --oneline
    else
        git log --oneline "${tag}..HEAD"
    fi
}

# Validate tag format (v0.0.0)
validate_tag_format() {
    local tag=${1}
    if [[ ! ${tag} =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "Error: Tag must be in format v0.0.0"
        return 1
    fi
    return 0
}

# Compare version tags (returns 1 if new_tag <= current_tag)
validate_tag_version() {
    local current_tag=${1}
    local new_tag=${2}

    [[ ${current_tag} == "none" ]] && return 0

    local current_version=${current_tag#v}
    local new_version=${new_tag#v}

    if [[ ${current_version} == $(echo -e "${current_version}\n${new_version}" | sort -V | tail -n1) ]]; then
        echo "Error: New tag must be greater than current tag"
        return 1
    fi
    return 0
}

# Create new tag after confirmation
create_tag() {
    local new_tag=${1}
    echo -e "\nAbout to create tag: ${new_tag}"
    echo -n "Proceed? (y/n): "
    read -r confirm

    if [[ ${confirm} == "y" ]]; then
        git tag "${new_tag}"
        echo "Tag ${new_tag} created locally"
        echo "To push the tag, run: git push origin ${new_tag}"
        return 0
    else
        echo "Operation cancelled"
        return 1
    fi
}

#######################
# Main execution flow #
#######################
main() {
    # Get and display current tag
    current_tag=$(get_current_tag)
    echo "Current tag: ${current_tag}"

    # Show commit history
    show_commits_since_tag "${current_tag}"

    # Prompt for new tag
    echo -e "\nCurrent tag is ${current_tag}"
    echo -n "Enter new tag (e.g., v0.1.3): "
    read -r new_tag

    # Validate tag format and version
    if validate_tag_format "${new_tag}" && validate_tag_version "${current_tag}" "${new_tag}"; then
        create_tag "${new_tag}"
    else
        exit 1
    fi
}

# Execute main function
main
