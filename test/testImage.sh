#!/bin/bash
set -eo pipefail

# Helper function to compare test ouput
function compareTestStrings() {
  if [[ "$2" == "$3" ]]; then
    echo "Check $1 PASSED"
    rm $4
  else
    echo "$1 FAILED"
    echo "Expected: $2"
    echo "Received: $3"
    exit 1
  fi
}

dockerImage=$1

echo "Testing ${dockerImage}"

if ! docker inspect "${dockerImage}" &> /dev/null; then
    echo $'image does not exist!'
    false
fi

# Test run metadata
testTimestamp=`date +%Y%m%d%H%M%S`
imageNameStr=$(sed -r 's#[:/\.]#_#g' <<<"$dockerImage")
testId="${imageNameStr}_${testTimestamp}"
echo "test ID: ${testId}"
echo "Running as $USER"

# Define test attributes and create env file
USER_ID=`id -u`
USER_GROUP=`id -g`
DRIVE_SRC_MOUNT=${HOME}/${testId}
DRIVE_DST_MOUNT=/pCloudDrive
ENV_FILE=./.test_env

cat >${ENV_FILE} << EOL
TEST_IMAGE=${dockerImage}
PCLOUD_DRIVE=${DRIVE_SRC_MOUNT}
PCLOUD_USERNAME=${PCLOUD_USERNAME}
PCLOUD_UID=${USER_ID}
PCLOUD_GID=${USER_GROUP}
EOL

# Create the source mount directory if needed
test -d ${DRIVE_SRC_MOUNT} || mkdir -p ${DRIVE_SRC_MOUNT}
echo `ls -ld ${DRIVE_SRC_MOUNT}`
# Start the test container
docker compose -f ./test/docker-compose.yml \
    --env-file ${ENV_FILE} \
    -p ${testId} \
    up --detach --wait

# Extract the ID of the test container
containerId=`docker container ls -f name=${testId} --format "{{.Names}}"`

# Wait until the container is ready
MAX_WAIT_TIME=10
WAITED=0
while [ $WAITED -lt $MAX_WAIT_TIME ] && ! docker logs $containerId | grep -q "READY"
do
  echo "Waiting for container to be ready..."
  sleep 1
  WAITED=$((WAITED+1))
done

if [ $WAITED -ge $MAX_WAIT_TIME ]; then
  echo "Container did not become ready within $MAX_WAIT_TIME seconds"
  exit 1
fi

echo "-----------------------------------------------------"
echo " Check read access from container"
echo "-----------------------------------------------------"
set -x
testStr="test2container"
testFile=${DRIVE_SRC_MOUNT}/${testId}_${testStr}
touch ${testFile}
echo "${testStr}" > ${testFile}
outFile=${DRIVE_DST_MOUNT}/${testId}_${testStr}

testOut=`docker exec -u ${USER_ID}:${USER_GROUP} ${containerId} cat ${outFile}`
ls -al $testFile

compareTestStrings "container read" "${testStr}" "${testOut}" "${testFile}"

echo "-----------------------------------------------------"
echo " Check write access from container"
echo "-----------------------------------------------------"
testStr="container2test"
testFile=${DRIVE_DST_MOUNT}/${testId}_${testStr}
outFile=${DRIVE_SRC_MOUNT}/${testId}_${testStr}

docker exec -u ${USER_ID}:${USER_GROUP} ${containerId} bash -c "touch ${testFile} && echo ${testStr} > ${testFile}"
testOut=`cat ${outFile}`
ls -al $outFile

compareTestStrings "container write" "${testStr}" "${testOut}" "${outFile}"

docker compose -f ./test/docker-compose.yml \
    --env-file ${ENV_FILE} \
    -p ${testId} \
    down
