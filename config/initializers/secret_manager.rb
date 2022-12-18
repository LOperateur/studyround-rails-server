secret_name = "JSON_VAR"
secret_json = ENV[secret_name]

if secret_json
  secret_hash = JSON.parse(secret_json)
  secret_hash.each_pair do |key, value|
    ENV[key.to_s] = value
  end
end
