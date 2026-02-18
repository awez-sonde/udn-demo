# Localnet

## Introduction
Localnet provides direct VM-to-physical network attachment, bypassing the overlay network. This enables VMs to connect directly to the physical network infrastructure, which is essential for scenarios requiring direct access to physical networks or integration with existing network equipment.

## What is Localnet?
Localnet is a special type of UDN that connects VMs directly to a physical network interface on the host node. Unlike bridge-based UDNs that create virtual bridges, Localnet uses the physical network interface directly, allowing VMs to appear as if they're directly connected to the physical network.

## Use Cases
- Direct physical network access
- Integration with existing network infrastructure
- Bypassing overlay network for performance
- VLAN trunking and tagging
- Integration with physical switches and routers
- Legacy system integration
- Network appliances and gateways

## Configuration

### Step 1: Identify Physical Network Interface

First, identify the physical network interface on your nodes:

```bash
# On the node, list network interfaces
ip link show

# Or using oc debug
oc debug node/<node-name> -- chroot /host ip link show
```

Common physical interfaces:
- `eth0`, `ens3`, `eno1` (Ethernet)
- `bond0`, `bond1` (Bonded interfaces)
- `br-ex` (External bridge, if pre-configured)

### Step 2: Create Localnet NetworkAttachmentDefinition

Create a NetworkAttachmentDefinition with Localnet configuration:

```yaml
apiVersion: k8s.cni.cncf.io/v1
kind: NetworkAttachmentDefinition
metadata:
  name: localnet-physical
  namespace: <your-namespace>
spec:
  config: |
    {
      "cniVersion": "0.3.1",
      "type": "macvlan",
      "master": "eth0",
      "mode": "bridge",
      "ipam": {
        "type": "whereabouts",
        "range": "192.168.1.0/24"
      }
    }
```

**Alternative: Using SR-IOV (for high performance):**

```yaml
apiVersion: k8s.cni.cncf.io/v1
kind: NetworkAttachmentDefinition
metadata:
  name: localnet-sriov
  namespace: <your-namespace>
spec:
  config: |
    {
      "cniVersion": "0.3.1",
      "type": "sriov",
      "master": "eth0",
      "vlan": 100,
      "ipam": {
        "type": "whereabouts",
        "range": "192.168.100.0/24"
      }
    }
```

### Step 3: Apply the Configuration

```bash
kubectl apply -f examples/localnet.yaml
```

### Step 4: Attach to Virtual Machine

Add the Localnet to your VM specification:

```yaml
apiVersion: kubevirt.io/v1
kind: VirtualMachine
metadata:
  name: vm-localnet
  namespace: <your-namespace>
spec:
  template:
    spec:
      domain:
        devices:
          interfaces:
          - name: default
            masquerade: {}
          - name: localnet-interface
            bridge: {}  # or sriov: {} for SR-IOV
      networks:
      - name: default
        pod: {}
      - name: localnet-interface
        multus:
          networkName: localnet-physical
      nodeSelector:
        kubernetes.io/hostname: <node-with-physical-interface>
```

## Localnet Types

### Macvlan Localnet
Creates a macvlan interface on the physical network:

```yaml
config: |
  {
    "cniVersion": "0.3.1",
    "type": "macvlan",
    "master": "eth0",
    "mode": "bridge",
    "ipam": {
      "type": "whereabouts",
      "range": "192.168.1.0/24"
    }
  }
```

**Characteristics:**
- Each VM gets its own MAC address on the physical network
- VMs appear as separate devices on the physical network
- Requires promiscuous mode on the physical interface

### SR-IOV Localnet
Uses Single Root I/O Virtualization for direct hardware access:

```yaml
config: |
  {
    "cniVersion": "0.3.1",
    "type": "sriov",
    "master": "eth0",
    "vlan": 100,
    "ipam": {
      "type": "whereabouts",
      "range": "192.168.100.0/24"
    }
  }
```

**Characteristics:**
- Direct hardware access for better performance
- Lower latency and higher throughput
- Requires SR-IOV capable hardware and drivers
- Supports VLAN tagging

### Bridge Localnet
Uses a bridge connected to the physical interface:

```yaml
config: |
  {
    "cniVersion": "0.3.1",
    "type": "bridge",
    "bridge": "br-physical",
    "isDefaultGateway": false,
    "ipam": {
      "type": "whereabouts",
      "range": "192.168.1.0/24"
    }
  }
```

## VLAN Configuration

### VLAN Tagging with Localnet

For VLAN-tagged networks:

```yaml
apiVersion: k8s.cni.cncf.io/v1
kind: NetworkAttachmentDefinition
metadata:
  name: localnet-vlan100
  namespace: <your-namespace>
spec:
  config: |
    {
      "cniVersion": "0.3.1",
      "type": "macvlan",
      "master": "eth0",
      "mode": "bridge",
      "vlan": 100,
      "ipam": {
        "type": "whereabouts",
        "range": "192.168.100.0/24"
      }
    }
```

## Node Selection

Since Localnet uses physical interfaces, you may need to specify which node the VM runs on:

```yaml
spec:
  template:
    spec:
      nodeSelector:
        kubernetes.io/hostname: worker-node-1
      # Or use node affinity
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
            - matchExpressions:
              - key: kubernetes.io/hostname
                operator: In
                values:
                - worker-node-1
                - worker-node-2
```

## Testing

### Verify Physical Interface

```bash
# Check physical interfaces on nodes
oc debug node/<node-name> -- chroot /host ip link show

# Verify interface is up and has carrier
oc debug node/<node-name> -- chroot /host ethtool eth0
```

### Verify Network Attachment

```bash
kubectl get network-attachment-definitions -n <namespace>
```

### Test Connectivity

```bash
# Connect to VM
virtctl console vm-localnet -n <namespace>

# Inside VM, check network interface
ip addr show

# Test connectivity to physical network
ping <physical-network-gateway>
ping <device-on-physical-network>
```

### Verify MAC Address

```bash
# Check VM MAC address
kubectl get vmi vm-localnet -n <namespace> -o yaml | grep macAddress

# On physical network, verify MAC is visible
# (check switch/router ARP table)
```

## Key Points

- **Direct Physical Access**: Bypasses overlay network
- **Performance**: Lower latency, higher throughput (especially with SR-IOV)
- **Node-specific**: Requires physical interface on the node
- **Network Integration**: VMs appear as devices on physical network
- **VLAN Support**: Can use VLAN tagging

## Security Considerations

1. **Promiscuous Mode**: Macvlan requires promiscuous mode on physical interface
2. **Network Access**: VMs have direct access to physical network
3. **Firewall Rules**: May need to configure physical network firewalls
4. **Network Policies**: Network policies may not apply to Localnet traffic
5. **Isolation**: Less isolation compared to overlay networks

## Best Practices

1. **Node Selection**: Use node selectors to ensure VMs run on nodes with physical interfaces
2. **IP Planning**: Coordinate IP addresses with network administrators
3. **VLAN Management**: Use VLANs to segment traffic on physical network
4. **Monitoring**: Monitor physical network interface utilization
5. **Documentation**: Document which physical interfaces are used

## Troubleshooting

### Common Issues

1. **Interface not found**
   - Verify physical interface name is correct
   - Check interface exists on the node
   - Ensure interface is up

2. **No connectivity**
   - Verify IP assignment
   - Check physical network configuration
   - Verify VLAN configuration if using VLANs
   - Check firewall rules on physical network

3. **Promiscuous mode errors**
   - Ensure physical interface supports promiscuous mode
   - Check node network configuration
   - Verify CNI plugin supports macvlan

4. **SR-IOV issues**
   - Verify hardware supports SR-IOV
   - Check SR-IOV drivers are installed
   - Verify VF (Virtual Function) configuration

### Debugging Commands

```bash
# Check physical interface status
oc debug node/<node-name> -- chroot /host ip link show eth0

# Check macvlan interfaces
oc debug node/<node-name> -- chroot /host ip link show type macvlan

# Verify promiscuous mode
oc debug node/<node-name> -- chroot /host ip link show eth0 | grep PROMISC

# Check SR-IOV VFs
oc debug node/<node-name> -- chroot /host lspci | grep -i ethernet
oc debug node/<node-name> -- chroot /host ls -la /sys/class/net/eth0/device/
```

## Next Steps

Congratulations! You've completed Part 1 covering all UDN types. Now proceed to [Part 2: Services, Routes, Egress, and Network Policies](../part-2-services-routes-egress/README.md) to learn about advanced networking features and security.
