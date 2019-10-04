Properties {
    $k8sns = 'sample-persistent-volume'
    $releaseName = 'mssqlv1'
    $localk8scluster = 'docker-for-desktop'
    $passwordLocalDatabase = 'P@ssw0rd'
}

Task Use-LocalK8sCluster { 
    kubectl config use-context $localk8scluster 
    kubectl config set-context $localk8scluster --namespace=$k8sns
}

Task Ensure-Namespace -depends Use-LocalK8sCluster {
    try {
        kubectl get ns $k8sns > Out-Nul
    }
    catch {
        kubectl create ns $k8sns
    }
}

Task Create-PersistentVolumeClaim {
    kubectl apply -f persistentvolumeclaim.yml
}

Task Create-PersistentVolume {
    kubectl apply -f persistentvolume.yml
}

Task Deploy-DevDatabase -depends Ensure-Namespace, Create-PersistentVolume, Create-PersistentVolumeClaim  {
    Write-Host Deploying develop database...
    helm install --name $releaseName stable/mssql-linux --set acceptEula.value=Y --set edition.value=Developer --set image.repository=mcr.microsoft.com/mssql/server --set image.tag=2019-RC1 --set sapassword=$passwordLocalDatabase --set service.type=LoadBalancer --set service.port=1433 --set persistence.enabled=true --set persistence.existingTransactionLogClaim=data-pv-claim 
}

Task Delete-All {
    helm delete $releaseName --purge
    kubectl delete pvc data-pv-claim
    kubectl delete pv data-pv-volume
    kubectl delete pvc master-pv-claim
    kubectl delete pv master-pv-volume
}

