secret_name = "JSON_VAR"
secret_json = ENV[secret_name]

if secret_json
  secret_hash = JSON.parse(secret_json)
  secret_hash.each_pair do |k, v|
    ENV["#{k}"] = v
  end
end
