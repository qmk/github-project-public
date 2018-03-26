#!/bin/bash
set -e # exit with nonzero exit code if anything fails

# clear and re-create the out directory
rm -rf www;
rm -f _data.json

mkdir www;

# Install dependencies for projects.js
npm install;

# run projects.js to pull the latest data from github Project
node $PWD/projects.js qmk | \
  "$PWD/bin/jq-linux64" -s 'group_by(.column_name) |
    map( { (.[0].column_name|tostring) : .  }) |
    add |
    {
      "Backend TODO": ."Backend TODO",
      "Frontend TODO": ."Frontend TODO",
      "In Progress": ."In Progress",
      Completed: .Completed
    }' \
  > _data.json

# Need to remove node_modules to avoid a conflict that causes `harp compile` to fail
rm -r node_modules;

# Install Harp globally
npm install -g harp;

# run our compile script, discussed above
harp compile
# go to the out directory and create a *new* Git repo
cd www
git init

# inside this git repo we'll pretend to be a new user
git config user.name "QMK Bot"
git config user.email "hello@qmk.fm"

# The first and only commit to this new Git repo contains all the
# files present with the commit message "Deploy to GitHub Pages".
git add .
git commit -m "Deploy to GitHub Pages"

# Force push from the current repo's dev branch to the remote github.io
# repo's gh-pages branch. (All previous history on the gh-pages branch
# will be lost, since we are overwriting it.) We redirect any output to
# /dev/null to hide any sensitive credential data that might otherwise be exposed.
git push --force --quiet "https://${GH_TOKEN}@${GH_REF}" master:gh-pages > /dev/null 2>&1