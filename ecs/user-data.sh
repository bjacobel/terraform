#!/bin/bash
# mark this as belonging to our cluster
echo ECS_CLUSTER=${cluster_name} >> /etc/ecs/ecs.config

# mount NFS
yum install -y nfs-utils
mkdir -p /efs
mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2 \
    ${efs_dns_name}:/ /efs
sudo chown -R 500:500 /efs
sudo chown -R 472:472 /efs/grafana
