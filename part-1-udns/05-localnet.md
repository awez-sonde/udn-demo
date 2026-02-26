# Localnet

## Overview
This guide creates a Localnet `ClusterUserDefinedNetwork` (CUDN).  
The YAML below matches `examples/localnet.yaml` exactly.

## Example Manifest

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: udn-localnet-test
  labels:
    udn-localnet: "true"
---
apiVersion: k8s.ovn.org/v1
kind: ClusterUserDefinedNetwork
metadata:
  name: localnet-physical
spec:
  namespaceSelector:
    matchLabels:
      udn-localnet: "true"
  network:
    topology: Localnet
    localnet:
      role: Secondary
      physicalNetworkName: localnet1
      ipam:
        lifecycle: Persistent
      subnets:
        - "192.168.1.0/24"
```

## Apply and Verify

```bash
oc apply -f examples/localnet.yaml
oc get clusteruserdefinednetwork localnet-physical -o yaml
```

## Prerequisites and Notes
- Localnet requires OVS bridge mapping aligned to `physicalNetworkName`.
- In Red Hat OpenShift Container Platform, Localnet is supported with CUDN (`role: Secondary`) and supported secondary-network workflows.
- Validate node-level physical network mapping before VM onboarding.
