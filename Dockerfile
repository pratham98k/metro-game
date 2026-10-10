# Flutter's Linux toolchain runs under Docker Desktop's amd64 emulation on M-series Macs.
FROM ubuntu:24.04 AS sdk
ARG FLUTTER_VERSION=3.35.7
ENV DEBIAN_FRONTEND=noninteractive \
    PATH="/opt/flutter/bin:/opt/flutter/bin/cache/dart-sdk/bin:${PATH}" \
    PUB_CACHE=/opt/pub-cache
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl git unzip xz-utils libglu1-mesa \
    && rm -rf /var/lib/apt/lists/*
RUN git clone --depth 1 --branch ${FLUTTER_VERSION} https://github.com/flutter/flutter.git /opt/flutter \
    && flutter config --no-analytics --enable-web \
    && flutter precache --web
WORKDIR /app
COPY pubspec.* ./
RUN flutter pub get
COPY . .

FROM sdk AS test
CMD ["sh", "-c", "dart format --output=none --set-exit-if-changed lib test && flutter analyze && flutter test --coverage"]

FROM sdk AS build
RUN flutter build web --release --no-web-resources-cdn

FROM nginxinc/nginx-unprivileged:1.28-alpine AS web
COPY docker/nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/build/web /usr/share/nginx/html
EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s \
    CMD wget -q -O /dev/null http://127.0.0.1:8080/health || exit 1
