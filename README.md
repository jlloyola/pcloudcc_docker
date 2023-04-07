# pcloudcc_docker
<p>
<a href="https://github.com/jlloyola/pcloudcc_docker/actions"><img alt="Actions Status" src="https://github.com/jlloyola/pcloudcc_docker/actions/workflows/docker-image.yml/badge.svg"></a>
<a href="https://hub.docker.com/r/jloyola/pcloudcc"><img alt="Docker pulls" src="https://img.shields.io/docker/pulls/jloyola/pcloudcc"></a>
<a href="https://github.com/jlloyola/pcloudcc_docker/blob/main/LICENSE"><img alt="License: GPL-3.0" src="https://img.shields.io/github/license/jlloyola/pcloudcc_docker"></a>
</p>

This repo defines a Dockerfile to build the
[pcloud console client](https://github.com/pcloudcom/console-client)
from source and run it inside a container.  

The container exposes your pcloud drive in a location of your
choice. It runs using non-root `uid`:`gid` to properly handle
file permissions and allow seamless file transfers between the host, the container, and pcloud.  
This image includes PR [#163](https://github.com/pcloudcom/console-client/pull/163)
to enable one-time password multi-factor authentication.

## Setup instructions
It is recommended to use a compose file to simplify setup.  
Make sure you have docker installed. Refer to https://docs.docker.com/engine/install/

### 1. Obtain your user and group ID
You can get them from the command line. For example
```
% id -u
1000
% id -g
1000
```
### 2. Create a `.env` file
Enter the relevant information for your setup:
| Variable           | Purpose                                    | Sample Value          |
|----------------    |--------------------------------------------|-----------------------|
|PCLOUD_IMAGE        |Image version                               |jloyola/pcloudcc:latest|
|PCLOUD_DRIVE        |Host directory where pcloud will be mounted |/home/user/pCloudDrive |
|PCLOUD_USERNAME     |Your pcloud username                        |example@example.com    |
|PCLOUD_UID          |Your host user id (obtained above)          |1000                   |
|PCLOUD_GID          |Your host group id (obtained above)         |1000                   |
|PCLOUD_SAVE_PASSWORD|Save password in cache volume               |1                      |

Example `.env` file:  
```
PCLOUD_IMAGE=jloyola/pcloudcc:latest
PCLOUD_DRIVE=/home/user/pCloudDrive
PCLOUD_USERNAME=example@example.com
PCLOUD_UID=1000
PCLOUD_GID=1000
PCLOUD_SAVE_PASSWORD=1
```
### 3. Create the pcloud directory on the host
```
mkdir -p <PCLOUD_DRIVE>
```
`<PCLOUD_DRIVE>` corresponds to the same directory you specified in the `.env`
This step guarantees the directory permissions for the pcloud mount point
match your `uid:gid`. Otherwise, Docker will create the folder, and the
folder will be given 'root' permissions, which then causes the Docker container to fail upon startup with the following error message:
```
ROOT level privileges prohibited!
```
### 4. Initial run
Copy the [compose.yml](https://github.com/jlloyola/pcloudcc_docker/blob/main/compose.yml)
file from this repo and place it in the same location as
your `.env` file
You will need to login the initial run.
```
% docker compose up -d
[+] Running 1/0
 ⠿ Container pcloudcc_docker-pcloud-1
```
Attach to the container to enter your password (and MFA code if enabled).  
Hit enter after attaching to the container to be prompted for your credentials
```
% docker attach pcloudcc_docker-pcloud-1
Down: Everything Downloaded| Up: Everything Uploaded, status is LOGIN_REQUIRED
Please, enter password
logging in
Down: Everything Downloaded| Up: Everything Uploaded, status is CONNECTING
Down: Everything Downloaded| Up: Everything Uploaded, status is TFA_REQUIRED
Please enter 2fa code
123456
Down: Everything Downloaded| Up: Everything Uploaded, status is CONNECTING
Down: Everything Downloaded| Up: Everything Uploaded, status is SCANNING
Down: Everything Downloaded| Up: Everything Uploaded, status is READY
```
### 5. Access your pcloud drive
You can now access your pcloud drive from your host machine
at the location specified in your `.env` file.

## Troubleshooting
When stopping the container, the mount point can get stuck.  
Run the following command to fix it
```
% fusermount -uz <PCLOUD_DRIVE>
```
`<PCLOUD_DRIVE>` corresponds to the same directory you specified in the `.env`.  
See https://stackoverflow.com/a/25986155
## Acknowledgments
The code in this repo was inspired by the work from:
* zcalusic: https://github.com/zcalusic/dockerfiles/tree/master/pcloud
* abraunegg: https://github.com/abraunegg/onedrive
