#!/bin/bash

echo -e "\033[0;32mDeploying updates to GitHub...\033[0m"

# Pull project before build
cd public
git checkout main
git pull origin main
cd ..

# Build the project.
hugo -t PaperMod

# Go To Public folder
cd public
git add .

# Commit changes.
msg="rebuilding site `date`"
if [ $# -eq 1 ]
  then msg="$1"
fi
git commit -m "$msg"

# Push source and build repos.
git push origin main

# Come Back up to the Project Root
cd ..


# blog 저장소 Commit & Push
git add .

msg="rebuilding site `date`"
if [ $# -eq 1 ]
  then msg="$1"
fi
git commit -m "$msg"

git push origin master
