FROM ruby:2.7.1

RUN apt-get update && apt-get install -y nodejs && apt-get install -y jq
WORKDIR /app
COPY ./Gemfile* ./
RUN bundle install
COPY ./ ./
RUN echo $JSON_VAR | jq -r 'to_entries[] | .key + "=\"" + (.value|tostring) + "\""' > "file.txt" && set -a && . ./file.txt && set +a && rm file.txt

ENTRYPOINT ["./entrypoint.sh"]

EXPOSE 3000

CMD ["bundle", "exec", "puma", "-C", "config/puma.rb", "staging", "-b", "tcp://0.0.0.0:3000"]
