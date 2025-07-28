#!/bin/bash

# Exit on any error
set -e

# Prompt for a commit message
read -p ">> Enter commit message: " COMMIT_MSG

echo ">> Committing & pushing site build to main..."
git add -- . ':!/public'
git commit -m "$COMMIT_MSG" || echo ">> Nothing to commit."
git push

echo ">> Building Hugo site..."
hugo

echo ">> Commiting % pushing public/ folder to build..."
git switch build
git add .
git commit -m "$COMMIT_MSG" || echo ">> Nothing to commit."
git push
git switch main

echo ">> Done. Site deployed to build branch."