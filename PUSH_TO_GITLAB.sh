#!/bin/bash

# Push the repository to GitLab
# Make sure you have SSH access configured first

echo "Pushing Fetcha to GitLab..."
git remote set-url origin git@gitlab.com:mstrslv/fetcha.git
git push -u origin main

echo "Done! Repository is now backed up to GitLab."