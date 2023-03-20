#!/bin/bash -eu

set +H -euo pipefail

PCLOUD_DRIVE_PATH="/pCloudDrive/data"

: ${PCLOUD_UID:=$(stat ${PCLOUD_DRIVE_PATH} -c '%u')}
: ${PCLOUD_GID:=$(stat ${PCLOUD_DRIVE_PATH} -c '%g')}

# Create new group using target GID
if ! pcloud_group="$(getent group "$PCLOUD_GID")"; then
  pcloud_group='pcloud'
  groupadd "${pcloud_group}" -g "$PCLOUD_GID"
else
  pcloud_group=${pcloud_group%%:*}
fi

# Create new user using target UID
if ! pcloud_user="$(getent passwd "$PCLOUD_UID")"; then
  pcloud_user='pcloud'
  useradd -m "${pcloud_user}" -u "$PCLOUD_UID" -g "$PCLOUD_GID"
else
  pcloud_user="${pcloud_user%%:*}"
  usermod -g "${pcloud_group}" "${pcloud_user}"
  grep -qv root <( groups "${pcloud_user}" ) || { echo 'ROOT level privileges prohibited!'; exit 1; }
fi

ARGS=(-m ${PCLOUD_DRIVE_PATH})
echo "Base Args: ${ARGS}"

if [ "${PCLOUD_SAVE_PASSWORD:=0}" == "1" ]; then
  echo "# Adding -s to save password"
  ARGS=(-s ${ARGS[@]})
fi

if [ -n "${PCLOUD_USERNAME:=""}" ]; then
  ARGS=(-u ${PCLOUD_USERNAME} ${ARGS[@]})
fi

echo "# Launching pcloud"
# Only switch user if not running as target uid (ie. Docker)
if [ "$PCLOUD_UID" = "$(id -u)" ]; then
  /usr/bin/pcloudcc "${ARGS[@]}"
else
  mkdir -p ${PCLOUD_DRIVE_PATH}
  chown "${pcloud_user}:${pcloud_group}" ${PCLOUD_DRIVE_PATH}
  exec gosu "${pcloud_user}" /usr/bin/pcloudcc "${ARGS[@]}"
fi