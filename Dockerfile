FROM node:lts as build

ENV NODE_ENV=production \
    DAEMON=false \
    SILENT=false

RUN mkdir -p /usr/src/app \
    && chown node:node -R /usr/src/app

WORKDIR /usr/src/app/

COPY . /usr/src/app/

# Install corepack to allow usage of other package managers
RUN corepack enable

# Removing unnecessary files for us
RUN find . -mindepth 1 -maxdepth 1 -name '.*' ! -name '.' ! -name '..' -exec bash -c 'echo "Deleting {}"; rm -rf {}' \;

# Prepage package.json
RUN cp /usr/src/app/install/package.json /usr/src/app/

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive \
    apt-get -y --no-install-recommends install \
        tini

USER node

RUN npm install --omit=dev
    # TODO: generate lockfiles for each package manager
    ## pnpm import \

FROM node:lts-slim AS final

ENV NODE_ENV=production \
    DAEMON=false \
    SILENT=false


RUN mkdir -p /usr/src/app \
    && chown node:node -R /usr/src/app

WORKDIR /usr/src/app/

RUN corepack enable

COPY --from=build /usr/bin/tini /usr/src/app/install/docker/entrypoint.sh /usr/local/bin/

RUN chmod +x /usr/local/bin/entrypoint.sh \
    && chmod +x /usr/local/bin/tini

USER node

RUN mkdir -p /usr/src/app/logs/ /opt/config/

COPY --from=build /usr/src/app/ /usr/src/app/install/docker/setup.json /usr/src/app/


# TODO: Have docker-compose use environment variables to create files like setup.json and config.json.
# COPY --from=hairyhenderson/gomplate:stable /gomplate /usr/local/bin/gomplate

EXPOSE 4567

VOLUME ["/usr/src/app/node_modules", "/usr/src/app/build", "/usr/src/app/public/uploads", "/opt/config/"]

# Utilising tini as our init system within the Docker container for graceful start-up and termination.
# Tini serves as an uncomplicated init system, adept at managing the reaping of zombie processes and forwarding signals.
# This approach is crucial to circumvent issues with unmanaged subprocesses and signal handling in containerised environments.
# By integrating tini, we enhance the reliability and stability of our Docker containers.
# Ensures smooth start-up and shutdown processes, and reliable, safe handling of signal processing.
ENTRYPOINT ["tini", "--", "entrypoint.sh"]