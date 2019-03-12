# k8-mapr-csi-demo
The procedure will walk you through setting up a single kubernetes master/worker node in Virtualbox. Using the CSI driver will will mount a MapR Cluster volume to pods statically and dynamically. 

To reference MapR provided test yamls see here: [mapr-csi github](https://github.com/mapr/mapr-csi.git)
All yamls in this project were sourced from mapr-csi github and updated for local installation purposes. 

Using Virtualbox 

Ubuntu : 
Start with an installation of Ubuntu 16.4 on Virtualbox 
Networking: NAT , Host-only 
CPU: 2 

[MapR Sandbox for Hadoop 6.1](https://mapr.com/docs/61/SandboxHadoop/t_install_sandbox_vbox.html#task_kjv_45t_zs)



# Install kubeadm on Ubuntu



Next Install kubeadm 
Resources: [Creating Cluster Reference](https://kubernetes.io/docs/setup/independent/create-cluster-kubeadm/#pod-network)
[Install kubeadm](https://kubernetes.io/docs/setup/independent/install-kubeadm/)

```
apt-get update && apt-get install -y apt-transport-https curl
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF
apt-get update
apt-get install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl
```


```
sudo su
cd ~
./k8-install.sh
```

Your coredns pod will likely fail with **CrashLoopBackOff** error 
Use the following hack around

```
kubectl -n kube-system edit configmap coredns
```
remove the line that says "loop"


wait to see the pods restart themselves
```
watch kubectl get pods --all-namespaces
```

# Set Up MapR CSI Plugin 

```
git clone https://github.com/mapr/mapr-csi
cd mapr-csi
kubectl create -f deploy/kubernetes/csi-maprkdf-v1.0.0.yaml
watch kubectl get pods --all-namespaces
```
wait for the csi-controller-kdf-0 and csi-nodeplugin-kdf to start

# Static Provisioning 
Static provisioning involves mounting a volume that already exists on the MapR Cluster to a pod. We will do this with 3 files: 
*teststaticpv.yaml
*testprovisionerrestsecret.yaml
*teststaticpvc.yaml


teststaticpv.yaml example: 
```
# Copyright (c) 2009 & onwards. MapR Tech, Inc., All rights reserved
# apiVersion: v1
# kind: PersistentVolume
# metadata:
#   name: test-static-pv
#   namespace: test-csi
# spec:
#   accessModes:
#   - ReadWriteOnce
#   persistentVolumeReclaimPolicy: Delete
#   capacity:
#     storage: 5Gi
#   csi:
#     driver: com.mapr.csi-kdf
#     volumeHandle: test-id
#     volumeAttributes:
#       volumePath: "/static" # Default: "/"
#       cluster: demo.mapr.com
#       cldbHosts: maprdemo
#       securityType: "Unsecure" # Default: Unsecure
```

testprovisionerrestsecret.yaml example: 
```
Copyright (c) 2009 & onwards. MapR Tech, Inc., All rights reserved
apiVersion: v1
kind: Secret
# metadata:
#   name: mapr-provisioner-secrets
#   namespace: test-csi
# type: Opaque
# data:
#   MAPR_CLUSTER_USER: bWFwcg==
#   MAPR_CLUSTER_PASSWORD: bWFwcg==
```

teststaticpvc.yaml
```
# Copyright (c) 2009 & onwards. MapR Tech, Inc., All rights reserved
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: test-static-pvc
  namespace: test-csi
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 5G
```
      
# Create Static Volume on MapR Cluster
On your mapr cluster 
```
maprcli volume create -name static -path /static
```

Use kubectl to create all the services 
```
#start by creating a namespace
kubectl apply -f testnamespace.yaml
# Deploy the secrets which the drivers uses to connect to the MapR cluster 
kubectl create -f testprovisionerrestsecret.yaml
# Create a persistant volume description that matches the volume we created or "/" 
kubectl create -f teststaticpv.yaml
# Bind a persistant volume claim  with a persistant volume
kubectl create -f teststaticpvc.yaml
```

Check that the claims are bound with the following commands 
kubectl get pvc -n test-csi
kubectl get pv -n test-csi

We are now ready to deploy our pod 
```
kubectl create -f teststaticpod.yaml
watch kubectl get pods --all-namespaces
```

Let's test our /static mount point by writing some data to /static/test.dat
 

kubectl exec -it test-static-pod -n test-csi -- dd if=/dev/zero of=/static/test.dat bs=1M count=10
kubectl exec -it test-static-pod -n test-csi -- ls -l /static/test.dat


You can also list the file like this: 
ssh mapr@maprdemo hadoop fs -ls /static/

The data is saved to the persistent volume, so when pods get deleted or restarted there is no affect to the data volume 

```
kubectl delete -f teststaticpod.yaml
```

Check that your volume is in the same state you left it in: 
```
ssh mapr@maprdemo hadoop fs -ls /static/
```

Recreate the pod and write another file to pick up where you left off: 
```
kubectl create -f teststaticpod.yaml
kubectl exec -it test-static-pod2 -n test-csi -- dd if=/dev/zero of=/static/test2.dat bs=1M count=10
```

Clean up to save resources on your machine 
```
kubectl delete -f teststaticpod.yaml
kubectl delete -f teststaticpvc.yaml
kubectl delete -f teststaticpv.yaml
kubectl delete -f testprovisionerrestsecret.yaml
```


# Dynamic Provisioning of a MapR Volume 

Dynamic provisioning means a volume does not already exist on the MapR cluster and by using a storage class and a persistent volume claim the driver will provision the volume for us. 

Will will be using the following yamls for dynamic provisioning: 
*testnamespace.yaml
*testprovisionerrestsecret.yaml
*testunsecurestorageclass.yaml
*testdynamicpvc.yaml
*testdynamicpod.yaml


