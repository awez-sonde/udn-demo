# Primary Layer 2 UDN

## Overview
This guide creates a primary Layer 2 `UserDefinedNetwork` in `udn-test1`.  
The YAML below matches `examples/primary-layer2-udn.yaml` exactly.

## Example Manifest

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: udn-test1
  labels:
    k8s.ovn.org/primary-user-defined-network: ""
---
apiVersion: k8s.ovn.org/v1
kind: UserDefinedNetwork
metadata:
  name: primary-layer2-udn
  namespace: udn-test1
spec:
  topology: Layer2
  layer2:
    role: Primary
    subnets:
      - "10.200.0.0/16"
    ipam:
      lifecycle: Persistent
```

## Apply and Verify

```bash
oc apply -f examples/primary-layer2-udn.yaml
oc get userdefinednetwork primary-layer2-udn -n udn-test1 -o yaml
```

## Notes
- The namespace label `k8s.ovn.org/primary-user-defined-network` must exist at namespace creation time.
- A primary UDN becomes the main workload network for that namespace.