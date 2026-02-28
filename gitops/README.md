# OpenShift GitOps Application Files

This folder contains `Application` resources for OpenShift GitOps (Argo CD).

## Files
- `app-network-bootstrap.yaml`: deploys only namespaces + UDN/CUDN resources
- `app-full-validation.yaml`: deploys validation VMs only (no namespace/network overlap with bootstrap app)

## Repository defaults
The app files are already preconfigured with:
- `spec.source.repoURL: https://github.com/awez-sonde/udn-demo.git`
- `spec.source.targetRevision: main`
- `spec.source.path: part-1-udns/examples`
- `spec.source.directory.recurse: false`
- `spec.source.directory.include` is set per app:
  - `all-network-bootstrap.yaml` for network bootstrap
  - `all-validation-vms-only.yaml` for full validation VMs

## Deploy
```bash
oc apply -f gitops/app-network-bootstrap.yaml
```

or

```bash
oc apply -f gitops/app-full-validation.yaml
```

## VM Runtime Note (GitOps)
`app-full-validation.yaml` ignores drift on `VirtualMachine.spec.running`, so manual start/stop operations are allowed and Argo CD will not force-stop VMs.
