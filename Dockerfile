FROM --platform=linux/amd64 clojure:temurin-17-lein

# Install essential tooling
RUN apt update
RUN apt install --no-install-recommends -yy curl unzip build-essential zlib1g-dev

# Download and configure GraalVM
WORKDIR /opt
ARG GRAAL_VERSION="22.3.1"
ENV GRAAL_VERSION="$GRAAL_VERSION"
ENV GRAAL_HOME="/opt/graalvm-ce-java17-$GRAAL_VERSION"
RUN curl -sLO https://github.com/graalvm/graalvm-ce-builds/releases/download/vm-$GRAAL_VERSION/graalvm-ce-java17-linux-amd64-$GRAAL_VERSION.tar.gz
RUN tar -xzf graalvm-ce-java17-linux-amd64-$GRAAL_VERSION.tar.gz
RUN $GRAAL_HOME/bin/gu install native-image

ENV JAVA_HOME="$GRAAL_HOME/bin"
ENV PATH="$JAVA_HOME:$PATH"
