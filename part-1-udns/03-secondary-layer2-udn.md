# Secondary Layer 2 UDN

## Introduction
A Secondary Layer 2 UDN allows you to add additional network interfaces to virtual machines, enabling multi-homing scenarios. This is useful when VMs need to connect to multiple networks simultaneously.

## What is Secondary UDN?
A secondary UDN is an additional network interface added to a VM that already has a primary network (either the default pod network or a primary UDN). This enables VMs to be connected to multiple networks at the same time.

## Use Cases
- Multi-homing: VMs connected to multiple networks
- Network segmentation: Separating traffic types
- Migration scenarios: Gradual network transition
- Redundancy: Multiple network paths
- Service isolation: Different networks for different services

## Configuration

### Step 1: Create Primary Network (if not exists)

Ensure you have a primary network. This could be the default pod network or a primary UDN.

### Step 2: Create Secondary NetworkAttachmentDefinition

Create a secondary NetworkAttachmentDefinition in the `udn-test1` namespace:

```yaml
apiVersion: k8s.cni.cncf.io/v1
kind: NetworkAttachmentDefinition
metadata:
  name: secondary-layer2-udn
  namespace: udn-test1
spec:
  config: |
    {
      "cniVersion": "0.3.1",
      "type": "bridge",
      "bridge": "br-secondary-udn-test1",
      "isDefaultGateway": false,
      "ipam": {}
    }
```

### Step 3: Apply the Configuration

```bash
kubectl apply -f examples/secondary-layer2-udn.yaml
```

### Step 4: Attach Both Networks to Virtual Machine

Add both primary and secondary networks to your VM specification:

```yaml
apiVersion: kubevirt.io/v1
kind: VirtualMachine
metadata:
  name: vm-multihomed
  namespace: udn-test1
spec:
  template:
    spec:
      domain:
        devices:
          interfaces:
          - name: default
            masquerade: {}
          - name: primary-udn
            bridge: {}
          - name: secondary-udn
            bridge: {}
      networks:
      - name: default
        pod: {}
      - name: primary-udn
        multus:
          networkName: primary-layer2-udn
      - name: secondary-udn
        multus:
          networkName: secondary-layer2-udn
```

## Multi-Homing Scenarios

### Scenario 1: Default + Secondary UDN
VM connected to default pod network and a secondary UDN:

```yaml
interfaces:
- name: default
  masquerade: {}
- name: secondary-net
  bridge: {}
networks:
- name: default
  pod: {}
- name: secondary-net
  multus:
    networkName: secondary-layer2-udn
```

### Scenario 2: Primary UDN + Secondary UDN
VM connected to two different UDNs:

```yaml
interfaces:
- name: primary-udn
  bridge: {}
- name: secondary-udn
  bridge: {}
networks:
- name: primary-udn
  multus:
    networkName: primary-layer2-udn
- name: secondary-udn
  multus:
    networkName: secondary-layer2-udn
```

### Scenario 3: Multiple Secondary Networks
VM with default network and multiple secondary networks:

```yaml
interfaces:
- name: default
  masquerade: {}
- name: secondary-net1
  bridge: {}
- name: secondary-net2
  bridge: {}
networks:
- name: default
  pod: {}
- name: secondary-net1
  multus:
    networkName: secondary-layer2-udn-1
- name: secondary-net2
  multus:
    networkName: secondary-layer2-udn-2
```

## Testing

### Verify Network Attachments

```bash
kubectl get network-attachment-definitions -n udn-test1
```

### Check VM Network Interfaces

```bash
# Check VM network status
kubectl get vmi vm-multihomed -n udn-test1 -o yaml | grep -A 20 interfaces

# Connect to the VM
virtctl console vm-multihomed -n udn-test1

# Inside the VM, list all interfaces
ip addr show

# Check routing table
ip route show
```

### Test Connectivity on Each Network

```bash
# Test connectivity on primary network
ping -I <primary-interface> <target-ip>

# Test connectivity on secondary network
ping -I <secondary-interface> <target-ip>
```

## Key Points

- **Multi-homing**: VMs can have multiple network interfaces
- **Network Isolation**: Each network is isolated from others
- **Flexible Configuration**: Mix and match different network types
- **Interface Ordering**: Interface order matters for routing

## Best Practices

1. **Naming Convention**: Use clear, descriptive names for interfaces
2. **Network Purpose**: Document the purpose of each network
3. **IP Management**: Plan IP addresses for each network carefully
4. **Routing**: Configure routing rules if needed for multi-homed VMs
5. **Security**: Apply network policies per network interface

## Troubleshooting

### Common Issues

1. **Secondary network not appearing**
   - Verify NetworkAttachmentDefinition exists
   - Check interface name matches network name
   - Ensure VM is in the correct namespace

2. **Routing conflicts**
   - Check default route configuration
   - Verify routing table: `ip route show`
   - Use source-based routing if needed

3. **Interface ordering**
   - Interface order in spec affects enumeration
   - Check `ip link show` to see actual interface names
   - May differ from spec order

### Debugging Commands

```bash
# Check all network attachments
kubectl get network-attachment-definitions -n udn-test1

# View VM network status
kubectl describe vmi vm-multihomed -n udn-test1

# Check bridge interfaces on node
ip link show | grep br-

# View network attachment status
kubectl get network-attachment-definitions -n udn-test1 -o yaml
```

## Next Steps

After understanding Secondary Layer 2 UDN, proceed to [Cluster UDN (CUDN)](./04-cluster-udn.md) to learn about cluster-wide network definitions.
