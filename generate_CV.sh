#!/bin/bash

set -euo pipefail

# log all output (stdout + stderr)
exec > >(tee -a /tmp/myscript.log) 2>&1
echo "==== Script started at $(date) ===="

cd '/mnt/c/Users/piyus/Desktop/lp3thw/JOB_Switch_AI_CV_generator/Resume-CV'

git fetch --all

echo "Enter the company name:"
while true; do
  read COMPANY_NAME
  # Convert to lowercase, remove spaces and special chars for branch name
  BRANCH_NAME=$(echo "$COMPANY_NAME" | tr '[:upper:]' '[:lower:]' | tr -cd '[:alnum:]-_')
  if git show-ref --verify --quiet "refs/remotes/origin/$BRANCH_NAME"; then
    echo "Branch '$BRANCH_NAME' already exists. Please enter a different company name:"
  else
    break
  fi
done

echo "Creating for $COMPANY_NAME!"

git checkout "main"

# Create venv if not present
if [ ! -d "venv" ]; then
  echo "Creating virtual environment..."
  python3 -m venv venv
fi

source venv/bin/activate

pip install -r requirements.txt

python3 ./gpt_resume.py

# Args: Job ID
YAML_FILE="Piyush_Patil_CV.yaml"

# Convert to lowercase, remove spaces and special chars for branch name
BRANCH_NAME=$(echo "$COMPANY_NAME" | tr '[:upper:]' '[:lower:]' | tr -cd '[:alnum:]-_')

# Check input
if [ -z "$YAML_FILE" ] || [ -z "$COMPANY_NAME" ]; then
  echo "Usage: ./generate_resume.sh \"Company Name and JOB ID\""
  exit 1
fi

# Exit if resume.yaml doesn't exist
if [ ! -f "$YAML_FILE" ]; then
  echo "YAML resume not found at: $YAML_FILE"
  exit 1
fi

# Create and switch to new branch
git checkout -b "$BRANCH_NAME"

# setup
if [ ! -d "venv" ]; then
    python3 -m venv venv
fi

# Generate resume
rendercv render "$YAML_FILE"

# Commit and push
git add -A
git commit -m "$COMPANY_NAME"
git push -u origin "$BRANCH_NAME"

echo "✅ Resume branch for $COMPANY_NAME created and pushed!"


# # delete stale branches 
# for k in $(git branch | sed /\*/d); do 
#   if [ -z "$(git log -1 --since='4 months ago' -s $k)" ]; then
#     git branch -D $k
#     git push origin --delete $k
#   fi
# done