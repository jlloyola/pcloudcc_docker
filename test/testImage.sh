#!/bin/bash
set -eo pipefail

# Helper function to compare test ouput
function compareTestStrings() {
  if [[ "$2" == "$3" ]]; then
    echo "Check $1 PASSED"
    return 0
  else
    echo "$1 FAILED"
    echo "Expected: $2"
    echo "Received: $3"
    return 1
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
imageNameStr=$(sed -r 's#[:/]#_#g' <<<"$dockerImage")
testId="${imageNameStr}_${testTimestamp}"
echo "test ID: ${testId}"

# Define test attributes and create env file
USER_ID=`id -u`
USER_GROUP=`id -g`
DRIVE_SRC_MOUNT=${HOME}/pCloudDrive
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

# Start the test container
docker compose -f ./test/docker-compose.yml \
    --env-file ${ENV_FILE} \
    -p ${testId} \
    up --detach --wait
sleep 10

# Extract the ID of the test container
containerId=`docker container ls -f name=${testId} --format "{{.Names}}"`

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

compareTestStrings "container read" "${testStr}" "${testOut}"
if [[ $? -ne 0 ]] ; then
    exit 1
fi


echo "-----------------------------------------------------"
echo " Check write access from container"
echo "-----------------------------------------------------"
testStr="container2test"
testFile=${DRIVE_DST_MOUNT}/${testId}_${testStr}
outFile=${DRIVE_SRC_MOUNT}/${testId}_${testStr}

docker exec -u ${USER_ID}:${USER_GROUP} ${containerId} bash -c "touch ${testFile} && echo ${testStr} > ${testFile}"
testOut=`cat ${outFile}`
ls -al $outFile

compareTestStrings "container write" "${testStr}" "${testOut}"
if [[ $? -ne 0 ]] ; then
    exit 1
fi
sleep 10
docker compose -f ./test/docker-compose.yml \
    --env-file ${ENV_FILE} \
    -p ${testId} \
    down
