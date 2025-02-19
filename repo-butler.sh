#!/bin/bash
#
# Usage:
#   ./clean_workflow.sh [options]
#
# Options:
#   -A, --auto-commit   Automatically commit the removal without prompting.
#   -P, --auto-push   Automatically push the changes after a commit without prompting.
#   -v, --verbose       Enable verbose logging (displays additional details).
#   -S, --sign          Sign commits using your configured GPG key.
#   -h, --help          Display this help and exit.
#


# Defaults
auto_commit=false
auto_push=false
verbose=false
sign_commits=false

show_help() {
    cat << EOF
Usage: ${0##*/} [options]

This script processes all remote branches containing "WI-0" in their name.
For each branch, it removes the .github/workflows directory (if present) and 
either automatically commits the removal (with -A/--auto-commit) and/or automatically
pushes the removal (with -P/--auto-push) or prompts you to confirm the commit and push.

Options:
  -A, --auto-commit   Automatically commit the removal without prompting.
  -P, --auto-push   Automatically push the changes after a commit without prompting.
  -v, --verbose       Enable verbose logging (displays additional details).
  -S, --sign          Sign commits using your configured GPG key.
  -h, --help          Display this help and exit.

EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -A|--auto-commit)
      auto_commit=true
      shift
      ;;
    -P|--auto-push)
      auto_push=true
      shift
      ;;
    -v|--verbose)
      verbose=true
      shift
      ;;
    -S|--sign)
      sign_commits=true
      shift
      ;;
    -h|--help)
      show_help
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      show_help
      exit 1
      ;;
  esac
done

log_verbose() {
  if $verbose; then
    echo "[VERBOSE] $1"
  fi
}

echo "Fetching all remote branches..."
git fetch --all

if [ -d ".github/workflows" ]; then
    untracked_workflows=$(git status --porcelain .github/workflows | grep '^??')
    if [ -n "$untracked_workflows" ]; then
        echo "WARNING: The following untracked files in .github/workflows might be overwritten by checkout:"
        echo "$untracked_workflows"
        read -p "Do you want to remove these untracked files using 'git clean -fd .github/workflows'? [y/N] " clean_answer
        if [[ "$clean_answer" =~ ^[Yy]$ ]]; then
            git clean -fd .github/workflows
        else
            echo "Please move or remove the above files manually before running the script."
            exit 1
        fi
    fi
fi

for remote_branch in $(git branch -r | grep "origin/.*WI-0" | sed 's/ *origin\///'); do
    echo "============================================="
    echo "Processing branch: $remote_branch"
    
    log_verbose "Checking out branch $remote_branch from origin/$remote_branch"
    git checkout -B "$remote_branch" "origin/$remote_branch" || { echo "Failed to checkout $remote_branch"; continue; }
    
    if [ -d ".github/workflows" ]; then
        echo "Stage: Found .github/workflows directory. Removing it..."
        log_verbose "Running: git rm -r --cached .github/workflows"
        git rm -r --cached .github/workflows
        
        if ! git diff --cached --quiet; then
            log_verbose "Staged changes:"
            if $verbose; then
              git status --short
            fi

            commit_cmd="git commit"
            if $sign_commits; then
              commit_cmd+=" -S"
            fi
            commit_cmd+=" -m \"Remove .github/workflows directory from branch $remote_branch\""

            if $auto_commit; then
                echo "Stage: Auto-committing removal in branch $remote_branch..."
                log_verbose "Running: $commit_cmd"
                eval "$commit_cmd"
                
                 if $auto_push; then
                    echo "Stage: Auto-pushing branch $remote_branch to remote..."
                    git push origin "$remote_branch"
                else
                    read -p "Do you want to push this commit to the remote branch? [y/N] " push_answer
                    if [[ "$push_answer" =~ ^[Yy]$ ]]; then
                        echo "Stage: Pushing branch $remote_branch to remote..."
                        git push origin "$remote_branch"
                    else
                        echo "Stage: Push skipped for branch $remote_branch."
                    fi
                 fi   
            else
                read -p "Do you want to commit these changes? [y/N] " commit_answer
                if [[ "$commit_answer" =~ ^[Yy]$ ]]; then
                    echo "Stage: Committing removal in branch $remote_branch..."
                    log_verbose "Running: $commit_cmd"
                    eval "$commit_cmd"
                    
                    if $auto_push; then
                      echo "Stage: Auto-pushing branch $remote_branch to remote..."
                      git push origin "$remote_branch"
                    else
                      read -p "Do you want to push this commit to the remote branch? [y/N] " push_answer
                      if [[ "$push_answer" =~ ^[Yy]$ ]]; then
                         echo "Stage: Pushing branch $remote_branch to remote..."
                         git push origin "$remote_branch"
                      else
                         echo "Stage: Push skipped for branch $remote_branch."
                      fi
                    fi
                else
                    echo "Stage: Commit skipped for branch $remote_branch. Resetting staged changes..."
                    git reset HEAD .github/workflows
                    continue
                fi
            fi
        else
            echo "Stage: No changes to commit in branch $remote_branch."
        fi
    else
        echo "Stage: .github/workflows directory does not exist in branch $remote_branch. Skipping."
    fi
    git clean -fd .github/workflows
done

echo "============================================="
read -p "Do you want to switch back to your main branch? [y/N] " main_answer
if [[ "$main_answer" =~ ^[Yy]$ ]]; then
    echo "Stage: Checking out main branch..."
    git checkout main
    echo "Switched to main."
fi

echo "Script completed."