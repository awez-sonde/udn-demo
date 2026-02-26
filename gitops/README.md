# OpenShift GitOps Application Files

This folder contains `Application` resources for OpenShift GitOps (Argo CD).

## Files
- `app-network-bootstrap.yaml`: deploys only namespaces + UDN/CUDN resources
- `app-full-validation.yaml`: deploys namespaces + UDN/CUDN + validation VMs

## Repository defaults
The app files are already preconfigured with:
- `spec.source.repoURL: https://github.com/awez-sonde/udn-demo.git`
- `spec.source.targetRevision: main`

## Deploy
```bash
oc apply -f gitops/app-network-bootstrap.yaml
```

or

```bash
oc apply -f gitops/app-full-validation.yaml
```
