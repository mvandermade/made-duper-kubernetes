#!/bin/sh
# This script is used to run the backend of the Postzegel application in a local development environment.
# It sets up the environment, builds the application, and starts the server.
# Usage: ./postzegel-backend.sh
NAMESPACE=postzegel-backend
PERSISTENT_VOLUME_PATH=/Users/martynem/postzegel/volumes

postgresPath="$PERSISTENT_VOLUME_PATH/postgres"

SCRIPT_DIR=$(pwd)

start() {
  cd $SCRIPT_DIR
  echo "Creating path $PERSISTENT_VOLUME_PATH for pv storage..."
  mkdir -p $PERSISTENT_VOLUME_PATH
  kubectl create namespace $NAMESPACE

  cd ../postgres/init_manually_first
  mkdir -p $postgresPath
  cat persistent-volume.yaml | sed 's@$PERSISTENT_VOLUME_PATH@'"$postgresPath"'@g' | kubectl apply -f -
  kubectl -n $NAMESPACE apply -f persistent-volume-claim.yaml
  cd $SCRIPT_DIR
  cd ../postgres
  kubectl -n $NAMESPACE apply -k production

  cd $SCRIPT_DIR

  cd ../postzegel-backend
  kubectl -n $NAMESPACE apply -k staging
}

stop() {
  cd $SCRIPT_DIR
  echo "Stopping the Postzegel backend..."
  cd ../postzegel-backend
  kubectl -n $NAMESPACE delete -k staging
}

destroy() {
  cd $SCRIPT_DIR
  echo "Stopping persistent objects..."
  cd ../postgres
  kubectl -n $NAMESPACE delete -k production
  cd init_manually_first
  kubectl -n $NAMESPACE delete -f persistent-volume-claim.yaml
  cat persistent-volume.yaml | sed 's@$PERSISTENT_VOLUME_PATH@'"$postgresPath"'@g' | kubectl delete -f -
  cd $SCRIPT_DIR
  echo "Scrapping postgres directory on $postgresPath..."
  rm -rf $postgresPath
  echo "Namespace deletion may take a while... (this is the last step)"
  kubectl -n $NAMESPACE delete namespace $NAMESPACE
}

info() {
  echo "-----------------------------------kubectl ...-----------------------------------"
  echo "get configmaps"
  kubectl -n $NAMESPACE get configmaps
  echo "\n"
  echo "get deployments"
  kubectl -n $NAMESPACE get deployments
  echo "\n"
  echo "get ingress"
  kubectl -n $NAMESPACE get ingress
  echo "\n"
  echo "get pods"
  kubectl -n $NAMESPACE get pods
  echo "\n"
  echo "get nodes"
  kubectl -n $NAMESPACE get nodes
  echo "\n"
  echo "get pv"
  kubectl -n $NAMESPACE get pv
  echo "\n"
  echo "get pvc"
  kubectl -n $NAMESPACE get pvc
  echo "\n"
  echo "get services"
  kubectl -n $NAMESPACE get services
  echo "\n"
  echo "get secrets"
  kubectl -n $NAMESPACE get secrets
  echo "\n"
  echo "-----------------------------------diskspace ...-----------------------------------"
  echo $(du -hs $postgresPath)
}

logs() {
  kubectl -n $NAMESPACE logs deployment/postzegel-backend-deployment $1
}

case "$1" in
  start)
    start
    ;;
  stop)
    stop
    ;;
  destroy)
    stop
    destroy
    ;;
  info)
    info
    ;;
  logs)
    logs $2
    ;;
  *)
    echo "Usage: $0 {start|stop|destroy|info|logs}" >&2
    exit 1
    ;;
esac

