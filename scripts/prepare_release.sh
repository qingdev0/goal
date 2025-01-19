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
    printf "\nCommits since tag '%s':\n" "${tag}"
    if [[ ${tag} == "none" ]]; then
        git --no-pager log --oneline
    else
        git --no-pager log --oneline "${tag}..HEAD"
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

# Suggest next version based on conventional commits
suggest_version() {
    local current_tag=$1
    local major_bump=false
    local minor_bump=false
    local patch_bump=false

    # Default to v0.1.0 if no current tag
    if [[ ${current_tag} == "none" ]]; then
        echo "v0.1.0"
        return
    fi

    # Analyze commits since last tag
    while IFS= read -r commit; do
        commit_msg=$(echo "${commit}" | sed -E 's/^[0-9a-f]{7}[[:space:]]+//')
        if [[ ${commit_msg} =~ ^.*!:.*|.*BREAKING.*CHANGE.* ]]; then
            major_bump=true
        elif [[ ${commit_msg} =~ ^feat: ]]; then
            minor_bump=true
        else
            patch_bump=true
        fi
    done < <(git log --oneline "${current_tag}..HEAD")

    # Extract current version numbers
    local version=${current_tag#v}
    local major minor patch
    IFS='.' read -r major minor patch <<< "${version}"

    # Calculate new version
    if [[ ${major_bump} == true ]]; then
        echo "v$((major + 1)).0.0"
    elif [[ ${minor_bump} == true ]]; then
        echo "v${major}.$((minor + 1)).0"
    elif [[ ${patch_bump} == true ]]; then
        echo "v${major}.${minor}.$((patch + 1))"
    else
        # No changes detected, suggest current version
        echo "${current_tag}"
    fi
}

#######################
# Main execution flow #
#######################
main() {
    # Get and display current tag
    current_tag=$(get_current_tag)
    echo "Current tag: ${current_tag}"

    # Show commit history and suggest version
    show_commits_since_tag "${current_tag}"
    suggested_tag=$(suggest_version "${current_tag}")
    echo -e "\nCurrent tag is ${current_tag}"
    echo -e "Suggested tag is ${suggested_tag} (based on conventional commits)"
    echo -n "Enter new tag [default: ${suggested_tag}]: "
    read -r new_tag
    new_tag=${new_tag:-${suggested_tag}}

    # Validate tag format and version
    if validate_tag_format "${new_tag}" && validate_tag_version "${current_tag}" "${new_tag}"; then
        create_tag "${new_tag}"
    else
        exit 1
    fi
}

# Execute main function
main
