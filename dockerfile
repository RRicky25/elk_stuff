# Use a basic Ubuntu image as the base
FROM ubuntu:20.04

# Install required dependencies
RUN apt-get update && apt-get install -y \
    wget \
    curl \
    apt-transport-https \
    openjdk-11-jre-headless \
    gnupg2 \
    lsb-release \
    ca-certificates \
    sudo \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Install Elasticsearch
RUN wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | apt-key add - \
    && sh -c 'echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" > /etc/apt/sources.list.d/elastic-7.x.list' \
    && apt-get update \
    && apt-get install -y elasticsearch

# Install Logstash
RUN apt-get update \
    && apt-get install -y logstash

# Install Kibana
RUN apt-get update \
    && apt-get install -y kibana

# Expose necessary ports
EXPOSE 9200 5601 5044

# Create a user for Elasticsearch and give it the necessary permissions if not already created
RUN getent group elasticsearch || groupadd -r elasticsearch \
    && getent passwd elasticsearch || useradd -r -g elasticsearch elasticsearch \
    && chown -R elasticsearch:elasticsearch /usr/share/elasticsearch /etc/elasticsearch /var/log/elasticsearch /var/lib/elasticsearch

# Ensure the Logstash data directory is writable
RUN chmod -R 777 /usr/share/logstash/data

# Copy configuration files (ensure these files exist in the same directory as the Dockerfile)
COPY ./elasticsearch.yml /etc/elasticsearch/elasticsearch.yml
COPY ./logstash.conf /etc/logstash/conf.d/
COPY ./kibana.yml /etc/kibana/kibana.yml

# Set ownership and permissions for Kibana files and data directory
RUN chown -R elasticsearch:elasticsearch /etc/kibana \
    && chmod -R 755 /etc/kibana \
    && mkdir -p /usr/share/kibana/data \
    && chown -R elasticsearch:elasticsearch /usr/share/kibana/data \
    && chmod -R 755 /usr/share/kibana/data


RUN mkdir -p /logs/testingLogs && chmod -R 755 /logs/testingLogs


ENV LOGSTASH_PATH_SETTINGS=/etc/logstash

# Switch to the non-root user and run services
USER elasticsearch


# Run Elasticsearch, Logstash, Kibana, and Filebeat in the foreground
CMD /usr/share/elasticsearch/bin/elasticsearch -d && \
    /usr/share/logstash/bin/logstash -f /etc/logstash/conf.d/logstash.conf & \
    /usr/share/kibana/bin/kibana -c /etc/kibana/kibana.yml & \
    tail -f /dev/null

# # Run Elasticsearch, Logstash, Kibana, and Filebeat in the foreground
# CMD /usr/share/elasticsearch/bin/elasticsearch -d && \
#     /usr/share/logstash/bin/logstash -f /etc/logstash/conf.d/logstash.conf && \
#     /usr/share/kibana/bin/kibana && \
#     /usr/share/filebeat/bin/filebeat -e && \
#     tail -f /dev/null
