FROM google/dart
# RUN apt -y update && apt -y upgrade
WORKDIR /app
COPY pubspec.* /app/
RUN dart pub get
COPY . /app
RUN dart pub get --offline
RUN dart compile exe /app/bin/server.dart -o /app/dcache/dcache

FROM subfuzion/dart-scratch
COPY --from=0 /app/pubspec.yaml /app/pubspec.yaml
COPY --from=0 /app/dcache/dart.png /app/dcache/dart.png
COPY --from=0 /app/dcache/favicon.ico /app/dcache/favicon.ico
COPY --from=0 /app/dcache/index.html /app/dcache/index.html
COPY --from=0 /app/dcache/dcache /app/dcache/dcache
COPY --from=0 /app/dcache/monitor/monitor.md /app/dcache/monitor/monitor.md
WORKDIR /app
EXPOSE 8088
ENTRYPOINT ["/app/dcache/dcache"]
