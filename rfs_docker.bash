XAUTH=/tmp/.docker.xauth
CONTAINER_NAME="rfs"
WORKSPACE_DIR=~/rfs_ws
IMAGE_NAME=osrf/ros:humble-desktop
USER_NAME=root

echo "Welcome to the Robotics From Scratch!"
if [ ! -f $XAUTH ]; then
    if [ ! -z "$xauth_list" ]; then
        echo $xauth_list | xauth -f $XAUTH nmerge -
    else
        touch $XAUTH
    fi
    chmod a+r $XAUTH
fi

if [ "$(docker ps -aq -f name=${CONTAINER_NAME})" ]; then
    if [ "$(docker ps -aq -f status=exited -f name=${CONTAINER_NAME})" ]; then
        # cleanup
        docker start ${CONTAINER_NAME}
    fi
    if [ -z "$CMD" ]; then
        docker exec -it --user $USER_NAME ${CONTAINER_NAME} bash
    else
        docker exec -it --user $USER_NAME ${CONTAINER_NAME} bash -c "$CMD"
    fi
else

if [ -n "$DISPLAY" ]; then
	# give docker root user X11 permissions
	sudo xhost +si:localuser:root
	
	# enable SSH X11 forwarding inside container (https://stackoverflow.com/q/48235040)
	XAUTH=/tmp/.docker.xauth
	xauth nlist $DISPLAY | sed -e 's/^..../ffff/' | xauth -f $XAUTH nmerge -
	chmod 777 $XAUTH

	DISPLAY_DEVICE="-e DISPLAY=$DISPLAY -v /tmp/.X11-unix/:/tmp/.X11-unix -v $XAUTH:$XAUTH -e XAUTHORITY=$XAUTH"
fi

docker run -it \
        --volume=${WORKSPACE_DIR}:${WORKSPACE_DIR}:rw \
        --env="DISPLAY=$DISPLAY" \
        --env="QT_X11_NO_MITSHM=1" \
        --env="XAUTHORITY=$XAUTH" \
        --ipc="host" \
        --volume="$XAUTH:$XAUTH" \
        --volume="/etc/localtime:/etc/localtime:ro" \
        --volume="/dev/input:/dev/input" \
        --privileged \
        --name=${CONTAINER_NAME} \
        -p 8181:8181 \
        -p 9090:9090 \
        -p 3883:3883 \
        --workdir=${WORKSPACE_DIR} \
        ${IMAGE_NAME}
fi
