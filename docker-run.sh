docker stop dcache
docker rm dcache

docker run -d -it \
-p 8088:8086 \
--env-file=dcache.env \
-v /home/cloud/kekim/source/dcache/dcache/cache:/app/dcache/mounted \
--name dcache \
dcache:0.2
