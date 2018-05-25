FROM ruby:2.2.2
MAINTAINER mii-chan <miichan.maple.apps@gmail.com>

# Install Traveling Ruby
RUN mkdir -p /var/task \
    && wget http://d6r77u77i8pq3.cloudfront.net/releases/traveling-ruby-20150715-2.2.2-linux-x86_64.tar.gz \
    && tar -xvf traveling-ruby-20150715-2.2.2-linux-x86_64.tar.gz -C /var/task

# Install bundler (in both local and global environment)
WORKDIR /var/task
RUN ./bin/gem install bundler --no-document \
    && gem install bundler --no-document

# Copy Gemfile
COPY Gemfile /var/task
COPY Gemfile.lock /var/task
COPY .bundle /var/task/.bundle

# Install gems by using GLOBAL bundler (cause header files are not packaged in Traveling Ruby)
RUN bundle install --path vendor/bundle