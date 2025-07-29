#!/bin/bash

# Exit on any error
set -e

# Prompt for a commit message
read -p ">> Enter commit message: " COMMIT_MSG

echo -e "\n>> Building Hugo site...\n"
hugo

echo -e "\n>> Committing & pushing files to main...\n"
git add .
git commit -m "$COMMIT_MSG" || echo "\n>> Nothing to commit.\n"
git push origin main

echo -e "\n>> Committing & pushing static site to build...\n"
git subtree split --prefix=public -b temp-deploy
git push -f origin temp-deploy:build
git branch -D temp-deploy

echo -e "\n>> Done. Site deployed to build branch.\n"