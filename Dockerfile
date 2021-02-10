ARG ALPINE_VER="3.13"
ARG RUBY_VER="2.7.2"
ARG RUBY_IMAGE="${RUBY_VER}-alpine${ALPINE_VER}"

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

FROM ruby:${RUBY_IMAGE}

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
		python2-dev \
	&& apk add \
	--no-cache \
		git \
		nodejs-current \
		nodejs-npm \
		python2 \
		tzdata \
		yarn \
	\
# install bundle and yarn packages
	\
	&& yarn install --pure-lockfile \
	&& gem install bundler \
	&& bundle install \
	&& yarn bundle \
	&& bundle exec rails assets:precompile \
# cleanup
	\
	&& yarn cache clean \
	&& apk del .build-deps

# ports and start commands
EXPOSE 3000
ENTRYPOINT [ "./docker/entrypoint.sh" ]
CMD [ "start" ]
