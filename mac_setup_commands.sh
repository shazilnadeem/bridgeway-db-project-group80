#!/bin/bash

# cmd 1: creating the cluster with p=ort mapping
kind create cluster --config kind-config.yaml --name bridgeway-cluster


# IMPORTANT: confirm that PROJECT/src/Bridgeway.ConsoleApp/ConsoleFactory.cs contains this exact connection string:
# "Server=localhost,1433;Database=BridgewayDB;User Id=sa;Password=YourStrong!Password123;TrustServerCertificate=True;"

# cmd 2: creating the db password secret
kubectl create secret generic mssql-secret --from-literal=SA_PASSWORD="YourStrong!Password123"

# cmd 3: creating persistent storage (PV and PVC)
kubectl apply -f sql-storage.yaml

# cmd 4: deploying SQL Server
kubectl apply -f sql-deployment.yaml

# cmd 5: verifying pods are running
kubectl get pods

# comand to simulate failure by deleting a pod if u want to check like in my video
# kubectl delete pod <pod-name>