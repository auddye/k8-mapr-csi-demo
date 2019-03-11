# k8-mapr-csi-demo
The procedure will walk you through setting up a single kubernetes master/worker node in Virtualbox. Using the CSI driver will will mount a MapR Cluster volume to pods statically and dynamically. 

Using Virtualbox 

# Install kubeadm on Ubuntu
Start with an installation of Ubuntu 16.4 on Virtualbox 

```
sudo su
cd ~
./k8-install.sh
```

***Your coredns pod will likely fail with CrashLoopBackOff error 
Use the following hack around***

```kubectl -n kube-system edit configmap coredns
remove the line that says "loop" ```

```
# wait to see the pods restart themselves
watch kubectl get pods --all-namespaces
```

# Set Up MapR CSI Plugin 
```
git clone https://github.com/mapr/mapr-csi
cd mapr-csi
kubectl create -f deploy/kubernetes/csi-maprkdf-v1.0.0.yaml
watch kubectl get pods --all-namespaces
# wait for the csi-controller-kdf-0 and csi-nodeplugin-kdf to start ```

# Static Provisioning 
Static provisioning involves mounting a volume that already exists on the MapR Cluster to a pod. We will do this with 3 files: 
teststaticpv.yaml
testprovisionerrestsecret.yaml
teststaticpvc.yaml


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
# testprovisionerrestsecret.yaml 
# Copyright (c) 2009 & onwards. MapR Tech, Inc., All rights reserved
# apiVersion: v1
# kind: Secret
# metadata:
#   name: mapr-provisioner-secrets
#   namespace: test-csi
# type: Opaque
# data:
#   MAPR_CLUSTER_USER: bWFwcg==
#   MAPR_CLUSTER_PASSWORD: bWFwcg==
```

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
      
