# Create an insecure Registry Locally
docker run -d -p 5000:5000 --restart=always --name registry registry:2

# Persistent Data for Registry
docker run -d \
  -p 5000:5000 \
  --restart=always \
  --name registry \
  -v /mnt/registry:/var/lib/registry \
  registry:2

# Create self-signed TLS Certs
openssl req \
  -newkey rsa:4096 -nodes -sha256 -keyout certs/domain.key \
  -addext "subjectAltName = DNS:hub-cache" \
  -x509 -days 365 -out certs/domain.crt

# Create a docker network for cache
docker network create cache

# Deploy a pull through cache registry
docker run -d --name hub-cache --net cache --restart unless-stopped \
  -v $PWD/certs:/certs:ro \
  -v $PWD/hub-cache:/var/lib/registry \
  -p 5000:5000 \
  -e REGISTRY_STORAGE_FILESYSTEM_ROOTDIRECTORY=/var/lib/registry \
  -e REGISTRY_PROXY_REMOTEURL=https://registry-1.docker.io \
  -e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/domain.crt \
  -e REGISTRY_HTTP_TLS_KEY=/certs/domain.key \
  registry:2

# Deploy a DIND Image to act as a builder server
docker run -d --name builder --net cache --restart unless-stopped --privileged \
  --mount "type=bind,src=$(pwd)/certs/domain.crt,dst=/etc/docker/certs.d/hub-cache:5000/ca.crt,readonly" \
  docker:dind --registry-mirror https://hub-cache:5000

# Deploy a registry with S3 Storage
docker run -d --name hub-cache --restart unless-stopped \
  -p 5000:5000 \
  -e REGISTRY_STORAGE="s3" \
  -e REGISTRY_STORAGE_S3_ACCESSKEY="" \
  -e REGISTRY_STORAGE_S3_SECRETKEY="" \
  -e REGISTRY_STORAGE_S3_REGION="ap-south-1" \
  -e REGISTRY_STORAGE_S3_BUCKET="docker-local-registry-backup" \
  registry:2