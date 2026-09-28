# aws-privateca-issuer - installed !


Error from server (NotFound): customresourcedefinitions.apiextensions.k8s.io "awspcaclusterissuers.awspca.cert-manager.io" not found
ERROR: Failed to deploying component aws-privateca-issuer on

   This error means the CRD for the AWS Private CA issuer hasn't been installed in the cluster yet. The operator pod may be running but the CRDs it provides haven't been
   registered.

   Fix — install the CRDs first:

   # Check what version of aws-privateca-issuer you're running
   kubectl get deployment -n cert-manager | grep privateca

   # Install the CRDs directly from the upstream manifest
   kubectl apply -f https://raw.githubusercontent.com/cert-manager/aws-privateca-issuer/main/config/crd/bases/awspca.cert-manager.io_awspcaclusterissuers.yaml
   kubectl apply -f https://raw.githubusercontent.com/cert-manager/aws-privateca-issuer/main/config/crd/bases/awspca.cert-manager.io_awspcaissuers.yaml

   Or if you're deploying via Helm, the CRDs should be bundled — make sure installCRDs is enabled:

   helm upgrade --install aws-privateca-issuer \
     aws-pca-issuer/aws-privateca-issuer \
     --namespace cert-manager \
     --set installCRDs=true

   Diagnose the current state:

   # Check if the CRD exists at all
   kubectl get crd | grep awspca

   # Check if the issuer operator is running
   kubectl get pods -n cert-manager | grep privateca

   # Check operator logs for errors
   kubectl logs -n cert-manager -l app=aws-privateca-issuer --tail=50

   Common causes:

   ┌──────────────────────────────────────────────────────┬────────────────────────────────────────────────────────────────────────────────────────────────────────┐
   │ Cause                                                │ Fix                                                                                                    │
   ├──────────────────────────────────────────────────────┼────────────────────────────────────────────────────────────────────────────────────────────────────────┤
   │ CRDs not installed before applying issuer resources  │ Apply CRD manifests first, then redeploy                                                               │
   ├──────────────────────────────────────────────────────┼────────────────────────────────────────────────────────────────────────────────────────────────────────┤
   │ Helm chart deployed without installCRDs=true         │ Upgrade the Helm release with the flag enabled                                                         │
   ├──────────────────────────────────────────────────────┼────────────────────────────────────────────────────────────────────────────────────────────────────────┤
   │ Wrong namespace for the operator                     │ Verify the operator is in the same namespace you're targeting                                          │
   ├──────────────────────────────────────────────────────┼────────────────────────────────────────────────────────────────────────────────────────────────────────┤
   │ Version mismatch between cert-manager and the issuer │ Check compatibility matrix in the upstream docs (https://github.com/cert-manager/aws-privateca-issuer) │
   ├──────────────────────────────────────────────────────┼────────────────────────────────────────────────────────────────────────────────────────────────────────┤
   │ Deployment pipeline applying resources out of order  │ Add a kubectl wait for CRD establishment before applying issuers                                       │
   └──────────────────────────────────────────────────────┴────────────────────────────────────────────────────────────────────────────────────────────────────────┘

   If you're using a deployment pipeline, add a wait step after CRD installation to ensure they're fully established before proceeding:

   kubectl apply -f crds/
   kubectl wait --for=condition=established --timeout=60s \
     crd/awspcaclusterissuers.awspca.cert-manager.io \
     crd/awspcaissuers.awspca.cert-manager.io

   # Then deploy the rest
   kubectl apply -f manifests/

# aws-pca-clusterissuer - now installed !

Error: unable to build kubernetes objects from release manifest: resource mapping not found for name: "aws-pca-clusterissuer" namespace: "" from "": no matches for kind "AWSPCAClusterIssuer" in version "awspca.cert-manager.io/v1beta1"
ensure CRDs are installed first

> cloudwatch namespace deleted







Same root cause — the CRD isn't registered when Helm tries to render and apply the resources. This is a CRD ordering problem within the Helm chart itself.

   Immediate fix — install CRDs manually first, then deploy:

   # 1. Add the Helm repo if not already added
   helm repo add aws-pca-issuer https://cert-manager.github.io/aws-privateca-issuer
   helm repo update

   # 2. Install ONLY the CRDs first
   helm install aws-privateca-issuer aws-pca-issuer/aws-privateca-issuer \
     --namespace cert-manager \
     --create-namespace \
     --set installCRDs=true \
     --dry-run  # remove this flag once confirmed

   # 3. Wait for CRDs to be established
   kubectl wait --for=condition=established --timeout=90s \
     crd/awspcaclusterissuers.awspca.cert-manager.io \
     crd/awspcaissuers.awspca.cert-manager.io

   # 4. Now apply your AWSPCAClusterIssuer resource
   kubectl apply -f aws-pca-clusterissuer.yaml

   If you're using a separate values file or GitOps pipeline, split the deployment into two stages:

   # Stage 1 — deploy the operator (installs CRDs)
   helm upgrade --install aws-privateca-issuer aws-pca-issuer/aws-privateca-issuer \
     --namespace cert-manager \
     --set installCRDs=true

   # Stage 2 — only after CRDs are established, apply the ClusterIssuer
   kubectl wait --for=condition=established --timeout=90s \
     crd/awspcaclusterissuers.awspca.cert-manager.io

   kubectl apply -f - <<EOF
   apiVersion: awspca.cert-manager.io/v1beta1
   kind: AWSPCAClusterIssuer
   metadata:
     name: aws-pca-clusterissuer
   spec:
     arn: arn:aws:acm-pca:REGION:ACCOUNT_ID:certificate-authority/CA_ID
     region: eu-west-1
   EOF

   If using ArgoCD, the fix is to use a SyncWave to enforce ordering:

   # Wave 0 — Helm chart (installs operator + CRDs)
   metadata:
     annotations:
       argocd.argoproj.io/sync-wave: "0"

   # Wave 1 — ClusterIssuer (depends on CRDs from wave 0)
   metadata:
     annotations:
       argocd.argoproj.io/sync-wave: "1"

   Verify the API version is correct for your installed version:

   # Check what versions the CRD actually exposes
   kubectl get crd awspcaclusterissuers.awspca.cert-manager.io \
     -o jsonpath='{.spec.versions[*].name}'

   If the output shows v1beta1 is not listed, your installed operator version may only support v1alpha1 — adjust the apiVersion in your manifest accordingly.
