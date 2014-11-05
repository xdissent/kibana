# Kibana 4
#
# Default CMD expects a linked elasticsearch container or env vars:
#   ELASTICSEARCH_PORT_9200_TCP_ADDR
#   ELASTICSEARCH_PORT_9200_TCP_PORT

FROM dockerfile/java:oracle-java7

RUN curl -sL https://deb.nodesource.com/setup | bash -

RUN apt-get install -y nodejs ruby ruby-dev ruby-bundler libssl-dev zip && \
  rm -rf /var/lib/apt/lists/*

RUN npm install -g grunt-cli bower

ADD . /kibana

WORKDIR /kibana

RUN \
  npm install && \
  bower install --allow-root && \
  bundle && \
  cd src/server && bundle

# Download jruby and fix weird grunt error
ENV JENKINS_HOME /dev/null
RUN grunt download_jruby

# Pre-install warbler in jruby
RUN .jruby/bin/jruby -S gem install warbler

# Build jar
RUN grunt build

# Dramatically hack bundler and move on with life
RUN mkdir jar && cd jar && unzip ../build/dist/kibana/lib/kibana.jar
RUN echo "\nrequire 'bundler'\nrequire 'bundler/index'\nrequire 'bundler/remote_specification'\nrequire 'bundler/endpoint_specification'\nrequire 'bundler/dep_proxy'" >> jar/META-INF/init.rb
RUN cd jar && zip ../build/dist/kibana/lib/kibana.jar META-INF/init.rb

CMD ["/bin/sh", "-c", "/kibana/build/dist/kibana/bin/kibana -e http://$ELASTICSEARCH_PORT_9200_TCP_ADDR:$ELASTICSEARCH_PORT_9200_TCP_PORT"]

EXPOSE 5601
