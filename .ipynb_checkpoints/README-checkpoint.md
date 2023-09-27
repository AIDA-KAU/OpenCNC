This repository is a microservice of the tool OpenCNC. OpenCNC is a unit that automatically manages the elements of a Time Sensitive Network (TSN) according to the specification presented in the IEEE 801.2Q standard and its relevant amendments.

This repository is the best starting point with OpenCNC. It contains links to the rest of its microservices, installation guide, a deployment script as well as the needed dependencies.

# Brief introduction of OpenCNC

OpenCNC is an implementation of the Control plane for TSN networks that orchestrates and manages the operations in the forwarding plane. The term management entails more than configuring
the network. It includes:
* Calculating the configuration of the TSN switches and the end stations.
* Loading and retrieving the configuration to/from the TSN switches automatically depending on the current state and target state of the network.
* Discovering the switches and retrieving their capabilities.
* Maintaining a global view of the topology and the available resources.
* Handling network events in order to maintain a desired state.
* Monitoring of performance key values for network analysis.

OpenCNC is designed as a micro-service based system. In total, it has the following micro-services, each micro-service is implemented in a different repository to allow easier use, extension and maintenance of the tool:
* Main service
* TSN service
* policing service (not implemented yet)
* Monitoring interface
* Monitor service
* Topology service
* Config service
* gnmi to Netconf adapter
* Onos plugin (not implemented yet)

an overview of the OpenCNC target architecture is presented in the following Figure:
<img src="./images/arch.png">


# OpenCNC_demo
This microservice is used to run all the other microservices that are part of the Open Centralized Network Configurator (OpenCNC).

All of the helm charts for deploying the different services that OpenCNC consists of, and the models that are used in OpenCNC is contained in this repository. This repository is responsible for anything related to the deployment of OpenCNC such as, when opening new ports for services, adding new services, or changing access rights to k/v stores.

## TODO
Make the script for deploying cleaner.

Make shell scripts that use kubectl in order to make testing and logging easier since each pod name is hashed.

Install OpenCNC is a production environment using k8s instead of Kind.

## Problems
Docker images do not disappear after a rebuild.

## Modules

### grpc service implementation
To enable grpc ports between microservices, they must first be added in deployment and service yaml files under each service respectively, i.e:
\opencnc_demo\tsn-service\templates\deployment.yaml
\opencnc_demo\tsn-service\templates\service.yaml.

Under deployment.yaml the path to ports is spec/spec/ports where “- name” and “containerPort” should be added.
Under deployment.yaml the path to ports is spec/ports where “-name” and “port” should be added.

Finalize by running the command “helm dep build” inside opencnc_demo/open-cnc.

### Models

#### Adding
When adding a model to OpenCNC, a new directory should be created for the helm chart of the new model. The directory could be generated with helm or an already existing model directory could be copied. Firstly, one must test compiling the yang files using ygot. If that is successful, the model should work with OpenCNC.

If the model has been added the command “helm dep build” should be executed inside opencnc_demo/open-cnc to rebuild the charts used when deploying OpenCNC.

When OpenCNC has been deployed in the cluster, the models can be seen using the command “kubectl -n open-cnc get models”, if the model is not there, something has gone wrong when adding it (if no models show up, try redeploying OpenCNC).

#### Using
The models should be stored in the k/v store, they are stored from the config-subsystem repository. The exact URNs and in what k/v store they are stored, should potentially be changed, and therefore, is not specified here. The code where the models is stored in the k/v store, is at “config-subsystem/pkg/modelregistry/modelregistry.go line 345”, and at “config-subsystem/pkg/store/deviceModel/deviceModel.go”.


## Dependencies
To run OpenCNC's services, one need to first install the following:
- Docker
- the programming language go
	- Must have at least version 1.17 (e.g. `sudo snap install go --channel=1.18/stable --classic`)
- helm
- kind
- Kubernetes

## Setup OpenCNC
Run these commands in order:
1. `$ kind create cluster`
2. `$ cd ~`
3. `$ mkdir .kube`
4. `$ kind get kubeconfig > ~/.kube/config`
    * If it lacks permission, run the following
        * `$ touch config`
        * `$ chmod 777 .kube/config`
5. `$ export KUBECONFIG=~/.kube/config`
    * If running it for the first time:
        * `$ helm repo add cord https://charts.opencord.org`
        * `$ helm repo add atomix https://charts.atomix.io`
        * `$ helm repo add onosproject https://charts.onosproject.org`
        * `$ helm repo update`
6. `$ kubectl create namespace open-cnc`
7. `$ helm install -n kube-system atomix-controller atomix/atomix-controller --version 0.6.9`
8. `$ helm install -n kube-system atomix-raft-storage atomix/atomix-raft-storage --version 0.1.26`
9. `$ helm install -n kube-system onos-operator onosproject/onos-operator --version 0.4.13`
10. `$ helm -n open-cnc install onos-umbrella onosproject/onos-umbrella`


## Deploy OpenCNC
- Start the kind control plane
- Then run the following to:
    - Deploy/install cnc
      -  `$ ./opencnc_demo/deploy.sh -n open-cnc -d <path to directory with all microservices>`
	- press Y to rename namespace
        -  Press “Y” for each service that should be rebuilt
- End with Y to deploy OpenCNC with its microservices
    - Show deployed pods
        - `$ kubectl -n open-cnc get pods`
    - Show logging for a pod
        - `$ kubectl logs -f -n open-cnc pod/<name of pod> <container if necessary>`

### Possible issues and solutions
If problem to deploy/install cnc, the following can help:

- If one run the code on windows with wsl, one might need to convert the file type:
    - `$ dos2unix opencnc_demo/deploy.sh`
- One might need to make the file executable
    - `$ chmod +x opencnc_demo/deploy.sh`
- If the script fails to install a micro service, it will not show an error message, and instead run with an older version. To check that has not happened, run “make kind” manually for a microservice (while in its directory) to check if it can install it successfully.
