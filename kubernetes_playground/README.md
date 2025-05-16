# Kubernetes playground
For trying out kubernetes using kustomize.

# Check out the scripts
## How
- Install Docker desktop and activate kubernetes
- Navigate to the folder local_dev
- Run the script using bash: `./postzegel-backend.sh start`

## Installation
For ubuntu see the install folder

## Configuration for k8s
k is an alias for kubectl inside the k8s snap package.
See folder install on how to alias kubectl to `k`

## Use kustomize
Kustomize is built in into kubectl.

Navigate into a folder such as `mysql` or `postzegel-backend` and then depending on the folders present:

```
k apply -k staging
k apply -k production
```
To get rid of the kustomization:
```
k delete -k staging
k delete -k production
```

# Local dev environment using docker desktop
