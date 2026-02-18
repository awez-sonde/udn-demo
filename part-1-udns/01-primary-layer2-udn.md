# Primary Layer 2 UDN

## Introduction
A Primary Layer 2 UDN provides basic Layer 2 networking for virtual machines. This is the simplest form of User-Defined Networking and serves as the foundation for understanding more complex UDN configurations.

## What is Layer 2 UDN?
Layer 2 UDN operates at the data link layer, providing a bridge-based network where VMs can communicate directly using MAC addresses. This type of UDN is ideal for scenarios where you need simple, flat networking without IP address management.

## Use Cases
- Simple VM-to-VM communication within the same network
- Testing and development environments
- Scenarios where IPAM is not required
- Basic network isolation

## Configuration

### Step 1: Create NetworkAttachmentDefinition

Create a NetworkAttachmentDefinition in the `udn-test1` namespace:

```yaml
apiVersion: k8s.cni.cncf.io/v1
kind: NetworkAttachmentDefinition
metadata:
  name: primary-layer2-udn
  namespace: udn-test1
spec:
  config: |
    {
      "cniVersion": "0.3.1",
      "type": "bridge",
      "bridge": "br-udn-test1",
      "isDefaultGateway": false,
      "ipam": {}
    }
```

### Step 2: Apply the Configuration

```bash
kubectl apply -f examples/primary-layer2-udn.yaml
```

### Step 3: Attach to Virtual Machine

Add the network to your VM specification:

```yaml
apiVersion: kubevirt.io/v1
kind: VirtualMachine
metadata:
  name: vm-layer2-test
  namespace: udn-test1
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
          networkName: primary-layer2-udn
```

## Testing

### Verify Network Attachment

```bash
kubectl get network-attachment-definitions -n udn-test1
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
- **Bridge-based**: Uses a Linux bridge for network connectivity
- **Namespace-scoped**: This UDN is only available in the `udn-test1` namespace
- **Primary network**: This is the primary (non-default) network for the VM

## Troubleshooting

### Common Issues

1. **Network not appearing in VM**
   - Verify the NetworkAttachmentDefinition exists
   - Check VM is in the same namespace
   - Ensure the network name matches exactly

2. **No connectivity**
   - Verify the bridge is created: `ip link show br-udn-test1`
   - Check VM network interfaces: `ip addr show` inside VM

## Next Steps

After understanding Primary Layer 2 UDN, proceed to [Primary Layer 3 UDN](./02-primary-layer3-udn.md) to learn about IP address management.
