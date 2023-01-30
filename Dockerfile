FROM ruby:2.7.1

RUN apt-get update && apt-get install -y nodejs && apt-get install -y jq
WORKDIR /app
COPY ./Gemfile* ./
RUN bundle install
COPY ./ ./

ENV JSON_VAR=$JSON_VAR
ENV APP=$APP

ENTRYPOINT ["./entrypoint.sh"]

EXPOSE 3000
