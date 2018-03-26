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
      TODO: .TODO,
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
