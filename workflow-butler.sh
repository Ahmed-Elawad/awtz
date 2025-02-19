#!/bin/bash

ARCHIVE_DIR="archive/workflow-butler"
PER_PAGE=100

read -p "Enter the GitHub Owner (user or organization): " OWNER
read -p "Enter the GitHub Repository Name: " REPO
API_URL="repos/$OWNER/$REPO/actions/runs"
echo "Using API URL: https://api.github.com/$API_URL"
read -p "Proceed with deleting workflow runs for $OWNER/$REPO? (y/N): " CONFIRM

if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
    echo "Deletion aborted."
    exit 1
fi

TIMESTAMP=$(date +%Y%m%d%H%M%S)
ARCHIVE_SUBDIR="$ARCHIVE_DIR/$TIMESTAMP"
mkdir -p "$ARCHIVE_SUBDIR"
echo "Starting bulk deletion of workflow runs for $OWNER/$REPO..."

PAGE=1
while true; do
    printf "Fetching page %d of workflow runs...\r" "$PAGE"
    RESPONSE=$(gh api "$API_URL?per_page=$PER_PAGE&page=$PAGE")
    
    RUN_IDS=$(echo "$RESPONSE" | jq -r '.workflow_runs[].id')
    RUN_URLS=$(echo "$RESPONSE" | jq -r '.workflow_runs[].url')


    if [ -z "$RUN_IDS" ] || [ "$RUN_IDS" == "null" ]; then
        echo "No workflow runs found on page $PAGE. Exiting..."
        break
    fi

    IFS=$'\n'
    RUN_ID_ARRAY=($RUN_IDS)
    RUN_URL_ARRAY=($RUN_URLS)
    unset IFS

    for i in "${!RUN_ID_ARRAY[@]}"; do
        RUN_ID=${RUN_ID_ARRAY[$i]}
        RUN_URL=$(echo "${RUN_URL_ARRAY[$i]}" | sed 's/"//g')

        printf "\rWorklfow %s - DELETING ... " "$RUN_ID"
        ARCHIVE_FILE="$ARCHIVE_SUBDIR/workflow_$RUN_ID.json"
        gh api  "$RUN_URL" > "$ARCHIVE_FILE"
        
        gh api --method DELETE "$API_URL/$RUN_ID" > /dev/null
        printf "\rWorklfow %s - DONE      " "$RUN_ID"
        sleep 0.2
    done
    echo 
    RUN_COUNT=$(echo "$RUN_IDS" | wc -l | tr -d ' ')

    if [ "$RUN_COUNT" -lt "$PER_PAGE" ]; then
        echo "Last page reached. All workflow runs processed."
        break
    fi

    PAGE=$((PAGE + 1))
done

echo "Bulk deletion complete."