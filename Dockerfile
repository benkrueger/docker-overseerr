FROM ghcr.io/linuxserver/baseimage-alpine:3.13

# set version label
ARG BUILD_DATE
ARG VERSION
ARG OVERSEERR_VERSION
LABEL build_version="Linuxserver.io version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="nemchik"

# set environment variables
ENV HOME="/config"

RUN \
 echo "**** install build packages ****" && \
 apk add --no-cache --virtual=build-dependencies \
	curl \
	g++ \
	make \
	python3 && \
 echo "**** symlink python3 for compatibility ****" && \
 ln -s /usr/bin/python3 /usr/bin/python && \
 echo "**** install runtime packages ****" && \
 apk add --no-cache \
	yarn && \
 if [ -z ${OVERSEERR_VERSION+x} ]; then \
	OVERSEERR_VERSION=$(curl -sX GET "https://api.github.com/repos/sct/overseerr/releases/latest" \
	| awk '/tag_name/{print $4;exit}' FS='[""]'); \
 fi && \
 export COMMIT_TAG="${OVERSEERR_VERSION}" && \
 curl -o \
	/tmp/overseerr.tar.gz -L \
	"https://github.com/sct/overseerr/archive/${OVERSEERR_VERSION}.tar.gz" && \
 mkdir -p /app/overseerr && \
 tar xzf \
	/tmp/overseerr.tar.gz -C \
	/app/overseerr/ --strip-components=1 && \
 cd /app/overseerr && \
 NODE_OPTIONS=--max_old_space_size=1024 && \
 export NODE_OPTIONS && \
 yarn --frozen-lockfile --network-timeout 1000000 && \
 yarn build && \
 yarn install --production --ignore-scripts --prefer-offline && \
 yarn cache clean && \
 echo "{\"commitTag\": \"${COMMIT_TAG}\"}" > committag.json && \
 rm -rf /app/overseerr/config && \
 ln -s /config /app/overseerr/config && \
 echo "**** cleanup ****" && \
 apk del --purge \
	build-dependencies && \
 rm -rf \
    /root/.cache \
    /tmp/*

# copy local files
COPY root/ /

# ports and volumes
EXPOSE 5055
VOLUME /config