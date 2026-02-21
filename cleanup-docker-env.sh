#!/bin/bash
echo 'Cleanup env'
for CONTAINER in $(docker ps -aq)
do
  echo "stopping container" "$CONTAINER"
  docker container ls | grep "$CONTAINER"
  docker stop "$CONTAINER"
done

docker system prune --all --filter until=48h --filter label=project="pos-application" --force
docker system prune --volumes --force

for IMAGE in $(docker volume ls -q --filter dangling=true)
do
  echo "removing image" "$IMAGE"
  docker volume rm "$IMAGE"
done
