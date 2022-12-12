def set_aws_docker_managed_secrets
  secret_name = "JSON_VAR"

  secret_json = ENV[secret_name] || '{}'
  secret_hash = JSON.parse(secret_json)

  ENV['DATABASE_URL'] = secret_hash['DATABASE_URL']
  ENV['FREE_TEST_SESSION_ACCESS_HOURS'] = secret_hash['FREE_TEST_SESSION_ACCESS_HOURS']
  ENV['LANG'] = secret_hash['LANG']
  ENV['RACK_ENV'] = secret_hash['RACK_ENV']
  ENV['RAILS_ASSET_HOST'] = secret_hash['RAILS_ASSET_HOST']
  ENV['RAILS_ENV'] = secret_hash['RAILS_ENV']
  ENV['RAILS_LOG_TO_STDOUT'] = secret_hash['RAILS_LOG_TO_STDOUT']
  ENV['RAILS_MASTER_KEY'] = secret_hash['RAILS_MASTER_KEY']
  ENV['RAILS_SERVE_STATIC_FILES'] = secret_hash['RAILS_SERVE_STATIC_FILES']
  ENV['REDIS_PROVIDER'] = secret_hash['REDIS_PROVIDER']
  ENV['REDIS_TLS_URL'] = secret_hash['REDIS_TLS_URL']
  ENV['REDIS_URL'] = secret_hash['REDIS_URL']
  ENV['SECRET_KEY_BASE'] = secret_hash['SECRET_KEY_BASE']
  ENV['SENDGRID_API_KEY'] = secret_hash['SENDGRID_API_KEY']
  ENV['SENDGRID_PASSWORD'] = secret_hash['SENDGRID_PASSWORD']
  ENV['SENDGRID_USERNAME'] = secret_hash['SENDGRID_USERNAME']
  ENV['TEST_LAG_TIME_SECONDS'] = secret_hash['TEST_LAG_TIME_SECONDS']

end
