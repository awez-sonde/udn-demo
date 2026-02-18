# Cluster UDN (CUDN)

## Introduction
A Cluster User-Defined Network (CUDN) is a network definition that is available cluster-wide, across all namespaces. This enables consistent networking configurations and simplifies network management in multi-tenant environments.

## What is Cluster UDN?
Unlike namespace-scoped UDNs, Cluster UDNs are defined at the cluster level and can be referenced from any namespace. This makes them ideal for shared network infrastructure and standardized network configurations.

## Use Cases
- Shared network infrastructure across namespaces
- Standardized network configurations
- Multi-tenant environments with common networks
- Simplified network management
- Cross-namespace VM communication on the same network

## Configuration

### Step 1: Create ClusterNetworkAttachmentDefinition

Create a ClusterNetworkAttachmentDefinition (note the `cluster` scope):

```yaml
apiVersion: k8s.cni.cncf.io/v1
kind: NetworkAttachmentDefinition
metadata:
  name: cluster-udn-test1
  namespace: openshift-network-operator
  annotations:
    k8s.v1.cni.cncf.io/cluster-network: "true"
spec:
  config: |
    {
      "cniVersion": "0.3.1",
      "type": "bridge",
      "bridge": "br-cluster-udn",
      "isDefaultGateway": false,
      "ipam": {
        "type": "whereabouts",
        "range": "10.100.0.0/24"
      }
    }
```

**Note**: Cluster UDNs are typically created in the `openshift-network-operator` namespace or as cluster-scoped resources, depending on your OpenShift version.

### Step 2: Apply the Configuration

```bash
kubectl apply -f examples/cluster-udn.yaml
```

### Step 3: Verify Cluster UDN Availability

```bash
# Check cluster network attachment definitions
kubectl get network-attachment-definitions --all-namespaces | grep cluster-udn-test1

# Or check in the network operator namespace
kubectl get network-attachment-definitions -n openshift-network-operator
```

### Step 4: Use CUDN in Different Namespaces

Now you can reference this CUDN from any namespace, such as `udn-test3`:

```yaml
apiVersion: kubevirt.io/v1
kind: VirtualMachine
metadata:
  name: vm-in-udn-test3
  namespace: udn-test3
spec:
  template:
    spec:
      domain:
        devices:
          interfaces:
          - name: default
            masquerade: {}
          - name: cluster-udn-interface
            bridge: {}
      networks:
      - name: default
        pod: {}
      - name: cluster-udn-interface
        multus:
          networkName: cluster-udn-test1
```

## Cross-Namespace Networking

### Example: VMs in Different Namespaces on Same Network

**VM in `udn-test3` namespace:**
```yaml
apiVersion: kubevirt.io/v1
kind: VirtualMachine
metadata:
  name: vm-1
  namespace: udn-test3
spec:
  template:
    spec:
      domain:
        devices:
          interfaces:
          - name: cluster-net
            bridge: {}
      networks:
      - name: cluster-net
        multus:
          networkName: cluster-udn-test1
```

**VM in `udn-test4` namespace (different namespace, same network):**
```yaml
apiVersion: kubevirt.io/v1
kind: VirtualMachine
metadata:
  name: vm-2
  namespace: udn-test4
spec:
  template:
    spec:
      domain:
        devices:
          interfaces:
          - name: cluster-net
            bridge: {}
      networks:
      - name: cluster-net
        multus:
          networkName: cluster-udn-test1
```

Both VMs will be on the same network and can communicate with each other, despite being in different namespaces.

## CUDN vs Namespace UDN

| Feature | Namespace UDN | Cluster UDN (CUDN) |
|---------|--------------|-------------------|
| Scope | Single namespace | Cluster-wide |
| Definition Location | Target namespace | Network operator namespace |
| Availability | Only in defined namespace | All namespaces |
| Use Case | Namespace-specific networks | Shared infrastructure |
| Management | Per-namespace | Centralized |

## Configuration Options

### Layer 2 CUDN
```yaml
spec:
  config: |
    {
      "cniVersion": "0.3.1",
      "type": "bridge",
      "bridge": "br-cluster-udn",
      "isDefaultGateway": false,
      "ipam": {}
    }
```

### Layer 3 CUDN with IPAM
```yaml
spec:
  config: |
    {
      "cniVersion": "0.3.1",
      "type": "bridge",
      "bridge": "br-cluster-udn",
      "isDefaultGateway": false,
      "ipam": {
        "type": "whereabouts",
        "range": "10.100.0.0/24",
        "exclude": ["10.100.0.1-10.100.0.10"]
      }
    }
```

## Testing

### Verify CUDN Creation

```bash
# Check cluster network attachment definition
kubectl get network-attachment-definitions -n openshift-network-operator cluster-udn-test1

# Verify it's available cluster-wide
kubectl get network-attachment-definitions --all-namespaces | grep cluster-udn-test1
```

### Test Cross-Namespace Connectivity

1. Create VMs in different namespaces using the same CUDN
2. Get IP addresses assigned to each VM
3. Test connectivity between VMs:

```bash
# From VM in udn-test3
ping <vm-ip-in-udn-test4>

# From VM in udn-test4
ping <vm-ip-in-udn-test3>
```

### Check Network Status

```bash
# Check VM network interfaces
kubectl get vmi -n udn-test3 -o yaml | grep -A 10 interfaces

# Check network attachment in VM
kubectl describe vmi vm-in-udn-test3 -n udn-test3
```

## Key Points

- **Cluster-wide**: Available in all namespaces
- **Centralized Management**: Single definition for multiple namespaces
- **Cross-namespace Communication**: VMs in different namespaces can share the network
- **IP Pool Sharing**: IPAM pool is shared across all namespaces using the CUDN

## Best Practices

1. **Naming Convention**: Use clear, descriptive names (e.g., `cluster-udn-<purpose>`)
2. **IP Pool Planning**: Plan IP ranges carefully as they're shared cluster-wide
3. **Documentation**: Document which namespaces use which CUDNs
4. **Access Control**: Use RBAC to control who can create/modify CUDNs
5. **Network Policies**: Apply network policies appropriately for shared networks

## Troubleshooting

### Common Issues

1. **CUDN not visible in namespace**
   - Verify CUDN is created in the correct namespace
   - Check cluster network annotation is set
   - Ensure proper permissions to view cluster resources

2. **IP conflicts across namespaces**
   - Review IPAM pool size
   - Check for overlapping IP ranges
   - Monitor IP pool usage

3. **Cross-namespace connectivity issues**
   - Verify both VMs are using the same CUDN name
   - Check IP assignment
   - Verify network policies allow cross-namespace traffic

### Debugging Commands

```bash
# List all cluster network attachments
kubectl get network-attachment-definitions --all-namespaces -l k8s.v1.cni.cncf.io/cluster-network=true

# Check CUDN configuration
kubectl get network-attachment-definitions -n openshift-network-operator cluster-udn-test1 -o yaml

# View IP pool usage (if using Whereabouts)
kubectl get ipaddresspool -A
```

## Next Steps

After understanding Cluster UDN, proceed to [Localnet](./05-localnet.md) to learn about direct physical network attachment.
