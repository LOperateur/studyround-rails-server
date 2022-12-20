#! /bin/sh

echo $JSON_VAR | jq -r 'to_entries[] | .key + "=\"" + (.value|tostring) + "\""' > "file.txt" && set -a && . ./file.txt && set +a && rm file.txt

bundle exec rake db:migrate

if [[ $? -eq 0 ]] ; then
  echo -e "\n== Failed to migrate. Running setup first. ==\n"
  bundle exec rails db:setup
fi

exec "$@"
