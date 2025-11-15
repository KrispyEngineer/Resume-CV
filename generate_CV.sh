#!/bin/bash

set -euo pipefail

# Log all output (stdout + stderr)
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

git checkout main

###########################################
# VENV SETUP
###########################################

# Create venv if not present
if [ ! -d "venv" ]; then
  echo "Creating virtual environment..."
  python3 -m venv venv
fi

# Activate venv
echo "Activating virtual environment..."
source venv/bin/activate

# Ensure pip is upgraded (safe inside venv)
pip install --upgrade pip

# Install dependencies
echo "Installing requirements..."
pip install -r requirements.txt

###########################################
# GENERATE RESUME YAML
###########################################

python3 ./gpt_resume.py

YAML_FILE="Piyush_Patil_CV.yaml"

# Validate YAML exists
if [ ! -f "$YAML_FILE" ]; then
  echo "❌ YAML resume not found: $YAML_FILE"
  exit 1
fi

###########################################
# CREATE BRANCH
###########################################

git checkout -b "$BRANCH_NAME"

###########################################
# RENDER RESUME
###########################################

echo "Rendering resume..."
rendercv render "$YAML_FILE"

###########################################
# COMMIT + PUSH
###########################################

git add -A
git commit -m "$COMPANY_NAME"
git push -u origin "$BRANCH_NAME"

echo "✅ Resume branch for $COMPANY_NAME created and pushed successfully!"
