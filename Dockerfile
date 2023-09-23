FROM ruby:2.7.2

RUN apt-get update && apt-get install -y nodejs && apt-get install -y jq
WORKDIR /app
COPY ./Gemfile* ./
RUN bundle install
COPY ./ ./

ENV JSON_VAR=$JSON_VAR

ENTRYPOINT ["./entrypoint.sh"]

EXPOSE 3000
