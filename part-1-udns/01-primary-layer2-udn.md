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
kind: UserDefinedNetwork
metadata:
  name: layer2-udn
  namespace: my-namespace
spec:
  network:
    topology: Layer2
    layer2:
      subnets:
        - "10.200.0.0/16"
      role: Primary  # or Secondary
```

**Note**: For cluster-wide UDN (CUDN), use `ClusterUserDefinedNetwork` with `namespaceSelector` instead.

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

## Test: Create Layer2 UDN with VM

This test demonstrates creating a namespace, Layer2 UDN, and a VirtualMachine that uses the network.

### Prerequisites

- OpenShift cluster with OVN-Kubernetes CNI
- KubeVirt installed (for VM creation)
- Cluster administrator privileges

### Step 1: Create Namespace

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: udn-primary-layer2
  labels:
    network: layer2-primary
    k8s.ovn.org/primary-user-defined-network: layer2-udn-primary
```

**Note**: The `k8s.ovn.org/primary-user-defined-network` label must be set at namespace creation time and cannot be added later.

### Step 2: Create Layer2 UDN

Create a namespace-scoped UserDefinedNetwork (UDN) with Primary role:

```yaml
apiVersion: k8s.ovn.org/v1
kind: UserDefinedNetwork
metadata:
  name: layer2-udn-primary
  namespace: udn-primary-layer2
spec:
  network:
    topology: Layer2
    layer2:
      subnets:
        - "10.200.0.0/16"
      role: Primary
```

### Step 3: Create VirtualMachine

```yaml
apiVersion: kubevirt.io/v1
kind: VirtualMachine
metadata:
  name: rhel-primary-layer2
  namespace: udn-primary-layer2
spec:
  running: true
  template:
    metadata:
      labels:
        kubevirt.io/vm: rhel-primary-layer2
    spec:
      domain:
        devices:
          interfaces:
            - name: default
              masquerade: {}
        resources:
          requests:
            memory: 2Gi
            cpu: 1
      networks:
        - name: default
          pod: {}
      volumes:
        - name: containerdisk
          containerDisk:
            image: quay.io/containerdisks/rhel9:latest
        - name: cloudinitdisk
          cloudInitNoCloud:
            userData: |
              #cloud-config
              password: redhat
              chpasswd:
                expire: false
              ssh_pwauth: true
```

**Note**: Since this is a Primary UDN and the namespace has the `k8s.ovn.org/primary-user-defined-network` label, the VM will automatically receive a network interface on the Layer2 UDN. The VM's default network interface will be on the UDN network.

### Apply All Resources

```bash
# Apply namespace
oc apply -f namespace.yaml

# Apply UserDefinedNetwork
oc apply -f layer2-udn.yaml

# Wait for UDN to be ready
oc wait --for=condition=Ready userdefinednetwork/layer2-udn-primary -n udn-primary-layer2 --timeout=60s

# Apply VirtualMachine
oc apply -f vm.yaml

# Check VM status
oc get vm -n udn-primary-layer2
oc get vmi -n udn-primary-layer2
```

### Verification

```bash
# Verify namespace has the correct labels
oc get namespace udn-primary-layer2 --show-labels

# Verify UserDefinedNetwork status
oc get userdefinednetwork layer2-udn-primary -n udn-primary-layer2 -o yaml

# Verify VM is running and has network interface
oc get vmi rhel-primary-layer2 -n udn-primary-layer2 -o yaml | grep -A 10 interfaces

# Check VM network connectivity (if VNC/console access available)
oc console -n udn-primary-layer2 rhel-primary-layer2
```

### Expected Results

- Namespace `udn-primary-layer2` created with proper labels
- UserDefinedNetwork `layer2-udn-primary` in Ready state within the namespace
- VirtualMachine `rhel-primary-layer2` running with network interface on the Layer2 UDN
- VM can communicate with other pods/VMs on the same Layer2 network

## Additional Resources

- [OpenShift Networking Documentation](https://docs.openshift.com/)
- [OVN-Kubernetes User Defined Networks](https://github.com/ovn-org/ovn-kubernetes)
- [KubeVirt Documentation](https://kubevirt.io/)