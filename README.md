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

kubectl -n kube-system describe pod coredns
>remove the line that says "loop" 

```
# wait to see the pods restart themselves
watch kubectl get pods --all-namespaces
```

