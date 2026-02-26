# OpenShift GitOps Application Files

This folder contains `Application` resources for OpenShift GitOps (Argo CD).

## Files
- `app-network-bootstrap.yaml`: deploys only namespaces + UDN/CUDN resources
- `app-full-validation.yaml`: deploys namespaces + UDN/CUDN + validation VMs

## Before applying
Update these fields in each app file:
- `spec.source.repoURL`
- `spec.source.targetRevision`

## Deploy
```bash
oc apply -f gitops/app-network-bootstrap.yaml
```

or

```bash
oc apply -f gitops/app-full-validation.yaml
```
