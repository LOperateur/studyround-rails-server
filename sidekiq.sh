#! /bin/sh

echo $JSON_VAR | jq -r 'to_entries[] | .key + ":'" + (.value|tostring) + "'"' > "config/local_env.yml" && set -o allexport; source ./config/local_env.yml; set +o allexport

bundle exec sidekiq -c 5 -q default -q mailers -v
