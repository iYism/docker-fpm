# Dockerfile - FPM

ARG HOME_DIR=/opt/ruby34
ARG BUILD_DIR=/tmp/.build.ruby


# Build Stage
FROM rockylinux/rockylinux:10 AS builder
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
    && curl -LO --output-dir ${BUILD_DIR} https://cache.ruby-lang.org/pub/ruby/3.4/ruby-${RUBY_VERSION}.tar.gz \
    && tar zxf ruby-${RUBY_VERSION}.tar.gz \
    && cd ruby-${RUBY_VERSION} \
    && ./configure --prefix=${HOME_DIR} --disable-install-doc \
    && make -j`nproc` \
    && make install


# Runtime Stage
FROM rockylinux/rockylinux:10-minimal

# Component versions
ENV FPM_VERSION  1.17.0

# Set environment variables for the runtime stage
ARG HOME_DIR

COPY --from=builder ${HOME_DIR} ${HOME_DIR}

# Add custom compiled binaries to the PATH
ENV PATH=$HOME_DIR/bin:$PATH

RUN set -x \
# Install required packages
    && microdnf install -y openssl libyaml libffi rpm-build \
    && microdnf clean all \
# Install fpm
    && gem install fpm -v ${FPM_VERSION} --no-document

CMD ["fpm", "-v"]
