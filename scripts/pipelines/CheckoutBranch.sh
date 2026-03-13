#!/bin/bash
#Srii Seelam 2024-JUN-07- Initial Version

#Variables
#$1 = Branch name

git config user.name $BITBUCKET_USER
git config user.email $BITBUCKET_EMAIL
git remote set-url origin https://$BITBUCKET_USER:$BITBUCKET_PASSWORD@bitbucket.org/$BITBUCKET_PROJECT.git
git fetch
git config remote.origin.fetch "+refs/heads/*:refs/remotes/origin/*"
git remote update
git checkout $1
# for multi-merge scripts, remove any uncommitted changes on the running container
git reset --hard
# make sure current branch is up to date with remote branch
git pull --ff-only