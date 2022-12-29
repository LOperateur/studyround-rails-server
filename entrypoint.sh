#! /bin/sh

echo $JSON_VAR | jq -r 'to_entries[] | .key + ": \"" + (.value|tostring) + "\""' > "config/local_env.yml" && set -o allexport; . ./config/local_env.yml; set +o allexport

if [[ $APP = 'SESSION-RESULT-JOB' ]] ; then
bundle exec rake test_sessions:submit_stale_sessions test_sessions:expire_tests

elif [[ $APP = 'SIDEKIQ' ]] ; then
bundle exec sidekiq -c 5 -q default -q mailers -v

else
  bundle exec rake db:migrate

  if [[ $? -eq 0 ]] ; then
    echo -e "\n== Failed to migrate. Running setup first. ==\n"
    bundle exec rails db:setup
  fi

  bundle exec puma -C config/puma.rb staging -b tcp://0.0.0.0:3000
fi
