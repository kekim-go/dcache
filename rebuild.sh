docker rm -f dcache
docker image rm dcache:0.2
docker build -t dcache:0.2 .
