#!/bin/bash

DELETED_OPEN_CNC=0

REBUILD_MAIN_SERVICE=0
REBUILD_TSN_SERVICE=0
REBUILD_MONITOR_SERVICE=0
REBUILD_ONOS_CONFIG=0
REBUILD_ONOS_TOPO=0
REBUILD_ADAPTER=0

# Take in arguments for namespace to deploy and directory where all repos are
while getopts n:d: option
do 
    case "${option}" in
        n) namespace=${OPTARG};;
		d) DIR=${OPTARG};;
    esac
done

# Function to exit script
exitScript () {
	echo "Exiting..."
	exit
}

# If user doesn't provide namespace in arguments prompt it and exit
if [ -z "$namespace" ]; then
	echo "No namespace specified"
	exitScript
fi

# If user doesn't provide directory in arguments prompt it and exit
if [ -z "$DIR" ]; then
	echo "No directory specified"
	exitScript
fi

###################### REMOVE PODS FROM NAMESPACE ######################

############ OPEN-CNC ############
# Find open-cnc chart if deployed
chartName=`helm -n "$namespace" list |
	grep ^open-cnc |
	cut -f1 |
	xargs`

if [ -n "$chartName" ]; then
	echo -n -e "Delete $chartName from namespace \"$namespace\"? (Y/N)\n"
	read ans
	if [ "$ans" == "yes" ] || [ "$ans" == "y" ] || [ "$ans" == "Y" ] || [ "$ans" == "Yes" ] || [ "$ans" == "YES" ]; then
		DELETED_OPEN_CNC=1

		# Delete open-cnc chart
		helm -n "$namespace" delete "$chartName"
	fi
else
	DELETED_OPEN_CNC=1
fi

####################### REMOVE OLD DOCKER IMAGES #######################

################## OPEN-CNC ##################
# If deleted remove all images
if [ $DELETED_OPEN_CNC -eq 1 ]; then
	echo -n -e "Rebuild docker image: monitor-service? (Y/N)\n"
	read ans
	if [ "$ans" == "yes" ] || [ "$ans" == "y" ] || [ "$ans" == "Y" ] || [ "$ans" == "Yes" ] || [ "$ans" == "YES" ]; then
		REBUILD_MONITOR_SERVICE=1

		# Get ID of monitor-service image and delete it, if the image does not exist, do nothing
		docker images --format="{{.Repository}} {{.ID}}" |
			grep monitor-service |
			cut -d ' ' -f2 |
			xargs -r docker rmi
	fi

	echo -n -e "Rebuild docker image: main-service? (Y/N)\n"
	read ans
	if [ "$ans" == "yes" ] || [ "$ans" == "y" ] || [ "$ans" == "Y" ] || [ "$ans" == "Yes" ] || [ "$ans" == "YES" ]; then
		REBUILD_MAIN_SERVICE=1

		# Get ID of main-service image and delete it, if the image does not exist, do nothing
		docker images --format="{{.Repository}} {{.ID}}" |
			grep main-service |
			cut -d ' ' -f2 |
			xargs -r docker rmi
	fi

	echo -n -e "Rebuild docker image: tsn-service? (Y/N)\n"
	read ans
	if [ "$ans" == "yes" ] || [ "$ans" == "y" ] || [ "$ans" == "Y" ] || [ "$ans" == "Yes" ] || [ "$ans" == "YES" ]; then	
		REBUILD_TSN_SERVICE=1

		# Get ID of tsn-service image and delete it, if the image does not exist, do nothing
		docker images --format="{{.Repository}} {{.ID}}" |
			grep tsn-service |
			cut -d ' ' -f2 |
			xargs -r docker rmi
	fi

	echo -n -e "Rebuild docker image: onos-config? (Y/N)\n"
	read ans
	if [ "$ans" == "yes" ] || [ "$ans" == "y" ] || [ "$ans" == "Y" ] || [ "$ans" == "Yes" ] || [ "$ans" == "YES" ]; then
		REBUILD_ONOS_CONFIG=1

		# Get ID of onos-config image and delete it, if the image does not exist, do nothing
		docker images --format="{{.Repository}} {{.ID}}" |
			grep onos-config |
			cut -d ' ' -f2 |
			xargs -r docker rmi
	fi

	echo -n -e "Rebuild docker image: onos-topo? (Y/N)\n"
	read ans
	if [ "$ans" == "yes" ] || [ "$ans" == "y" ] || [ "$ans" == "Y" ] || [ "$ans" == "Yes" ] || [ "$ans" == "YES" ]; then
		REBUILD_ONOS_TOPO=1

		# Get ID of onos-topo image and delete it, if the image does not exist, do nothing
		docker images --format="{{.Repository}} {{.ID}}" |
			grep onos-topo |
			cut -d ' ' -f2 |
			xargs -r docker rmi
	fi

	echo -n -e "Rebuild docker image: gnmi-netconf-adapter? (Y/N)\n"
	read ans
	if [ "$ans" == "yes" ] || [ "$ans" == "y" ] || [ "$ans" == "Y" ] || [ "$ans" == "Yes" ] || [ "$ans" == "YES" ]; then
		REBUILD_ADAPTER=1

		# Get ID of gnmi-netconf-adapter image and delete it, if the image does not exist, do nothing
		docker images --format="{{.Repository}} {{.ID}}" |
			grep gnmi-netconf-adapter |
			cut -d ' ' -f2 |
			xargs -r docker rmi
	fi
fi

######################## BUILD NEW DOCKER IMAGES #######################

################## OPEN-CNC ##################
# If deleted rebuild all images
if [ $DELETED_OPEN_CNC -eq 1 ]; then

	######### MONITOR-SERVICE ########
	if [ $REBUILD_MONITOR_SERVICE -eq 1 ]; then
		# Go to the directory of monitor-service and build it
		cd "${DIR}opencnc_monitor-service"

		# Start processes in background and supress all output from it
		make deploy > /dev/null 2>&1 &
		PROC_MONITOR_DEPLOY=$!

		make kind > /dev/null 2>&1 &
		PROC_MONITOR_KIND=$!
	fi

	########## MAIN-SERVICE ##########
	if [ $REBUILD_MAIN_SERVICE -eq 1 ]; then
		# Go to the directory of main-service and build it
		cd "${DIR}opencnc_main-service"

		# Start processes in background and supress all output from it
		make deploy > /dev/null 2>&1 &
		PROC_MAIN_DEPLOY=$!

		make kind > /dev/null 2>&1 &
		PROC_MAIN_KIND=$!
	fi

	########### TSN-SERVICE ##########
	if [ $REBUILD_TSN_SERVICE -eq 1 ]; then
		# Go to the directory of tsn-service and build it
		cd "${DIR}opencnc_tsn-service"

		# Start processes in background and supress all output from it
		make deploy > /dev/null 2>&1 &
		PROC_TSN_DEPLOY=$!

		make kind > /dev/null 2>&1 &
		PROC_TSN_KIND=$!
	fi

	########### ONOS-CONFIG ##########
	if [ $REBUILD_ONOS_CONFIG -eq 1 ]; then
		# Go to the directory of onos-config and build it
		cd "${DIR}config-subsystem"

		# Start process in background and supress all output from it
		make kind > /dev/null 2>&1 &
		PROC_CONFIG_KIND=$!
	fi

	########### ONOS-TOPO ##########
	if [ $REBUILD_ONOS_TOPO -eq 1 ]; then
		# Go to the directory of onos-topo and build it
		cd "${DIR}topology-subsystem"

		# Start process in background and supress all output from it
		make kind > /dev/null 2>&1 &
		PROC_TOPO_KIND=$!
	fi

	##### GNMI-NETCONF-ADAPTER #####
	if [ $REBUILD_ADAPTER -eq 1 ]; then
		# Go to the directory of gnmi-netconf-adapter and build it
		cd "${DIR}opencnc_gnmi-netconf-adapter"

		# Start process in background and supress all output from it
		make kind > /dev/null 2>&1 &
		PROC_ADAPTER_KIND=$!
	fi

	if [ $REBUILD_MONITOR_SERVICE -eq 1 ] || [ $REBUILD_MAIN_SERVICE -eq 1 ] || [ $REBUILD_TSN_SERVICE -eq 1 ] || [ $REBUILD_ONOS_CONFIG -eq 1 ] || [ $REBUILD_ONOS_TOPO -eq 1 ] || [ $REBUILD_ADAPTER -eq 1 ]; then
		# Wait until all images has been built and pushed to cluster
		echo "Building and pushing required images for open-cnc..."
		wait
		echo "Done building and pushing required images for open-cnc!"
	fi
fi

########################## DEPLOY NEW CHART(S) #########################

############ OPEN-CNC ############
# If the user removed onos-umbrella, check if they want to install it again
if [ $DELETED_OPEN_CNC -eq 1 ]; then
	# Check if user want to install open-cnc chart
	echo -n -e "Install open-cnc in namespace \"$namespace\"? (Y/N)\n"
	read ans
	if [ "$ans" == "yes" ] || [ "$ans" == "y" ] || [ "$ans" == "Y" ] || [ "$ans" == "Yes" ] || [ "$ans" == "YES" ]; then
		# Install open-cnc chart
		helm -n "$namespace" install open-cnc "${DIR}opencnc_demo/open-cnc"
	fi
fi

echo "Done!"