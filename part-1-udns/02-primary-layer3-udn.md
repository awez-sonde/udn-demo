# Primary Layer 3 UDN

## Overview
This guide creates a primary Layer 3 `UserDefinedNetwork` in `udn-test2`.  
The YAML below matches `examples/primary-layer3-udn.yaml` exactly.

## Example Manifest

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: udn-test2
  labels:
    k8s.ovn.org/primary-user-defined-network: ""
---
apiVersion: k8s.ovn.org/v1
kind: UserDefinedNetwork
metadata:
  name: primary-layer3-udn
  namespace: udn-test2
spec:
  topology: Layer3
  layer3:
    role: Primary
    subnets:
      - cidr: 10.150.0.0/16
        hostSubnet: 24
```

## Apply and Verify

```bash
oc apply -f examples/primary-layer3-udn.yaml
oc get userdefinednetwork primary-layer3-udn -n udn-test2 -o yaml
```

## Notes
- For Layer 3 UDN, `subnets` is required and uses `cidr` + `hostSubnet`.
- Primary Layer 3 UDN is useful when you want routed behavior with per-node segmentation.
