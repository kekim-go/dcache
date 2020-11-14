FROM google/dart
# RUN apt -y update && apt -y upgrade
WORKDIR /app
COPY pubspec.* /app/
RUN dart pub get
COPY . /app
RUN dart pub get --offline
RUN dart compile exe /app/bin/server.dart -o /app/dcache/server

FROM subfuzion/dart-scratch
COPY --from=0 /app/pubspec.yaml /app/pubspec.yaml
COPY --from=0 /app/bin/dart.png /app/dcache/dart.png
COPY --from=0 /app/bin/favicon.ico /app/dcache/favicon.ico
COPY --from=0 /app/bin/index.html /app/dcache/index.html
COPY --from=0 /app/bin/server /app/dcache/server
EXPOSE 8088
ENTRYPOINT ["/app/dcache/server"]
