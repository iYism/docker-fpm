# Dockerfile - FPM

ARG HOME_DIR=/opt/ruby32
ARG BUILD_DIR=/tmp/.build.ruby


# Build Stage
FROM rockylinux:9 AS builder
LABEL maintainer="iYism <admin@iyism.com>"

# Component versions
ENV RUBY_VERSION  3.4.9

# Set environment variables for the build stage
ARG HOME_DIR\
    BUILD_DIR

# Switching to root to install the required packages
USER root

WORKDIR ${BUILD_DIR}

RUN set -x \
# Install development packages
    && dnf install -y dnf-plugins-core \
    && dnf config-manager --enable devel \
    && dnf install -y make gcc gcc-c++ zlib-devel readline-devel \
        openssl-devel libffi-devel libyaml-devel \
# Install ruby
    && curl -LO --output-dir ${BUILD_DIR} https://cache.ruby-lang.org/pub/ruby/3.2/ruby-${RUBY_VERSION}.tar.gz \
    && tar zxf ruby-${RUBY_VERSION}.tar.gz \
    && cd ruby-${RUBY_VERSION} \
    && ./configure --prefix=${HOME_DIR} --disable-install-doc \
    && make -j`nproc` \
    && make install \
# Clean tmpdata
    && cd ${HOME_DIR} \
    && rm -fr ${BUILD_DIR} \
    && dnf config-manager --disable devel \
    && dnf remove -y make gcc gcc-c++ zlib-devel readline-devel \
        openssl-devel libffi-devel libyaml-devel \
    && dnf clean all


# Runtime Stage
FROM rockylinux:9-minimal

# Component versions
ENV FPM_VERSION  1.17.0

# Set environment variables for the runtime stage
ARG HOME_DIR

COPY --from=builder ${HOME_DIR} ${HOME_DIR}

# Add custom compiled binaries to the PATH
ENV PATH=$HOME_DIR/bin:$PATH

RUN set -x \
# Install fpm
    && gem install fpm -v ${FPM_VERSION} --no-document \
# Install required packages
    && microdnf install -y rpm-build \
    && microdnf clean all

CMD ["fpm", "-v"]
