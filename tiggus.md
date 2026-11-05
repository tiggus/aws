# information

## kubernetes

> https://github.com/cert-manager/cert-manager/issues/870

```sh
# install the issuer
# fixes the cloudwatch errors

kubectl get crd | grep certmanager

kubectl apply -f https://raw.githubusercontent.com/cert-manager/aws-privateca-issuer/main/config/crd/bases/awspca.cert-manager.io_awspcaclusterissuers.yaml
kubectl apply -f https://raw.githubusercontent.com/cert-manager/aws-privateca-issuer/main/config/crd/bases/awspca.cert-manager.io_awspcaissuers.yaml

# if needed delete first

kubectl delete crd awspcaclusterissuers.awspca.cert-manager.io
kubectl delete crd awspcaissuers.awspca.cert-manager.io
```
