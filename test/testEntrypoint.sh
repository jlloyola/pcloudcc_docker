#!/bin/bash
set -eo pipefail

dockerImage=$1

echo "started as $USER"
# Create new test group if running as root inside docker
if [[ "$USER" == "root" ]]; then
  echo "Adding pcloud user"
  groupadd pcloud -g 1000
  useradd -m pcloud -u 1000 -g 1000
  su pcloud -c "./test/testImage.sh $dockerImage"
else
  ./test/testImage.sh $dockerImage
fi
