FROM ruby:2.6.3-alpine
COPY . /app
WORKDIR /app
ENV RAILS_ENV production
RUN apk add --update tzdata build-base sqlite-dev nodejs npm yarn \
    && gem update --system \
    && gem update \
    && gem install bundler \
    && bundle install --deployment --without development test \
    # && bundle exec rake assets:precompile \ # not used for api-only rails
    && touch .build-complete
EXPOSE 80
CMD ["bundle", "exec", "rails", "server", "-p", "80"]

