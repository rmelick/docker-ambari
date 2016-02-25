#!/usr/bin/env bash

# source script functions
source ambari-functions

# clean out old dockers
echo "Removing all old docker containers with prefix: $NODE_PREFIX"
docker rm -f $(docker ps -a --filter="name=$NODE_PREFIX" -q)

# start up containers
CLUSTER_SIZE=3 amb-start-cluster;

AMBARI_SERVER_IP=`docker inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' amb-server`

# wait for ambari server to finish starting up
echo "Waiting for ambari to start (${AMBARI_SERVER_IP}:8080)"
while ! curl --output /dev/null --silent --head --fail http://${AMBARI_SERVER_IP}:8080
	do sleep 2
	echo -n .
done
echo "Ambari successfully started"

# post the cluster blueprint
curl -H "X-Requested-By: ambari" --user admin:admin -XPOST --data-binary @broken-hbase-blueprint.json "http://${AMBARI_SERVER_IP}:8080/api/v1/blueprints/broken-hbase-blueprint"
# confirm that the blueprint was posted successfully
curl -H "X-Requested-By: ambari" --user admin:admin -XGET "http://${AMBARI_SERVER_IP}:8080/api/v1/blueprints/"

sleep 5

# Inject the master variable into the Cluster Def and post it to create the host mapping for the cluster
curl -v -H "X-Requested-By: ambari" --user admin:admin -XPOST --data-binary @broken-hbase-cluster-def.json "http://${AMBARI_SERVER_IP}:8080/api/v1/clusters/broken-hbase-cluster"


