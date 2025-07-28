#!/bin/bash

# Exit on any error
set -e

# Prompt for a commit message
read -p ">> Enter commit message: " COMMIT_MSG

echo ">> Building Hugo site..."
hugo

echo ">> Committing & pushing files to main..."
git add .
git commit -m "$COMMIT_MSG" || echo ">> Nothing to commit."
git push origin main

echo ">> Committing & pushing static site to build..."
git subtree split --prefix=public -b temp-deploy
git push -f origin temp-deploy:build
git branch -D temp-deploy

echo ">> Done. Site deployed to build branch."