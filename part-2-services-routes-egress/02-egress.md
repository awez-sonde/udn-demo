# Egress

## Introduction
Egress policies in OpenShift allow you to control outbound traffic from pods and VMs, including specifying source IP addresses, destination restrictions, and routing rules. This is essential for security, compliance, and network integration requirements.

## Egress Overview

Egress in OpenShift provides several mechanisms to control outbound traffic:

1. **Egress IPs**: Assign specific source IP addresses to pods/VMs
2. **Egress Router**: Route traffic through a dedicated egress pod
3. **Egress Network Policies**: Control which destinations can be accessed
4. **Egress Firewall**: Block or allow traffic to specific destinations

## Egress IPs

Egress IPs allow you to assign a specific source IP address to pods or VMs, making it appear as if traffic originates from a specific IP address rather than the pod's IP.

### Use Cases
- Integration with external systems requiring specific source IPs
- Compliance requirements for source IP tracking
- Network policies based on source IP
- Integration with firewalls and security systems

### Configuration

#### Step 1: Create EgressIP Object

Create an EgressIP that defines the source IP and which pods/VMs should use it:

```yaml
apiVersion: k8s.ovn.org/v1
kind: EgressIP
metadata:
  name: egress-ip-vm-l3-a
spec:
  egressIPs:
  - 192.168.1.100
  namespaceSelector:
    matchLabels:
      kubernetes.io/metadata.name: udn-test2
  podSelector:
    matchLabels:
      kubevirt.io/domain: vm-l3-a
```

#### Step 2: Ensure namespace and VM match selectors

This example uses the built-in namespace label and existing VM labels from Part 1 validation:

```bash
oc get ns udn-test2 --show-labels | grep kubernetes.io/metadata.name
oc get vmi -n udn-test2 --show-labels
```

#### Step 3: Apply configuration

```bash
oc apply -f examples/egress-policy.yaml
```

### Verify Egress IP

```bash
# Check egress IP status
oc get egressip egress-ip-vm-l3-a

# Check egress IP assignment
oc describe egressip egress-ip-vm-l3-a

# Test from VM
virtctl console vm-l3-a -n udn-test2
# Inside VM:
curl ifconfig.me  # Should show egress IP
```

## Egress Router

An Egress Router is a pod that acts as a gateway for outbound traffic, routing traffic through a specific network interface or gateway.

### Use Cases
- Routing traffic through a specific gateway
- Network segmentation requirements
- Integration with VPNs or dedicated networks
- Compliance and audit requirements

### Configuration

#### Step 1: Create Egress Router Pod

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: egress-router
  namespace: udn-test2
  annotations:
    k8s.v1.cni.cncf.io/networks: |
      [
        {
          "name": "egress-network",
          "namespace": "udn-test2"
        }
      ]
spec:
  containers:
  - name: egress-router
    image: quay.io/openshift/origin-egress-router:latest
    env:
    - name: EGRESS_SOURCE
      value: "192.168.100.100"
    - name: EGRESS_GATEWAY
      value: "192.168.100.1"
    - name: EGRESS_DESTINATION
      value: "0.0.0.0/0"
    securityContext:
      privileged: true
    resources:
      requests:
        cpu: 100m
        memory: 100Mi
```

#### Step 2: Create Service for Egress Router

```yaml
apiVersion: v1
kind: Service
metadata:
  name: egress-router-service
  namespace: udn-test2
spec:
  ports:
  - port: 8080
  selector:
    name: egress-router
  type: ClusterIP
```

#### Step 3: Configure VMs to Use Egress Router

Update VM configuration to route traffic through egress router:

```yaml
apiVersion: kubevirt.io/v1
kind: VirtualMachine
metadata:
  name: vm-l3-a
  namespace: udn-test2
spec:
  template:
    spec:
      # Configure routing to use egress router
      # This typically requires custom network configuration
```

## Egress Network Policies

Egress Network Policies (also called Egress Firewall) allow you to control which external destinations pods and VMs can access.

### Configuration

#### Step 1: Create EgressFirewall

```yaml
apiVersion: k8s.ovn.org/v1
kind: EgressFirewall
metadata:
  name: vm-l3-egress-firewall
  namespace: udn-test2
spec:
  egress:
  - to:
      dnsName: "api.example.com"
    type: Allow
  - to:
      cidrSelector: 8.8.8.8/32
    type: Allow
  # Block everything else (default deny)
  - to:
      cidrSelector: 0.0.0.0/0
    type: Deny
```

#### Step 2: Apply Policy

```bash
oc apply -f examples/egress-policy.yaml
```

#### Step 3: Verify Policy

```bash
# Check egress network policy
oc get egressfirewall -n udn-test2

# Get policy details
oc describe egressfirewall vm-l3-egress-firewall -n udn-test2
```

### Policy Rules

#### Allow Specific CIDR

```yaml
- to:
    cidrSelector: 192.168.1.0/24
  type: Allow
```

#### Allow Specific DNS Name

```yaml
- to:
    dnsName: api.example.com
  type: Allow
```

#### Allow DNS Name with Wildcard

```yaml
- to:
    dnsName: "*.example.com"
  type: Allow
```

#### Deny All (Default)

```yaml
- to:
    cidrSelector: 0.0.0.0/0
  type: Deny
```

## Testing Egress Configuration

### Test Egress IP

```bash
# Connect to VM
virtctl console vm-l3-a -n udn-test2

# Inside VM, check source IP
curl ifconfig.me
curl ipinfo.io/ip

# Should show the configured egress IP
```

### Test Egress Network Policy

```bash
# Connect to VM
virtctl console vm-l3-a -n udn-test2

# Test allowed destination
curl http://api.example.com

# Test blocked destination
curl http://blocked-site.com
# Should fail or timeout

# Test allowed IP
curl http://8.8.8.8
```

### Test Egress Router

```bash
# Check egress router pod
kubectl get pods -n udn-test2 | grep egress-router

# Check egress router logs
kubectl logs egress-router -n udn-test2

# Test connectivity through router
# (depends on router configuration)
```

## Advanced Egress Configurations

### Multiple Egress IPs

```yaml
apiVersion: k8s.ovn.org/v1
kind: EgressIP
metadata:
  name: egress-ip-multi
spec:
  egressIPs:
  - 192.168.100.100
  - 192.168.100.101
  - 192.168.100.102
  namespaceSelector:
    matchLabels:
      kubernetes.io/metadata.name: udn-test2
```

### Egress IP with Node Selector

```yaml
apiVersion: k8s.ovn.org/v1
kind: EgressIP
metadata:
  name: egress-ip-node-specific
spec:
  egressIPs:
  - 192.168.100.100
  nodeSelector:
    matchLabels:
      node-role.kubernetes.io/worker: ""
  namespaceSelector:
    matchLabels:
      kubernetes.io/metadata.name: udn-test2
```

### Complex Egress Network Policy

```yaml
apiVersion: k8s.ovn.org/v1
kind: EgressFirewall
metadata:
  name: complex-egress-policy
  namespace: udn-test2
spec:
  egress:
  # Allow DNS
  - to:
      dnsName: "*.cluster.local"
    type: Allow
  # Allow Kubernetes API
  - to:
      cidrSelector: 10.0.0.0/8
    type: Allow
  # Allow specific external APIs
  - to:
      dnsName: "api.github.com"
    type: Allow
  - to:
      dnsName: "*.aws.amazon.com"
    type: Allow
  # Block everything else
  - to:
      cidrSelector: 0.0.0.0/0
    type: Deny
```

## Troubleshooting

### Common Issues

1. **Egress IP not assigned**
   - Verify EgressIP object exists and is configured correctly
   - Check namespace and pod labels match selectors
   - Verify egress IP is available on the node
   - Check node has egress IP capability

2. **Egress policy not working**
   - Verify EgressFirewall is applied
   - Check policy rules are correct
   - Verify DNS names resolve correctly
   - Check for conflicting policies

3. **Traffic blocked unexpectedly**
   - Review egress network policy rules
   - Check rule order (first match wins)
   - Verify CIDR selectors are correct
   - Check DNS name matching

4. **Egress router not routing**
   - Verify egress router pod is running
   - Check router configuration
   - Verify network attachment
   - Check router logs

### Debugging Commands

```bash
# Check egress IPs
kubectl get egressip -A

# Check egress network policies
oc get egressfirewall -A

# Check node egress IP configuration
oc get hostsubnet

# Check egress router
kubectl get pods -n udn-test2 | grep egress
kubectl logs egress-router -n udn-test2

# Test connectivity from VM
virtctl console <vm-name> -n <namespace>
# Inside VM:
curl -v http://example.com
traceroute example.com
```

## Best Practices

1. **Egress IP Planning**: Plan egress IP ranges carefully
2. **Policy Documentation**: Document egress policies and their purposes
3. **Testing**: Test egress policies in non-production first
4. **Monitoring**: Monitor egress traffic and policy violations
5. **Least Privilege**: Use deny-by-default and allow only what's needed
6. **Regular Review**: Regularly review and update egress policies

## Next Steps

After understanding Egress, proceed to [Network Policies](./03-network-policies.md) to learn about securing network traffic with policies.
