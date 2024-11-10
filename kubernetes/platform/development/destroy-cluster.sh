echo "🏴️ Destroying Kubernetes cluster..."

minikube stop --profile comma

minikube delete --profile comma

echo "🏴️ Cluster destroyed"