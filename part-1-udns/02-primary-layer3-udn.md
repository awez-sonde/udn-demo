# Primary Layer 3 UDN

## Introduction
A Primary Layer 3 UDN extends Layer 2 UDN by adding IP Address Management (IPAM) capabilities. This allows automatic IP address assignment and provides routing capabilities at Layer 3.

## What is Layer 3 UDN?
Layer 3 UDN operates at both the data link layer (Layer 2) and network layer (Layer 3), providing IP address management through IPAM plugins. This enables automatic IP assignment and routing between networks.

## Use Cases
- Production environments requiring IP management
- Scenarios needing automatic IP assignment
- Networks requiring routing capabilities
- Integration with existing IP address management systems

## Configuration

### Step 1: Create NetworkAttachmentDefinition with IPAM

Create a NetworkAttachmentDefinition in the `udn-test2` namespace with IPAM configuration:

```yaml
apiVersion: k8s.cni.cncf.io/v1
kind: NetworkAttachmentDefinition
metadata:
  name: primary-layer3-udn
  namespace: udn-test2
spec:
  config: |
    {
      "cniVersion": "0.3.1",
      "type": "bridge",
      "bridge": "br-udn-test2",
      "isDefaultGateway": false,
      "ipam": {
        "type": "whereabouts",
        "range": "192.168.100.0/24",
        "exclude": [
          "192.168.100.1-192.168.100.10"
        ]
      }
    }
```

### Step 2: Apply the Configuration

```bash
kubectl apply -f examples/primary-layer3-udn.yaml
```

### Step 3: Attach to Virtual Machine

Add the network to your VM specification:

```yaml
apiVersion: kubevirt.io/v1
kind: VirtualMachine
metadata:
  name: vm-layer3-test
  namespace: udn-test2
spec:
  template:
    spec:
      domain:
        devices:
          interfaces:
          - name: default
            masquerade: {}
          - name: udn-interface
            bridge: {}
      networks:
      - name: default
        pod: {}
      - name: udn-interface
        multus:
          networkName: primary-layer3-udn
```

## IPAM Configuration Options

### Whereabouts IPAM
Whereabouts is a Kubernetes IPAM plugin that manages IP addresses using IP pools.

**Configuration parameters:**
- `range`: CIDR block for IP allocation (e.g., "192.168.100.0/24")
- `exclude`: IP ranges to exclude from allocation
- `gateway`: Optional gateway IP address

### Example IPAM Configurations

**Static Range:**
```json
"ipam": {
  "type": "whereabouts",
  "range": "10.0.0.0/24"
}
```

**With Exclusions:**
```json
"ipam": {
  "type": "whereabouts",
  "range": "10.0.0.0/24",
  "exclude": [
    "10.0.0.1-10.0.0.10",
    "10.0.0.254"
  ]
}
```

**With Gateway:**
```json
"ipam": {
  "type": "whereabouts",
  "range": "10.0.0.0/24",
  "gateway": "10.0.0.1"
}
```

## Testing

### Verify Network Attachment

```bash
kubectl get network-attachment-definitions -n udn-test2
```

### Check IP Assignment

```bash
# Check the VM's network status
kubectl get vmi vm-layer3-test -n udn-test2 -o yaml | grep -A 10 interfaces

# Or connect to the VM
virtctl console vm-layer3-test -n udn-test2

# Inside the VM, check assigned IP
ip addr show
```

### Test Connectivity

```bash
# From within the VM, test connectivity to another VM on the same network
ping <other-vm-ip>
```

## Key Points

- **IPAM Enabled**: Automatic IP address assignment
- **IP Pool Management**: Uses Whereabouts or other IPAM plugins
- **Routing Ready**: Layer 3 capabilities enable routing
- **Namespace-scoped**: Available only in `udn-test2` namespace

## IPAM Plugin Options

### Whereabouts
- Default IPAM plugin for OpenShift
- Manages IP pools using Kubernetes resources
- Supports range exclusions

### Static IPAM
- Manual IP assignment
- Requires specifying exact IP addresses

### DHCP
- Dynamic IP assignment via DHCP server
- Requires DHCP server configuration

## Troubleshooting

### Common Issues

1. **No IP assigned**
   - Verify IPAM configuration is correct
   - Check IP pool has available addresses
   - Ensure Whereabouts is installed

2. **IP conflicts**
   - Review excluded ranges
   - Check for overlapping IP pools
   - Verify no static IP conflicts

3. **Connectivity issues**
   - Verify IP assignment: `ip addr show` in VM
   - Check routing: `ip route show` in VM
   - Ensure gateway is configured if needed

## Next Steps

After understanding Primary Layer 3 UDN, proceed to [Secondary Layer 2 UDN](./03-secondary-layer2-udn.md) to learn about multi-homing.
