#!/bin/sh
# This script is used to run the backend of the Postzegel application in a local development environment.
# It sets up the environment, and starts the server.
# Usage: ./postzegel-backend.sh {start|stop|destroy|info|logs}
NAMESPACE=postzegel-backend
PERSISTENT_VOLUME_PATH=/Users/martynem/postzegel/volumes

postgresPath="$PERSISTENT_VOLUME_PATH/postgres-postzegel-backend-persistent-volume"

SCRIPT_DIR=$(pwd)

start() {
  cd $SCRIPT_DIR
  echo "Creating path $PERSISTENT_VOLUME_PATH for persistent-volume storage..."
  mkdir -p $PERSISTENT_VOLUME_PATH
  kubectl create namespace $NAMESPACE

  cd ../postgres-postzegel-backend/init_manually_first
  mkdir -p $postgresPath
  cat persistent-volume.yaml | sed 's@$PERSISTENT_VOLUME_PATH@'"$postgresPath"'@g' | kubectl -n $NAMESPACE apply -f -
  kubectl -n $NAMESPACE apply -f persistent-volume-claim.yaml
  cd $SCRIPT_DIR
  cd ../postgres-postzegel-backend
  kubectl -n $NAMESPACE apply -k production

  cd $SCRIPT_DIR

  cd ../app
  kubectl -n $NAMESPACE apply -k staging
}

stop() {
  cd $SCRIPT_DIR
  echo "Stopping the Postzegel backend..."
  cd ../app
  kubectl -n $NAMESPACE delete -k staging
}

stop_db() {
  cd $SCRIPT_DIR
  echo "Stopping persistent objects..."
  cd ../postgres-postzegel-backend
  kubectl -n $NAMESPACE delete -k production
}

destroy() {
  stop_db
  cd $SCRIPT_DIR
  cd ../postgres-postzegel-backend
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
  echo "get statefulsets"
  kubectl -n $NAMESPACE get statefulsets
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
  down)
    stop
    stop_db
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
  namespace)
    echo $NAMESPACE
    ;;
  *)
    echo "Usage: $0 {start|stop|down|destroy|info|logs|namespace}" >&2
    exit 1
    ;;
esac

