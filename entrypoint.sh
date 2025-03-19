#!/bin/sh

echo $JSON_VAR | jq -r 'to_entries[] | .key + ": \"" + (.value|tostring) + "\""' > "config/local_env.yml"

bundle exec rake db:migrate

# Check if migration failed
if [[ $? -ne 0 ]]; then
  echo -e "\n== Failed to migrate. Running setup first. ==\n"
  bundle exec rails db:setup
fi

bundle exec puma -C config/puma.rb -b tcp://0.0.0.0:3000
