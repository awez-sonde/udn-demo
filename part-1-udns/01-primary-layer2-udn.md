# Primary Layer 2 UDN

# Layer2 UDN - User Defined Network

## Overview

Layer2 UDN (User Defined Network) is a network configuration that creates a single logical switch shared by all nodes in the cluster. This allows pods on different nodes to appear as if they are on the same Layer2 network segment.

## What is Layer2 UDN?

Layer2 UDN provides Layer2 (data link layer) connectivity across your OpenShift cluster. Unlike Layer3 topology which creates separate subnets per node, Layer2 creates one logical switch that spans all nodes, enabling:

- **Single broadcast domain** - All pods share the same Layer2 segment
- **Layer2 features** - Support for ARP, broadcast traffic, and other Layer2 protocols
- **Simplified networking** - No inter-node routing required for pod-to-pod communication

## What Happens When You Create a Layer2 UDN?

When you create a Layer2 UDN, the following occurs:

1. **Single Logical Switch Creation**: One logical switch is created and shared across all nodes in the cluster (unlike Layer3 which creates per-node segments).

2. **Pod Connectivity**: Pods in namespaces that match the UDN's `namespaceSelector` automatically receive:
   - IP addresses from the specified subnet
   - Layer2 connectivity to other pods on the same network
   - Ability to communicate as if on the same physical network segment

3. **Broadcast Domain**: Pods can utilize Layer2 features such as:
   - ARP (Address Resolution Protocol)
   - Broadcast traffic
   - Multicast traffic

4. **No Per-Node Subnets**: Unlike Layer3 topology, there are no separate subnets per node—all pods share the same Layer2 segment across the entire cluster.

5. **Automatic Assignment**:
   - **Primary UDN**: Pods automatically get interfaces on this network
   - **Secondary UDN**: Pods require the `k8s.v1.cni.cncf.io/networks` annotation to attach

## Key Characteristics

| Feature | Description |
|---------|-------------|
| **Topology** | `Layer2` - Single shared logical switch |
| **Use Case** | When you need Layer2 semantics (broadcast, ARP) across nodes |
| **IP Assignment** | From a single subnet pool shared across the cluster |
| **Routing** | Layer2 switching, no inter-node routing needed |
| **Broadcast Domain** | Single broadcast domain across all nodes |

## Example Configuration

```yaml
apiVersion: k8s.ovn.org/v1
kind: ClusterUserDefinedNetwork
metadata:
  name: layer2-udn
spec:
  namespaceSelector:
    matchLabels:
      network: layer2
  network:
    topology: Layer2
    layer2:
      subnets:
        - "10.200.0.0/16"
      role: Primary  # or Secondary
```

## When to Use Layer2 UDN

Use Layer2 UDN when you need:

- ✅ Layer2 networking features (ARP, broadcast)
- ✅ Applications that require Layer2 semantics
- ✅ Simple pod-to-pod connectivity without routing complexity
- ✅ Single broadcast domain across the cluster

## Comparison: Layer2 vs Layer3

| Aspect | Layer2 | Layer3 |
|--------|--------|--------|
| **Logical Switches** | One shared switch | One switch per node |
| **Subnets** | Single subnet pool | Per-node subnets |
| **Routing** | Layer2 switching | Layer3 routing between nodes |
| **Broadcast Domain** | Single domain | Separate per node |
| **Use Case** | Layer2 features needed | Standard IP routing |

## Additional Resources

- [OpenShift Networking Documentation](https://docs.openshift.com/)
- [OVN-Kubernetes User Defined Networks](https://github.com/ovn-org/ovn-kubernetes)

## Testing

### Verify Network Attachment

```bash
oc get network-attachment-definitions -n udn-test1
```

### Test Connectivity

Once your VM is running, you can test Layer 2 connectivity:

```bash
# Connect to the VM
virtctl console vm-layer2-test -n udn-test1

# Inside the VM, check network interfaces
ip addr show
```

## Key Points

- **No IPAM**: Layer 2 UDN doesn't manage IP addresses automatically
- **OVN-managed**: OVN-Kubernetes automatically creates and manages the bridge infrastructure
- **Namespace-scoped**: This UDN is only available in the `udn-test1` namespace
- **Primary network**: This is the primary (non-default) network for the VM

## Troubleshooting

### Common Issues

1. **Network not appearing in VM**
   - Verify the NetworkAttachmentDefinition exists
   - Check VM is in the same namespace
   - Ensure the network name matches exactly

2. **No connectivity**
   - Verify the NetworkAttachmentDefinition is applied: `oc get network-attachment-definitions -n udn-test1`
   - Check VM network interfaces: `ip addr show` inside VM
   - Verify VM is running: `oc get vmi -n udn-test1`
   - Check OVN network status (if accessible): The bridge is automatically managed by OVN-Kubernetes

## Next Steps

After understanding Primary Layer 2 UDN, proceed to [Primary Layer 3 UDN](./02-primary-layer3-udn.md) to learn about IP address management.
