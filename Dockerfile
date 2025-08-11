FROM ruby:2.7-bullseye

RUN apt-get update && apt-get install -y nodejs && apt-get install -y jq
WORKDIR /app
COPY ./Gemfile* ./
RUN bundle install
COPY ./ ./

RUN chmod +x entrypoint.sh
ENTRYPOINT ["./entrypoint.sh"]

EXPOSE 3000
