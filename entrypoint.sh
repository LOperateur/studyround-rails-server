#!/bin/bash

echo $JSON_VAR | jq -r 'to_entries[] | .key + "=\"" + (.value|tostring) + "\""' > "config/local_env.yml" && set -o allexport && source config/local_env.yml && set +o allexport

bundle exec rake db:migrate

if [[ $? -eq 0 ]] ; then
  echo -e "\n== Failed to migrate. Running setup first. ==\n"
  bundle exec rails db:setup
fi

bundle exec puma -C config/puma.rb staging -b tcp://0.0.0.0:3000
