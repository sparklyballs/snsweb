
ARG ALPINE_VER="3.11"
FROM alpine:${ALPINE_VER} as fetch-stage

############## fetch stage ##############

# install fetch packages
RUN \
	apk add --no-cache \
		bash \
		curl \
		git

# set shell
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# set workdir
WORKDIR /app

# fetch version file
RUN \
	set -ex \
	&& curl -o \
	/tmp/version.txt -L \
	"https://raw.githubusercontent.com/sparklyballs/versioning/master/version.txt"

# fetch source code
# hadolint ignore=SC1091
RUN \
	. /tmp/version.txt \
	&& set -ex \
	&& mkdir -p \
		app \
	&& curl -o \
		/tmp/snsweb.tar.gz -L \
		"https://github.com/standardnotes/web/archive/${SNSWEB_COMMIT}.tar.gz" \
	&& tar xf \
		/tmp/snsweb.tar.gz -C \
		/app --strip-components=1

FROM ruby:alpine


# set workdir
WORKDIR /app

# add artifacts from fetch stage
COPY --from=fetch-stage /app /app

# install build packages
RUN \
	apk add \
	--no-cache \
	--virtual .build-deps \
		alpine-sdk \
	&& apk add \
	--no-cache \
		nodejs \
		nodejs-npm \
		tzdata \
	\
	# install bundle and npm packages
	\
	&& bundle install \
	&& npm install \
	&& npm run build \
	\
	# cleanup
	\
	&& apk del .build-deps

# ports and start commands
EXPOSE 3000
ENTRYPOINT [ "./docker/entrypoint" ]
CMD [ "start" ]
