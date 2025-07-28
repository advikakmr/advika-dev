#!/bin/bash

# Exit on any error
set -e

# Prompt for a commit message
read -p ">> Enter commit message: " COMMIT_MSG

echo ">> Building Hugo site..."
hugo

echo ">> Committing & pushing site to main..."
git add -- . ':!/public'
git commit -m "$COMMIT_MSG" || echo ">> Nothing to commit."
git push

echo ">> Committing & pushing static site to build..."
git push origin --delete build
git subtree push --prefix=public origin build

echo ">> Done. Site deployed to build branch."