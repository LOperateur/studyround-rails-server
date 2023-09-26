#!/bin/sh

echo $JSON_VAR | jq -r 'to_entries[] | .key + ": \"" + (.value|tostring) + "\""' > "config/local_env.yml"

bundle exec rake test_sessions:submit_stale_sessions test_sessions:expire_tests result_sessions:delete_result_sessions guests:cleanup_guest_data
