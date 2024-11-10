echo "\n📦 Initializing Kubernetes cluster...\n"

minikube start --cpus 2 --memory 4g --driver docker --profile comma

echo "\n📦 Deploying MySQL-Account..."

kubectl apply -f services/mysql-account.yml
kubectl apply -f services/mysql-diary.yml
kubectl apply -f services/mysql-psychology.yml


sleep 5

echo "⌛ Waiting for MySQL-Account to be deployed..."

while [ $(kubectl get pod -l db=comma-mysql-account | wc -l) -eq 0 ] ; do
  sleep 5
done

echo "⌛ Waiting for MySQL-Diary to be deployed..."

while [ $(kubectl get pod -l db=comma-mysql-diary | wc -l) -eq 0 ] ; do
  sleep 5
done

echo "⌛ Waiting for MySQL-Psychology to be deployed..."

while [ $(kubectl get pod -l db=comma-mysql-psychology | wc -l) -eq 0 ] ; do
  sleep 5
done

echo "⌛ Waiting for MySQL-Account to be ready..."

kubectl wait \
  --for=condition=ready pod \
  --selector=db=comma-mysql-account \
  --timeout=180s

echo "⌛ Waiting for MySQL-Diary to be ready..."

kubectl wait \
  --for=condition=ready pod \
  --selector=db=comma-mysql-diary \
  --timeout=180s

echo "⌛ Waiting for MySQL-Psychology to be ready..."

kubectl wait \
  --for=condition=ready pod \
  --selector=db=comma-mysql-psychology \
  --timeout=180s