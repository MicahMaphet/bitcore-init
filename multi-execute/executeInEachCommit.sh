#!/bin/bash

# testEachCommit - Checkout each of the last N commits and run a command
# Usage: ./testEachCommit <number> -- <command>
# Example: ./testEachCommit 5 -- npm test

# Check if we have at least 3 arguments (script, number, --)
if [ $# -lt 3 ]; then
    echo "Usage: $0 <number> -- <command>"
    echo "Example: $0 5 -- npm test"
    exit 1
fi

# Extract the number of commits
num_commits=$1

# Verify it's a number
if ! [[ "$num_commits" =~ ^[0-9]+$ ]]; then
    echo "Error: First argument must be a number"
    exit 1
fi

# Verify the second argument is --
if [ "$2" != "--" ]; then
    echo "Error: Second argument must be --"
    exit 1
fi

# Shift to get the command (everything after --)
shift 2
command="$@"

# Verify we have a command
if [ -z "$command" ]; then
    echo "Error: No command provided after --"
    exit 1
fi

# Get the current branch to return to it later
original_branch=$(git rev-parse --abbrev-ref HEAD)

# Get the list of the last N commit hashes
commits=$(git log --oneline -n "$num_commits" --pretty=format:"%H")

# Convert to array
mapfile -t commit_array <<< "$commits"

# Reverse array so we process from oldest to newest
IFS=$'\n' sorted_commits=($(printf '%s\n' "${commit_array[@]}" | tac))

echo "Testing the last $num_commits commits..."
echo "Command to run: $command"
echo "---"

failed_commits=()
passed_commits=()

# Iterate through each commit
for commit in "${sorted_commits[@]}"; do
    commit_short=$(git rev-parse --short "$commit")
    commit_msg=$(git log --format=%B -n 1 "$commit" | head -1)
    
    echo ""
    echo "Checking out commit: $commit_short - $commit_msg"
    
    # Checkout the commit
    if ! git checkout "$commit" > /dev/null 2>&1; then
        echo "✗ Failed to checkout $commit_short"
        failed_commits+=("$commit_short")
        continue
    fi
    
    # Run the command
    echo "Running: $command"
    if eval "$command"; then
        echo "✓ Command succeeded on $commit_short"
        passed_commits+=("$commit_short")
    else
        echo "✗ Command failed on $commit_short"
        failed_commits+=("$commit_short")
    fi
done

# Return to original branch
echo ""
echo "---"
echo "Returning to original branch: $original_branch"
git checkout "$original_branch" > /dev/null 2>&1

# Print summary
echo ""
echo "Summary:"
echo "  Passed: ${#passed_commits[@]}"
echo "  Failed: ${#failed_commits[@]}"

if [ ${#failed_commits[@]} -gt 0 ]; then
    echo ""
    echo "Failed commits:"
    for commit in "${failed_commits[@]}"; do
        echo "  - $commit"
    done
    exit 1
fi

exit 0
