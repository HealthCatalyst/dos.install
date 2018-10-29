
# Setup Helm
kubectl --namespace kube-system create serviceaccount tiller
kubectl create clusterrolebinding tiller --clusterrole cluster-admin --serviceaccount=kube-system:tiller

helm init --upgrade --service-account tiller --wait

helm repo update

[string] $package = "nginx"
[string] $ngniximageTag = "0.20.0"

Write-Output "Removing old deployment"
helm del --purge $package

Start-Sleep -Seconds 5

# nginx configuration: https://github.com/helm/charts/tree/master/stable/nginx-ingress#configuration

Write-Verbose "Installing the public nginx load balancer"
helm install stable/nginx-ingress `
    --namespace "kube-system" `
    --name "$package" `
    --set controller.service.type="NodePort" `
    --set controller.service.nodePorts.http=31111 `
    --set controller.service.nodePorts.https=31112 `
    --set controller.image.tag="$ngniximageTag"

helm del --purge heapster-release

helm install stable/heapster --name heapster-release --namespace kube-system --set rbac.create=true --wait

helm del --purge kubernetes-dashboard

helm install stable/kubernetes-dashboard `
    --name kubernetes-dashboard `
    --namespace kube-system `
    --wait

kubectl logs -l "app=kubernetes-dashboard,release=kubernetes-dashboard" -n kube-system

kubectl logs -l "app=nginx-ingress" -n kube-system

kubectl proxy -p 8001

Start-Process -FilePath "http://localhost:8001/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy/#!/login";


