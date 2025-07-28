#!/bin/bash

# Exit on any error
set -e

# Prompt for a commit message
read -p "Enter commit message: " COMMIT_MSG

echo ">> Building Hugo site..."
hugo

echo ">> Committing site build..."
git add -- . ':!/public'
git commit -m "$COMMIT_MSG" || echo "Nothing to commit."
git push

echo ">> Pushing public/ folder to build branch..."
git subtree push --prefix=public origin build

echo ">> Done. Site deployed to build branch."