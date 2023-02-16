#!/bin/bash

echo $JSON_VAR | jq -r 'to_entries[] | .key + "=\"" + (.value|tostring) + "\""' > "config/local_env.yml" && set -o allexport && source config/local_env.yml && set +o allexport

bundle exec rake test_sessions:submit_stale_sessions test_sessions:expire_tests
