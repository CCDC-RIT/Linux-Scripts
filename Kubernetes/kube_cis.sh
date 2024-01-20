#!/bin/bash

echo "1.1.1 -- Ensure that the API server pod specification file permissions are \
set to 600 or more restrictive"
chmod 600 /etc/kubernetes/manifests/kube-apiserver.yaml

echo "1.1.2 -- Ensure that the API server pod specification file ownership is set \
to root:root"
chown root:root /etc/kubernetes/manifests/kube-apiserver.yaml

echo "1.1.3 -- Ensure that the controller manager pod specification file \
permissions are set to 600 or more restrictive"
chmod 600 /etc/kubernetes/manifests/kube-controller-manager.yaml

echo "1.1.4 -- Ensure that the controller manager pod specification file ownership \
is set to root:root"
chown root:root /etc/kubernetes/manifests/kube-controller-manager.yaml

echo "1.1.5 -- Ensure that the scheduler pod specification file permissions \
are set to 600 or more restrictive"
chmod 600 /etc/kubernetes/manifests/kube-scheduler.yaml

echo "1.1.6 -- Ensure that the scheduler pod specification file ownership is set \
to root:root"
chown root:root /etc/kubernetes/manifests/kube-scheduler.yaml

echo "1.1.7 -- Ensure that the etcd pod specification file permissions are set \
to 600 or more restrictive"
chmod 600 /etc/kubernetes/manifests/etcd.yaml

echo "1.1.8 -- Ensure tha tthe etcd pod specification file ownership is set to \
root:root"
chown root:root /etc/kubernetes/manifests/etcd.yaml

echo "1.1.9 -- Ensure that the Container Network Interface (CNI) permissions \ 
are set to 600 or more restrictive"

# Flannel CNI
chmod 600 /etc/kube-flannel/net-conf.json

echo "1.1.10 -- Ensure that the Container Network Interface (CNI) file ownership \
is set to root:root"

# Flannel CNI
chown root:root /etc/kube-flannel/net-conf.json

echo "1.1.11 -- Ensure that the etcd data directory permissions are set to 700 \
or more restrictive"

ETCD=$(ps -ef | grep etcd)
chmod 700 $ETCD

echo "1.1.12 -- Ensure that the etcd data directory ownership is set to etcd:etcd"

ETCD=$(ps -ef | grep etcd)
chown etcd:etcd $ETCD

echo "1.1.13 -- Ensure that the admin.conf file permissions are set to 600"
chmod 600 /etc/kubernetes/admin.conf

echo "1.1.14 -- Ensure that the admin.conf file ownership is set to root:root"
chown root:root /etc/kubernetes/admin.conf

echo "1.1.15 -- Ensure that the scheduler.conf file permissions are set to 600 \
or more restrictive"
chmod 600 /etc/kubernetes/scheduler.conf

echo "1.1.16 -- Ensure that the scheduler.conf file ownership is set to root:root"
chown root:root /etc/kubernetes/scheduler.conf

echo "1.1.17 -- Ensure that the controller-manager.conf file permissions are set \
to 600 or more restrictive"
chmod 600 /etc/kubernetes/controller-manager.conf

echo "1.1.18 -- Ensure that the controller-manager.conf file ownership is set to \
root:root"
chown root:root /etc/kubernetes/controller-manager.conf

echo "1.1.19 -- Ensure that the Kubernetes PKI directory and file ownership is \
set to root:root"
chown -R root:root /etc/kubernetes/pki/

echo "1.1.20 -- Ensure that the Kubernetes PKI certificate file permissions are \
set to 600 or more restrictive"
chmod -R 600 /etc/kubernetes/pki/*.crt

echo "1.1.21 -- Ensure that the Kubernetes PKI key file permissions are set to 600"
chmod -R 600 /etc/kubernetes/pki/*.key

echo "1.2.1, 1.2.3, 1.2.6, 1.2.7, 1.2.8, 1.2.9, 1.2.10, 1.2.11, 1.2.12, 1.2.13, \
1.2.14, 1.2.15, 1.2.16, 1.2.17, 1.2.18, 1.2.19, 1.2.20, 1.2.21, 1.2.22"
