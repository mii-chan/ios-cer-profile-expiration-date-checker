FROM amazonlinux:latest
MAINTAINER mii-chan <miichan.maple.apps@gmail.com>

RUN yum update -y
RUN yum -y groupinstall "Development tools"
RUN yum -y install openssl-devel zlib-devel
RUN yum -y install wget

# Install Traveling Ruby
RUN mkdir /var/task
RUN wget http://d6r77u77i8pq3.cloudfront.net/releases/traveling-ruby-20150715-2.2.2-linux-x86_64.tar.gz
RUN tar -xvf traveling-ruby-20150715-2.2.2-linux-x86_64.tar.gz -C /var/task

# Install the same version of Ruby as Traveling Ruby (2.2.2)
RUN wget http://cache.ruby-lang.org/pub/ruby/2.2/ruby-2.2.2.tar.gz
RUN tar -xvf ruby-2.2.2.tar.gz
WORKDIR ruby-2.2.2
RUN ./configure && make && make install

# Install bundler (in both local and global environment)
WORKDIR /var/task
RUN ./bin/gem install bundler --no-document
RUN gem install bundler --no-document

# Copy Gemfile
COPY Gemfile /var/task

# Install gems by using GLOBAL bundler (cause header files are not packaged in Traveling Ruby)
RUN bundle install --path vendor/bundle