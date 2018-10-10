# stop on error
$ErrorActionPreference = "Stop"

# Invoke-WebRequest -useb https://raw.githubusercontent.com/HealthCatalyst/dos.install/master/developer/installelasticsearch.ps1 | iex;

Write-Output "starting version 1.2"

$dockername = "fabric.docker.elasticsearch"

docker volume create --name esdata

docker stop $dockername
docker rm $dockername
docker pull healthcatalyst/$dockername

docker run --rm -d -p 9200:9200 -p 9300:9300 -e "discovery.type=single-node" --name $dockername -t healthcatalyst/$dockername

Write-Output "Sleeping for 10s"
Start-Sleep -s 10

# echo "Checking ElasticSearch"
# Invoke-WebRequest "http://localhost:9200/_cat/health"

Write-Output "You can verify ElasticSearch by running:"
Write-Output "curl http://localhost:9200" 

$dockername = "fabric.docker.kibana"

docker stop $dockername
docker rm $dockername
docker pull healthcatalyst/$dockername

$ipForElasticSearch = docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' fabric.docker.elasticsearch
Write-Output "ip for elasticsearch: $ipForElasticSearch"
if([string]::IsNullOrWhiteSpace($ipForElasticSearch))
{
    exit 1
}

docker run --rm -d -p 5601:5601 --add-host elasticsearch:$ipForElasticSearch --name $dockername -t healthcatalyst/$dockername


