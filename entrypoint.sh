#! /bin/sh

bundle exec rake db:migrate

if [[ $? -eq 0 ]] ; then
  echo -e "\n== Failed to migrate. Running setup first. ==\n"
  bundle exec rails db:setup
fi

exec "$@"