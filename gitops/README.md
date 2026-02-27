# OpenShift GitOps Application Files

This folder contains `Application` resources for OpenShift GitOps (Argo CD).

## Files
- `app-network-bootstrap.yaml`: deploys only namespaces + UDN/CUDN resources
- `app-full-validation.yaml`: deploys namespaces + UDN/CUDN + validation VMs

## Repository defaults
The app files are already preconfigured with:
- `spec.source.repoURL: https://github.com/awez-sonde/udn-demo.git`
- `spec.source.targetRevision: main`
- `spec.source.path: part-1-udns/examples`
- `spec.source.directory.recurse: false`
- `spec.source.directory.include` is set per app:
  - `all-network-bootstrap.yaml` for network bootstrap
  - `all-validation-resources.yaml` for full validation

## Deploy
```bash
oc apply -f gitops/app-network-bootstrap.yaml
```

or

```bash
oc apply -f gitops/app-full-validation.yaml
```

## VM Runtime Note (GitOps)
In the full validation bundle, VMs are created with `spec.running: false` to keep Argo CD app health stable.
Start them when you are ready to run connectivity checks:

```bash
virtctl start vm-l2-a -n udn-test1
virtctl start vm-l2-b -n udn-test1
virtctl start vm-overlap-a -n udn-overlap-a
virtctl start vm-overlap-b -n udn-overlap-b
virtctl start vm-cudn-a -n udn-test3
virtctl start vm-cudn-b -n udn-test4
virtctl start vm-localnet-1 -n udn-localnet-test
```
