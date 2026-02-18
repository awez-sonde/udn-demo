# Primary Layer 2 UDN

## Introduction

In OpenShift Virtualization, User-Defined Networking (UDN) enables you to move beyond the default pod network and create custom network configurations for your virtual machines. A Primary Layer 2 UDN represents the foundational building block of custom networking—a simple, bridge-based network that operates at the data link layer (Layer 2 of the OSI model).

Primary Layer 2 UDNs are implemented using the [Kubernetes Network Plumbing Working Group's Network Custom Resource Definition De-facto Standard](https://github.com/k8snetworkplumbingwg/multi-net-spec), which defines how additional networks are attached to pods and VMs through `NetworkAttachmentDefinition` resources. These definitions are managed by Multus CNI, a meta-plugin that enables multiple network interfaces in Kubernetes, and are configured using standard CNI (Container Network Interface) plugins.

The bridge CNI plugin, used in Layer 2 UDNs, creates a Linux bridge on the host node and connects VM interfaces to it. This provides a simple, flat network topology where VMs can communicate directly using MAC addresses, without the complexity of IP address management (IPAM) or routing configuration. This makes Layer 2 UDN ideal for learning the fundamentals of UDN and for scenarios requiring straightforward network connectivity.

## What is Layer 2 UDN?

Layer 2 UDN operates at the data link layer (Layer 2) of the OSI networking model, providing a bridge-based network where VMs communicate using MAC addresses rather than IP addresses. When you create a Layer 2 UDN, you're essentially creating a virtual switch (Linux bridge) that connects multiple VMs together on the same broadcast domain.

**Key characteristics:**
- **Bridge-based**: Uses the Linux bridge CNI plugin to create a virtual switch
- **MAC address communication**: VMs identify each other using MAC addresses
- **No IPAM**: Does not include IP Address Management—IPs must be configured manually or through other means
- **Flat network topology**: All VMs on the same UDN are on the same network segment
- **Namespace-scoped**: The NetworkAttachmentDefinition is created in a specific namespace and available only to resources in that namespace

This type of UDN is the simplest form of custom networking and serves as the foundation for understanding more advanced configurations like Layer 3 UDNs (which add IPAM), secondary networks (multi-homing), and cluster-wide UDNs.

## Use Cases
- Simple VM-to-VM communication within the same network
- Testing and development environments
- Scenarios where IPAM is not required
- Basic network isolation

## Configuration

### Step 1: Create NetworkAttachmentDefinition

Create a NetworkAttachmentDefinition in the `udn-test1` namespace. The `NetworkAttachmentDefinition` is a Kubernetes Custom Resource that follows the [Kubernetes Network Plumbing Working Group specification](https://github.com/k8snetworkplumbingwg/multi-net-spec). It defines how additional networks are attached to pods and VMs.

The `spec.config` field contains a JSON-formatted CNI configuration that specifies which CNI plugin to use and its parameters. For a Layer 2 UDN, we use the `bridge` CNI plugin:

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

**Configuration breakdown:**
- `cniVersion`: Specifies the CNI specification version (0.3.1 is widely supported)
- `type`: The CNI plugin type—`bridge` creates a Linux bridge
- `bridge`: The name of the Linux bridge interface to create (e.g., `br-udn-test1`)
- `isDefaultGateway`: Set to `false` since this is not the default route
- `ipam`: Empty object `{}` indicates no IPAM—this is a pure Layer 2 configuration

**Note**: While the [OpenShift Cluster Network Operator](https://github.com/openshift/cluster-network-operator) can manage additional networks through its configuration (using `additionalNetworks` in the network operator config), for User-Defined Networks in OpenShift Virtualization, you typically create `NetworkAttachmentDefinition` resources directly. This gives you more flexibility and follows the standard Kubernetes approach for multi-networking.

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
