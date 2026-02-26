# Secondary Layer 2 UDN

## Overview
This guide creates a secondary Layer 2 `UserDefinedNetwork` in `udn-test1`.  
The YAML below matches `examples/secondary-layer2-udn.yaml` exactly.

## Example Manifest

```yaml
apiVersion: k8s.ovn.org/v1
kind: UserDefinedNetwork
metadata:
  name: secondary-layer2-udn
  namespace: udn-test1
spec:
  topology: Layer2
  layer2:
    role: Secondary
    subnets:
      - "10.210.0.0/16"
```

## Apply and Verify

```bash
oc apply -f examples/secondary-layer2-udn.yaml
oc get userdefinednetwork secondary-layer2-udn -n udn-test1 -o yaml
```

## Notes
- Secondary UDN is for additional interfaces (multi-homing), not for replacing the primary namespace network.
- For VM attachment, reference `secondary-layer2-udn` through Multus in the VM network section.
