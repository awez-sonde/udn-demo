# Cluster UDN (CUDN)

## Overview
This guide creates a cluster-scoped Layer 2 CUDN and applies it to namespaces selected by label.  
The YAML below matches `examples/cluster-udn.yaml` exactly.

## Example Manifest

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: udn-test3
  labels:
    udn-cluster: "true"
    k8s.ovn.org/primary-user-defined-network: ""
---
apiVersion: k8s.ovn.org/v1
kind: ClusterUserDefinedNetwork
metadata:
  name: cluster-udn-test1
spec:
  namespaceSelector:
    matchLabels:
      udn-cluster: "true"
  network:
    topology: Layer2
    layer2:
      role: Primary
      subnets:
        - "10.100.0.0/16"
```

## Apply and Verify

```bash
oc apply -f examples/cluster-udn.yaml
oc get clusteruserdefinednetwork cluster-udn-test1 -o yaml
```

## Notes
- CUDN is cluster-scoped and selects target namespaces with `namespaceSelector`.
- For primary CUDN flows, target namespaces must carry `k8s.ovn.org/primary-user-defined-network` at creation time.
