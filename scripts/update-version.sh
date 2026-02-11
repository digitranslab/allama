#!/bin/bash

usage() {
    echo "Usage: $0 [options] [new_version]"
    echo "Options:"
    echo "  --major      # Increment major version (1.2.3 -> 2.0.0)"
    echo "  --minor      # Increment minor version (1.2.3 -> 1.3.0)"
    echo "Examples:"
    echo "  $0           # Automatically increment patch version"
    echo "  $0 --major   # Increment major version"
    echo "  $0 --minor   # Increment minor version"
    echo "  $0 1.0.1     # Set specific version"
    exit 1
}

INIT_FILE="allama/__init__.py"
if [ ! -f "$INIT_FILE" ]; then
    echo "Error: Cannot find $INIT_FILE"
    exit 1
fi

CURRENT_VERSION=$(grep -E "__version__ = \"[0-9]+\.[0-9]+\.[0-9]+\"" "$INIT_FILE" | grep -Eo "[0-9]+\.[0-9]+\.[0-9]+")
if [ -z "$CURRENT_VERSION" ]; then
    echo "Error: Could not extract version from $INIT_FILE"
    exit 1
fi

# Determine new version
if [ "$#" -eq 0 ]; then
    IFS='.' read -r major minor patch <<< "$CURRENT_VERSION"
    NEW_VERSION="${major}.${minor}.$((patch + 1))"
    echo "No version specified. Incrementing patch version to $NEW_VERSION"
elif [ "$#" -eq 1 ]; then
    case $1 in
        --major)
            IFS='.' read -r major minor patch <<< "$CURRENT_VERSION"
            NEW_VERSION="$((major + 1)).0.0"
            echo "Incrementing major version to $NEW_VERSION"
            ;;
        --minor)
            IFS='.' read -r major minor patch <<< "$CURRENT_VERSION"
            NEW_VERSION="${major}.$((minor + 1)).0"
            echo "Incrementing minor version to $NEW_VERSION"
            ;;
        --help|-h)
            usage
            ;;
        *)
            NEW_VERSION=$1
            ;;
    esac
else
    usage
fi

# Validate semver format
if ! [[ $NEW_VERSION =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Error: Version must be in semver format (e.g., 1.0.0)"
    exit 1
fi

# Files to update
FILES=(
    "allama/__init__.py"
    "packages/allama-registry/allama_registry/__init__.py"
    "docker-compose.yml"
    "docs/tutorials/updating.mdx"
    "docs/self-hosting/deployment-options/docker-compose.mdx"
    "docs/quickstart/install.mdx"
    "docs/self-hosting/updating.mdx"
    "CONTRIBUTING.md"
    ".github/ISSUE_TEMPLATE/bug_report.md"
)

update_version() {
    local file=$1

    if [ ! -f "$file" ]; then
        echo "Warning: File not found - $file"
        return
    fi

    echo "Updating $file..."
    if [[ "$(uname)" == "Darwin" ]]; then
        sed -i '' -E "s/$CURRENT_VERSION/$NEW_VERSION/g" "$file" && \
        sed -i '' -E "s/\/blob\/[0-9]+\.[0-9]+\.[0-9]+\//\/blob\/$NEW_VERSION\//g" "$file" && \
        sed -i '' -E "s/\`[0-9]+\.[0-9]+\.[0-9]+\`/\`$NEW_VERSION\`/g" "$file" && \
        echo "  Updated $file" || echo "  Failed to update $file"
    else
        sed -i -E "s/$CURRENT_VERSION/$NEW_VERSION/g" "$file" && \
        sed -i -E "s/\/blob\/[0-9]+\.[0-9]+\.[0-9]+\//\/blob\/$NEW_VERSION\//g" "$file" && \
        sed -i -E "s/\`[0-9]+\.[0-9]+\.[0-9]+\`/\`$NEW_VERSION\`/g" "$file" && \
        echo "  Updated $file" || echo "  Failed to update $file"
    fi
}

# Main execution
echo "Updating version from $CURRENT_VERSION to $NEW_VERSION"
echo "The following files will be modified:"
echo "----------------------------------------"
for file in "${FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "  - $file"
    else
        echo "  - $file (not found)"
    fi
done
echo "----------------------------------------"

read -p "Do you want to proceed with these changes? (y/N) " -n 1 -r
echo

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Operation cancelled."
    exit 1
fi

echo "Updating..."
for file in "${FILES[@]}"; do
    update_version "$file"
done

echo "----------------------------------------"
echo "Version update complete: $CURRENT_VERSION -> $NEW_VERSION"
echo "Review the changes before committing."

# Copy new version to clipboard
if command -v pbcopy &> /dev/null; then
    echo -n "$NEW_VERSION" | pbcopy
    echo "New version ($NEW_VERSION) copied to clipboard."
elif command -v xclip &> /dev/null; then
    echo -n "$NEW_VERSION" | xclip -selection clipboard
    echo "New version ($NEW_VERSION) copied to clipboard."
elif command -v wl-copy &> /dev/null; then
    echo -n "$NEW_VERSION" | wl-copy
    echo "New version ($NEW_VERSION) copied to clipboard."
fi
