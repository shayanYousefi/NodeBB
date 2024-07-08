FROM node:lts as build

ENV NODE_ENV=production \
    DAEMON=false \ 
    SILENT=false

# Install corepack to allow usage of other package managers
RUN corepack enable

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive \
    apt-get -y --no-install-recommends install \
    tini

RUN mkdir -p /usr/src/app \
    && chown node:node -R /usr/src/app

COPY --chown=node:node . /usr/src/app/

# Removing unnecessary files for us
RUN find . -mindepth 1 -maxdepth 1 -name '.*' ! -name '.' ! -name '..' -exec bash -c 'echo "Deleting {}"; rm -rf {}' \;

RUN mkdir -p  /opt/config/ \
    && chown node:node -R /opt/config

USER node

WORKDIR /usr/src/app/

RUN mkdir -p /usr/src/app/logs/

# TODO: Have docker-compose use environment variables to create files like setup.json and config.json.
# COPY --from=hairyhenderson/gomplate:stable /gomplate /usr/local/bin/gomplate

# Prepage package.json
RUN cp /usr/src/app/install/package.json /usr/src/app/

EXPOSE 4567

# Utilising tini as our init system within the Docker container for graceful start-up and termination.
# Tini serves as an uncomplicated init system, adept at managing the reaping of zombie processes and forwarding signals.
# This approach is crucial to circumvent issues with unmanaged subprocesses and signal handling in containerised environments.
# By integrating tini, we enhance the reliability and stability of our Docker containers.
# Ensures smooth start-up and shutdown processes, and reliable, safe handling of signal processing.
ENTRYPOINT ["tini", "--", "/usr/src/app/install/docker/entrypoint.sh"]