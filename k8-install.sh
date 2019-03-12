#!/bin/bash
echo "Reseting K8"

sudo kubeadm reset -f
sleep 4

echo "Turning swap off\n"

swapoff -a

echo "Setting kubeadm pod network cidr"\n
sleep 1
kubeadm init --pod-network-cidr=10.244.0.0/16
sleep 2


echo "Copy new configuration to the regular user"
sleep 3

mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

sleep 2
echo "Setting ENV KUBECONFIG=/etc/kubernetes/admin.conf"
sleep 1
export KUBECONFIG=/etc/kubernetes/admin.conf
sleep 1

echo "Applying Flannel" \n
sleep 1

kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/bc79dd1505b0c8681ece4de4c0d86c5cd2643275/Documentation/kube-flannel.yml
sleep 2

echo "Tainting master node" \n
sleep 1

kubectl taint nodes --all node-role.kubernetes.io/master-

sleep 2


echo "Watch pods starting up" \n
watch kubectl get pods --all-namespaces

exit 0
