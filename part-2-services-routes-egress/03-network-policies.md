# Network Policies

## Introduction
Network Policies in Kubernetes provide fine-grained control over network traffic between pods and VMs. They act as a firewall, allowing you to define rules for ingress and egress traffic based on pod selectors, namespaces, and IP blocks.

## Network Policy Overview

Network Policies use labels to select pods/VMs and define rules for:
- **Ingress**: Traffic coming into pods/VMs
- **Egress**: Traffic going out from pods/VMs

### Key Concepts

- **Default Deny**: By default, all traffic is allowed. Once a NetworkPolicy is applied, it becomes deny-by-default for the selected pods.
- **Pod Selector**: Selects which pods/VMs the policy applies to
- **Policy Types**: `Ingress`, `Egress`, or both
- **Rules**: Define what traffic is allowed

## Basic Network Policy

### Deny All Ingress

Create a policy that denies all incoming traffic:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all-ingress
  namespace: udn-test1
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  # No ingress rules = deny all ingress
```

### Deny All Egress

Create a policy that denies all outgoing traffic:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all-egress
  namespace: udn-test1
spec:
  podSelector: {}
  policyTypes:
  - Egress
  # No egress rules = deny all egress
```

### Deny All (Ingress and Egress)

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all
  namespace: udn-test1
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
  # No rules = deny all traffic
```

## Ingress Rules

### Allow Ingress from Specific Pods

Allow traffic from pods with specific labels:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-ingress-from-pods
  namespace: udn-test1
spec:
  podSelector:
    matchLabels:
      kubevirt.io/domain: vm-l2-a
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          kubevirt.io/domain: vm-l2-b
    ports:
    - protocol: TCP
      port: 80
```

### Allow Ingress from Specific Namespace

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-ingress-from-namespace
  namespace: udn-test1
spec:
  podSelector:
    matchLabels:
      kubevirt.io/domain: vm-l2-a
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: trusted-namespace
    ports:
    - protocol: TCP
      port: 80
```

### Allow Ingress from IP Block

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-ingress-from-ip
  namespace: udn-test1
spec:
  podSelector:
    matchLabels:
      kubevirt.io/domain: vm-l2-a
  policyTypes:
  - Ingress
  ingress:
  - from:
    - ipBlock:
        cidr: 192.168.1.0/24
        except:
        - 192.168.1.100
    ports:
    - protocol: TCP
      port: 80
```

### Allow Ingress from Multiple Sources

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-ingress-multiple
  namespace: udn-test1
spec:
  podSelector:
    matchLabels:
      kubevirt.io/domain: vm-l2-a
  policyTypes:
  - Ingress
  ingress:
  # Allow from specific pods
  - from:
    - podSelector:
        matchLabels:
          kubevirt.io/domain: vm-l2-b
    ports:
    - protocol: TCP
      port: 80
  # Allow from specific namespace
  - from:
    - namespaceSelector:
        matchLabels:
          name: trusted-namespace
    ports:
    - protocol: TCP
      port: 443
  # Allow from IP block
  - from:
    - ipBlock:
        cidr: 10.0.0.0/8
    ports:
    - protocol: TCP
      port: 8080
```

## Egress Rules

### Allow Egress to Specific Pods

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-egress-to-pods
  namespace: udn-test1
spec:
  podSelector:
    matchLabels:
      kubevirt.io/domain: vm-l2-b
  policyTypes:
  - Egress
  egress:
  - to:
    - podSelector:
        matchLabels:
          kubevirt.io/domain: vm-l2-a
    ports:
    - protocol: TCP
      port: 5432
```

### Allow Egress to Specific Namespace

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-egress-to-namespace
  namespace: udn-test1
spec:
  podSelector:
    matchLabels:
      kubevirt.io/domain: vm-l2-b
  policyTypes:
  - Egress
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          name: database-namespace
    ports:
    - protocol: TCP
      port: 5432
```

### Allow Egress to External IPs

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-egress-external
  namespace: udn-test1
spec:
  podSelector:
    matchLabels:
      kubevirt.io/domain: vm-l2-a
  policyTypes:
  - Egress
  egress:
  # Allow DNS
  - to:
    - namespaceSelector: {}
    ports:
    - protocol: UDP
      port: 53
  # Allow external HTTPS
  - to:
    - ipBlock:
        cidr: 0.0.0.0/0
    ports:
    - protocol: TCP
      port: 443
```

### Allow Egress to Multiple Destinations

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-egress-multiple
  namespace: udn-test1
spec:
  podSelector:
    matchLabels:
      kubevirt.io/domain: vm-l2-a
  policyTypes:
  - Egress
  egress:
  # Allow to database
  - to:
    - podSelector:
        matchLabels:
          kubevirt.io/domain: vm-l2-udn-bridged
    ports:
    - protocol: TCP
      port: 5432
  # Allow to cache
  - to:
    - namespaceSelector:
        matchLabels:
          name: cache-namespace
    ports:
    - protocol: TCP
      port: 6379
  # Allow external API calls
  - to:
    - ipBlock:
        cidr: 0.0.0.0/0
    ports:
    - protocol: TCP
      port: 443
```

## Combined Ingress and Egress

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: vm-l2-a-policy
  namespace: udn-test1
spec:
  podSelector:
    matchLabels:
      kubevirt.io/domain: vm-l2-a
  policyTypes:
  - Ingress
  - Egress
  ingress:
  # Allow SSH from vm-l2-b
  - from:
    - podSelector:
        matchLabels:
          kubevirt.io/domain: vm-l2-b
    ports:
    - protocol: TCP
      port: 22
  # Allow HTTP from vm-l2-b
  - from:
    - podSelector:
        matchLabels:
          kubevirt.io/domain: vm-l2-b
    ports:
    - protocol: TCP
      port: 8080
  egress:
  # Allow DNS
  - to:
    - namespaceSelector: {}
    ports:
    - protocol: UDP
      port: 53
    - protocol: TCP
      port: 53
  # Allow external HTTPS
  - to:
    - ipBlock:
        cidr: 0.0.0.0/0
    ports:
    - protocol: TCP
      port: 443
```

## Network Policies for VMs with UDNs

### Policy for VM on UDN

When VMs use UDNs, network policies still apply to the VM's pod network interface. Policies work the same way:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: vm-udn-policy
  namespace: udn-test1
spec:
  podSelector:
    matchLabels:
      kubevirt.io/domain: vm-l2-a
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          kubevirt.io/domain: vm-l2-b
    ports:
    - protocol: TCP
      port: 22
  egress:
  - to:
    - ipBlock:
        cidr: 0.0.0.0/0
    ports:
    - protocol: TCP
      port: 443
```

**Important**: Network policies apply to the pod network interface, not UDN interfaces. If you need to secure UDN traffic, you may need additional network-level controls.

## Testing Network Policies

### Verify Policy Applied

```bash
# Check network policies
kubectl get networkpolicies -n udn-test1

# Get policy details
kubectl describe networkpolicy vm-l2-a-policy -n udn-test1
```

### Test Allowed Traffic

```bash
# From allowed source pod
kubectl run test-client --image=curlimages/curl --rm -it --restart=Never \
  --labels="kubevirt.io/domain=vm-l2-b" -n udn-test1 -- \
  curl http://vm-l2-a-service:80

# Should succeed
```

### Test Blocked Traffic

```bash
# From blocked source pod
kubectl run test-blocked --image=curlimages/curl --rm -it --restart=Never \
  --labels="app=blocked" -n udn-test1 -- \
  curl http://vm-l2-a-service:80

# Should fail or timeout
```

### Test from VM

```bash
# Connect to VM
virtctl console vm-l2-a -n udn-test1

# Inside VM, test connectivity
# Allowed connections should work
curl http://allowed-service:80

# Blocked connections should fail
curl http://blocked-service:80
```

## Advanced Scenarios

### Multi-tier Application

```yaml
# Frontend policy
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: frontend-policy
  namespace: udn-test1
spec:
  podSelector:
    matchLabels:
      tier: frontend
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - namespaceSelector: {}  # Allow from anywhere
    ports:
    - protocol: TCP
      port: 80
  egress:
  - to:
    - podSelector:
        matchLabels:
          tier: backend
    ports:
    - protocol: TCP
      port: 8080

---
# Backend policy
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: backend-policy
  namespace: udn-test1
spec:
  podSelector:
    matchLabels:
      tier: backend
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          tier: frontend
    ports:
    - protocol: TCP
      port: 8080
  egress:
  - to:
    - podSelector:
        matchLabels:
          tier: database
    ports:
    - protocol: TCP
      port: 5432

---
# Database policy
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: database-policy
  namespace: udn-test1
spec:
  podSelector:
    matchLabels:
      tier: database
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          tier: backend
    ports:
    - protocol: TCP
      port: 5432
  # No egress = deny all egress
```

## Troubleshooting

### Common Issues

1. **Policy not working**
   - Verify network policy controller is enabled
   - Check policy is applied: `kubectl get networkpolicies`
   - Verify pod labels match selectors
   - Check policy types are correct

2. **Traffic blocked unexpectedly**
   - Review all network policies in namespace
   - Check for conflicting policies
   - Verify selectors match correctly
   - Check rule order (all rules are evaluated)

3. **Traffic allowed when should be blocked**
   - Verify policy is applied to correct pods
   - Check policy types include the direction
   - Ensure no other policy allows the traffic
   - Verify selectors are correct

4. **DNS not working**
   - Allow DNS egress:
    ```yaml
    egress:
    - to:
      - namespaceSelector: {}
      ports:
      - protocol: UDP
        port: 53
    ```

### Debugging Commands

```bash
# List all network policies
kubectl get networkpolicies -A

# Get policy details
kubectl describe networkpolicy <policy-name> -n <namespace>

# Check which policies apply to a pod
kubectl get networkpolicies -n <namespace> -o yaml

# Test connectivity
kubectl run test-pod --image=curlimages/curl --rm -it --restart=Never -- \
  curl -v <target>

# Check pod labels
kubectl get pods --show-labels -n <namespace>
```

## Best Practices

1. **Default Deny**: Start with deny-all and allow only what's needed
2. **Label Strategy**: Use consistent labels for policy selectors
3. **Documentation**: Document policies and their purposes
4. **Testing**: Test policies in non-production first
5. **Regular Review**: Regularly review and update policies
6. **Least Privilege**: Allow only necessary traffic
7. **Namespace Isolation**: Use namespace selectors for isolation
8. **DNS Allowance**: Always allow DNS egress if needed

## Network Policy Limitations

- **Applies to Pod Network**: Policies apply to pod network, not UDN interfaces
- **No L7 Filtering**: Only L3/L4 filtering (IP and port)
- **No Stateful Rules**: No connection tracking or stateful inspection
- **Namespace Scoped**: Policies are namespace-scoped
- **CNI Dependent**: Requires CNI plugin that supports network policies

## Next Steps

Congratulations! You've completed both parts of the blog series. You now understand:
- All UDN types and configurations (Part 1)
- Services, Routes, Egress, and Network Policies (Part 2)

You're ready to implement comprehensive networking solutions for your OpenShift Virtualization environment!
