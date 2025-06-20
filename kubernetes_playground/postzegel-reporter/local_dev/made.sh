#!/bin/sh
# This script is used to run the reporter of the Postzegel application in a local development environment.
# It sets up the environment, and starts the reporter.
# Usage: ./made.sh {start|stop|destroy|info|logs}
NAMESPACE=postzegel-reporter
PERSISTENT_VOLUME_PATH=/Users/martynem/postzegel/volumes

postgresPath="$PERSISTENT_VOLUME_PATH/postgres-postzegel-reporter-persistent-volume"
kafkaPath="$PERSISTENT_VOLUME_PATH/kafka-postzegel-reporter-persistent-volume"

SCRIPT_DIR=$(pwd)

start() {
  cd $SCRIPT_DIR
  echo "Creating path $PERSISTENT_VOLUME_PATH for persistent-volume storage..."
  mkdir -p $PERSISTENT_VOLUME_PATH
  kubectl create namespace $NAMESPACE

  # Postgres
  cd $SCRIPT_DIR
  cd ../postgres-postzegel-reporter/init_manually_first
  mkdir -p $postgresPath
  cat persistent-volume.yaml | sed 's@$PERSISTENT_VOLUME_PATH@'"$postgresPath"'@g' | kubectl -n $NAMESPACE apply -f -
  kubectl -n $NAMESPACE apply -f persistent-volume-claim.yaml
  cd $SCRIPT_DIR
  cd ../postgres-postzegel-reporter
  kubectl -n $NAMESPACE apply -k production

  # Kafka
  cd $SCRIPT_DIR
  cd ../kafka-postzegel-reporter/init_manually_first
  mkdir -p $kafkaPath
  cat persistent-volume.yaml | sed 's@$PERSISTENT_VOLUME_PATH@'"$kafkaPath"'@g' | kubectl -n $NAMESPACE apply -f -
  kubectl -n $NAMESPACE apply -f persistent-volume-claim.yaml
  cd $SCRIPT_DIR
  cd ../kafka-postzegel-reporter
  kubectl -n $NAMESPACE apply -k production
  echo "Postgres and Kafka are up and running."
  echo "Starting the Postzegel reporter..."

  cd $SCRIPT_DIR

  cd ../app
  kubectl -n $NAMESPACE apply -k production
}

stop() {
  cd $SCRIPT_DIR
  echo "Stopping the Postzegel reporter... (kafka and postgres will not be stopped)"
  cd ../app
  kubectl -n $NAMESPACE delete -k production
}

stop_db() {
  cd $SCRIPT_DIR
  echo "Stopping postgres objects..."
  cd ../postgres-postzegel-reporter
  kubectl -n $NAMESPACE delete -k production
}

stop_kafka() {
  cd $SCRIPT_DIR
  echo "Stopping kafka objects..."
  cd ../kafka-postzegel-reporter
  kubectl -n $NAMESPACE delete -k production
}

destroy() {
  stop_db
  stop_kafka
  
  # Postgres
  cd $SCRIPT_DIR
  cd ../postgres-postzegel-reporter
  cd init_manually_first
  kubectl -n $NAMESPACE delete -f persistent-volume-claim.yaml
  cat persistent-volume.yaml | sed 's@$PERSISTENT_VOLUME_PATH@'"$postgresPath"'@g' | kubectl delete -f -
  cd $SCRIPT_DIR
  echo "Scrapping postgres directory on $postgresPath..."
  rm -rf $postgresPath

  # Kafka
  cd $SCRIPT_DIR
  cd ../kafka-postzegel-reporter
  cd init_manually_first
  kubectl -n $NAMESPACE delete -f persistent-volume-claim.yaml
  cat persistent-volume.yaml | sed 's@$PERSISTENT_VOLUME_PATH@'"$kafkaPath"'@g' | kubectl delete -f -
  cd $SCRIPT_DIR
  echo "Scrapping kafka directory on $kafkaPath..."
  rm -rf $kafkaPath

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
  kubectl -n $NAMESPACE logs deployment/postzegel-reporter-deployment $1
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
    stop_kafka
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

