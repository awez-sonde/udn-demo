# Services & Routes

## Introduction
Kubernetes Services and OpenShift Routes provide ways to expose your virtual machines to other pods, services, and external clients. This guide covers how to create and configure Services and Routes for VMs using User-Defined Networks.

## Services Overview

Kubernetes Services provide a stable endpoint to access a set of pods (or VMs). Services abstract away the underlying network details and provide load balancing.

### Service Types

1. **ClusterIP**: Internal cluster access (default)
2. **NodePort**: Exposes service on each node's IP at a static port
3. **LoadBalancer**: Exposes service externally using a cloud provider's load balancer
4. **ExternalName**: Maps service to an external DNS name

## Creating Services for VMs

### Step 1: Ensure VM Has Labels

First, ensure your VM has appropriate labels for service selection:

```yaml
apiVersion: kubevirt.io/v1
kind: VirtualMachine
metadata:
  name: vm-web-server
  namespace: udn-test1
  labels:
    app: web-server
    version: v1
spec:
  # ... VM spec
```

### Step 2: Create a ClusterIP Service

Create a service that targets your VM:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: vm-web-service
  namespace: udn-test1
spec:
  selector:
    app: web-server
  ports:
  - name: http
    port: 80
    targetPort: 8080
    protocol: TCP
  - name: https
    port: 443
    targetPort: 8443
    protocol: TCP
  type: ClusterIP
```

### Step 3: Apply the Service

```bash
kubectl apply -f examples/service-example.yaml
```

### Step 4: Verify Service

```bash
# Check service
kubectl get svc vm-web-service -n udn-test1

# Get service details
kubectl describe svc vm-web-service -n udn-test1

# Check endpoints
kubectl get endpoints vm-web-service -n udn-test1
```

## Services with UDN Networks

### Service Targeting UDN Interface

When VMs use UDNs, you need to ensure the service targets the correct network interface. Services typically target the default pod network, but you can configure them to work with UDN interfaces.

**Important**: Services work with the VM's pod network interface. If your VM's service is on a UDN, you may need to:

1. Ensure the VM has both default pod network and UDN
2. Configure the service to target the appropriate interface
3. Use the VM's pod IP for service endpoints

### Example: VM with Multiple Networks

```yaml
apiVersion: kubevirt.io/v1
kind: VirtualMachine
metadata:
  name: vm-multi-net
  namespace: udn-test1
  labels:
    app: multi-net-app
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

The service will use the default pod network interface for connectivity.

## Routes Overview

OpenShift Routes provide HTTP/HTTPS-based external access to services. Routes are built on top of Services and provide additional features like TLS termination and path-based routing.

### Route Types

1. **Edge**: TLS termination at the router
2. **Passthrough**: TLS termination at the backend
3. **Reencrypt**: TLS termination at router with re-encryption to backend

## Creating Routes for VMs

### Step 1: Create a Service (if not exists)

Ensure you have a service for your VM:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: vm-web-service
  namespace: udn-test1
spec:
  selector:
    app: web-server
  ports:
  - port: 80
    targetPort: 8080
  type: ClusterIP
```

### Step 2: Create a Route

Create a route that exposes the service:

```yaml
apiVersion: route.openshift.io/v1
kind: Route
metadata:
  name: vm-web-route
  namespace: udn-test1
spec:
  to:
    kind: Service
    name: vm-web-service
  port:
    targetPort: http
  tls:
    termination: edge
    insecureEdgeTerminationPolicy: Redirect
```

### Step 3: Apply the Route

```bash
kubectl apply -f examples/route-example.yaml
```

### Step 4: Verify Route

```bash
# Check route
kubectl get route vm-web-route -n udn-test1

# Get route details
kubectl describe route vm-web-route -n udn-test1

# Get route hostname
kubectl get route vm-web-route -n udn-test1 -o jsonpath='{.spec.host}'
```

## Route Configurations

### Edge Route (TLS Termination at Router)

```yaml
apiVersion: route.openshift.io/v1
kind: Route
metadata:
  name: vm-web-route-edge
  namespace: udn-test1
spec:
  to:
    kind: Service
    name: vm-web-service
  port:
    targetPort: http
  tls:
    termination: edge
    certificate: |
      -----BEGIN CERTIFICATE-----
      ...
      -----END CERTIFICATE-----
    key: |
      -----BEGIN PRIVATE KEY-----
      ...
      -----END PRIVATE KEY-----
    insecureEdgeTerminationPolicy: Redirect
```

### Passthrough Route (TLS at Backend)

```yaml
apiVersion: route.openshift.io/v1
kind: Route
metadata:
  name: vm-web-route-passthrough
  namespace: udn-test1
spec:
  to:
    kind: Service
    name: vm-web-service
  port:
    targetPort: https
  tls:
    termination: passthrough
```

### Reencrypt Route

```yaml
apiVersion: route.openshift.io/v1
kind: Route
metadata:
  name: vm-web-route-reencrypt
  namespace: udn-test1
spec:
  to:
    kind: Service
    name: vm-web-service
  port:
    targetPort: https
  tls:
    termination: reencrypt
    destinationCACertificate: |
      -----BEGIN CERTIFICATE-----
      ...
      -----END CERTIFICATE-----
    insecureEdgeTerminationPolicy: Redirect
```

## Validating Ingress Connectivity

### Test Service Connectivity

```bash
# From within the cluster
# Get service cluster IP
SVC_IP=$(kubectl get svc vm-web-service -n udn-test1 -o jsonpath='{.spec.clusterIP}')

# Test connectivity from a pod
kubectl run test-pod --image=curlimages/curl --rm -it --restart=Never -- curl http://$SVC_IP:80

# Or using service DNS name
kubectl run test-pod --image=curlimages/curl --rm -it --restart=Never -- \
  curl http://vm-web-service.udn-test1.svc.cluster.local:80
```

### Test Route Connectivity

```bash
# Get route hostname
ROUTE_HOST=$(kubectl get route vm-web-route -n udn-test1 -o jsonpath='{.spec.host}')

# Test from external client
curl http://$ROUTE_HOST

# Test with HTTPS (if TLS configured)
curl -k https://$ROUTE_HOST
```

### Test from VM

```bash
# Connect to VM
virtctl console vm-web-server -n udn-test1

# Inside VM, test service connectivity
curl http://vm-web-service.udn-test1.svc.cluster.local:80

# Test route (if accessible from VM)
curl http://vm-web-route-udn-test1.apps.example.com
```

## Advanced Service Configurations

### Session Affinity

```yaml
apiVersion: v1
kind: Service
metadata:
  name: vm-web-service
  namespace: udn-test1
spec:
  selector:
    app: web-server
  ports:
  - port: 80
    targetPort: 8080
  sessionAffinity: ClientIP
  sessionAffinityConfig:
    clientIP:
      timeoutSeconds: 10800
```

### External IPs

```yaml
apiVersion: v1
kind: Service
metadata:
  name: vm-web-service
  namespace: udn-test1
spec:
  selector:
    app: web-server
  ports:
  - port: 80
    targetPort: 8080
  externalIPs:
  - 192.168.1.100
```

### LoadBalancer Service

```yaml
apiVersion: v1
kind: Service
metadata:
  name: vm-web-service
  namespace: udn-test1
spec:
  selector:
    app: web-server
  ports:
  - port: 80
    targetPort: 8080
  type: LoadBalancer
```

## Troubleshooting

### Common Issues

1. **Service has no endpoints**
   - Verify VM labels match service selector
   - Check VM is running: `kubectl get vmi -n <namespace>`
   - Verify VM has the correct labels

2. **Route not accessible**
   - Check route status: `kubectl describe route <route-name>`
   - Verify service exists and has endpoints
   - Check router is running: `kubectl get pods -n openshift-ingress`
   - Verify DNS resolution for route hostname

3. **Connection timeouts**
   - Verify VM is listening on the target port
   - Check network policies aren't blocking traffic
   - Verify firewall rules
   - Test connectivity from VM to service

4. **TLS certificate issues**
   - Verify certificate format is correct
   - Check certificate validity
   - Ensure key matches certificate
   - Verify CA certificate for reencrypt routes

### Debugging Commands

```bash
# Check service endpoints
kubectl get endpoints vm-web-service -n udn-test1 -o yaml

# Check VM status
kubectl get vmi -n udn-test1

# Check route status
kubectl describe route vm-web-route -n udn-test1

# Check router logs
kubectl logs -n openshift-ingress -l ingresscontroller.operator.openshift.io/deployment-ingresscontroller=default

# Test DNS resolution
nslookup vm-web-service.udn-test1.svc.cluster.local

# Check network policies
kubectl get networkpolicies -n udn-test1
```

## Best Practices

1. **Label Management**: Use consistent labels for service selection
2. **Port Naming**: Use named ports for better readability
3. **TLS Configuration**: Always use TLS for production routes
4. **Health Checks**: Implement health checks in your VMs
5. **Monitoring**: Monitor service and route metrics
6. **Documentation**: Document service and route configurations

## Next Steps

After understanding Services and Routes, proceed to [Egress](./02-egress.md) to learn about controlling outbound traffic.
