# Designing VM Networks with OpenShift User-Defined Networks

## UDN Basics in Red Hat OpenShift Container Platform
Red Hat OpenShift Container Platform uses OVN-Kubernetes as its default networking stack.  
User-Defined Networks (UDNs) let you create extra network segments for pods and virtual machines (VMs), with much better isolation than a one-size-fits-all setup.

If you are running or migrating VM workloads, UDNs are one of the most useful features to get cleaner network boundaries and predictable behavior.

---

## When UDN Became Available
UDNs are part of modern OpenShift releases and reached **general availability in Red Hat OpenShift Container Platform 4.18**.

Quick tip: always validate details against the docs for your exact version before production rollout, because some behaviors and workflows evolve over time.

---

## The Main UDN Objects You Work With
Most UDN designs are built with two resources:

- **`UserDefinedNetwork`** (namespace-scoped)
- **`ClusterUserDefinedNetwork`** (cluster-scoped, can target multiple namespaces)

This gives a practical ownership model: cluster admins can define shared patterns, and tenant or app teams can consume those patterns safely.
UDNs require OVN-Kubernetes as the CNI.

UDN/CUDN and NAD can work together:
- UDN/CUDN is the recommended high-level API for most tenant-isolation use cases.
- NAD still exists for plugin-specific secondary networking workflows.
- In UDN/CUDN workflows, OpenShift creates the network attachment artifacts for you.

---

## Why Teams Use UDNs for Virtualization
UDNs are usually adopted to solve familiar VM networking needs:

- stronger tenant isolation
- easier IP plan reuse
- clearer separation between traffic types
- fewer custom networking exceptions

In short, UDNs make network design feel intentional instead of patched together.

---

## Topology choices and trade-offs
Red Hat OpenShift Container Platform documentation highlights three practical topology paths:

### Layer2
- A shared broadcast domain across nodes.
- Good fit for VM networking patterns that expect subnet-like behavior.
- Simpler to reason about during initial migrations.

### Layer3
- Per-node segments with routing between nodes.
- Better scaling characteristics for larger deployments and broadcast control.
- Requires more deliberate address planning.

### Localnet (secondary scenarios)
- Connects OVN-managed networks to external Layer 2 infrastructure.
- Useful when VMs must reach physical network domains directly.
- Needs aligned node and physical network configuration.

Important: `Localnet` is not supported in namespace-scoped `UserDefinedNetwork` CRs.  
Use `Localnet` with:
- secondary `NetworkAttachmentDefinition` (NAD), or
- `ClusterUserDefinedNetwork` (CUDN) with `topology: Localnet` and `role: Secondary`.

Topology should be selected based on traffic shape, failure domains, and external dependency requirements, not only on familiarity.

---

## Part 1 Walkthrough: Create Layer 2 UDN
To create a primary Layer 2 UDN, create the namespace with the required label first:

```bash
cat <<'EOF' | oc apply -f -
apiVersion: v1
kind: Namespace
metadata:
  name: udn-test1
  labels:
    k8s.ovn.org/primary-user-defined-network: ""
EOF
```

Create the `UserDefinedNetwork`:

```yaml
apiVersion: k8s.ovn.org/v1
kind: UserDefinedNetwork
metadata:
  name: layer2-udn
  namespace: udn-test1
spec:
  topology: Layer2
  layer2:
    role: Primary
    subnets:
      - "10.200.0.0/16"
```

Apply and verify:

```bash
oc apply -f layer2-udn.yaml
oc get userdefinednetwork layer2-udn -n udn-test1 -o yaml
```

### Overlapping subnet use case (same CIDR in two projects)
Apply the overlapping example:

```bash
oc apply -f part-1-udns/examples/overlapping-layer2-udn.yaml
```

This creates two namespaces (`udn-overlap-a` and `udn-overlap-b`) and assigns both a primary Layer2 UDN with the same subnet (`10.220.0.0/16`).  
The same CIDR works because each UDN is isolated by design.


---

## Part 1 Walkthrough: Create Layer 3 UDN
Create the `UserDefinedNetwork`:

```yaml
apiVersion: k8s.ovn.org/v1
kind: UserDefinedNetwork
metadata:
  name: layer3-udn
  namespace: udn-test2
spec:
  topology: Layer3
  layer3:
    role: Primary
    subnets:
      - cidr: 10.150.0.0/16
        hostSubnet: 24
```

Apply and verify:

```bash
oc apply -f layer3-udn.yaml
oc get userdefinednetwork layer3-udn -n udn-test2 -o yaml
```

For Layer 3 UDN, `subnets` with `cidr` + `hostSubnet` are required.  


---

## Part 1 Walkthrough: Create Localnet
Use a `ClusterUserDefinedNetwork` with Localnet topology:

```yaml
apiVersion: k8s.ovn.org/v1
kind: ClusterUserDefinedNetwork
metadata:
  name: localnet-cudn
spec:
  namespaceSelector:
    matchLabels:
      udn-localnet: "true"
  network:
    topology: Localnet
    localnet:
      role: Secondary
      physicalNetworkName: test
      ipam:
        lifecycle: Persistent
      subnets:
        - "192.168.0.0/16"
```

Apply and verify:

```bash
oc apply -f part-1-udns/examples/localnet.yaml
oc get clusteruserdefinednetwork localnet-physical -o yaml
```

Because Localnet touches physical networking, coordinate early with your network team for interface, VLAN, OVS bridge mapping, and IP plan alignment.

---

## Validation Scenarios (Ping-Based)
Use this section after creating your demo resources to validate expected behavior.

### 1) Intra-UDN validation (same UDN, should pass)
Example: two VMs in `udn-test1` on the same Layer2 UDN (`vm-l2-a`, `vm-l2-b`).

```bash
# Create VMs
oc apply -f part-1-udns/examples/vms-layer2-intra.yaml

# Get VM interfaces and IPs
oc get vmi -n udn-test1 -o wide

# Open console to VM A and ping VM B
virtctl console vm-l2-a -n udn-test1
ping <vm-l2-b-ip-on-udn>
```

Expected result: ping succeeds.

Bridge-mode VM check (from the all-validation bundle):

```bash
# Start the bridge-mode VM in udn-test1
virtctl start vm-l2-udn-bridged -n udn-test1

# Verify the VMI and inspect interface details from inside the guest
oc get vmi vm-l2-udn-bridged -n udn-test1 -o wide
virtctl console vm-l2-udn-bridged -n udn-test1
ip addr
```

Expected result: `vm-l2-udn-bridged` comes up on the UDN and uses a bridged primary interface (not masquerade).

### Masquerade vs Bridge: where the UDN IP appears
In this demo, we have used two modes of network interfaces for VM's:

- `vm-l2-a` (masquerade): inside the VM you usually see a NAT-style guest IP (for example `10.0.2.x`), not the UDN IP.
- `vm-l2-udn-bridged` (bridge): inside the VM you see the UDN IP directly (for example `10.200.0.x`).
- In masquerade mode, the UDN-facing IP is visible on interfaces in the `virt-launcher` pod namespace.

Use these checks side by side:

```bash
# Guest view (masquerade VM)
virtctl console vm-l2-a -n udn-test1
ip a

# Guest view (bridge VM)
virtctl console vm-l2-udn-bridged -n udn-test1
ip a

# Pod namespace view for masquerade VM
MASQ_POD=$(oc get pod -n udn-test1 -l kubevirt.io=virt-launcher,kubevirt.io/domain=vm-l2-a -o name)
oc exec -n udn-test1 -it "${MASQ_POD#pod/}" -- ip a

# Pod namespace view for bridge VM
BRIDGE_POD=$(oc get pod -n udn-test1 -l kubevirt.io=virt-launcher,kubevirt.io/domain=vm-l2-udn-bridged -o name)
oc exec -n udn-test1 -it "${BRIDGE_POD#pod/}" -- ip a
```

How to read common `virt-launcher` interfaces (names can vary slightly):

- `eth0`: pod primary network interface (cluster pod network, not the guest NIC).
- `ovn-udn1`: OVN/UDN-side interface created for the UDN attachment.
- `k6t-ovn-udn1`: Linux bridge managed by KubeVirt to connect VM tap and pod-side UDN attachment.
- `tap0`: tap device connected to the VM NIC and attached to `k6t-ovn-udn1`.
- `lo`: loopback interface.

Practical interpretation for this demo:

- In masquerade mode, traffic is NATed between guest NIC and pod-side UDN attachment, so the guest does not present the UDN IP directly.
- In bridge mode, the VM NIC is bridged into the UDN path, so the guest gets and shows the UDN IP directly.

### 2) Inter-UDN isolation validation (different UDNs, should fail)
Example: one VM in `udn-overlap-a` and one VM in `udn-overlap-b`, both using `10.220.0.0/16` (`vm-overlap-a`, `vm-overlap-b`).

```bash
# Create VMs
oc apply -f part-1-udns/examples/vms-overlap.yaml

oc get vmi -n udn-overlap-a -o wide
oc get vmi -n udn-overlap-b -o wide

# From VM in namespace A, try pinging VM IP in namespace B
virtctl console vm-overlap-a -n udn-overlap-a
ping <vm-overlap-b-ip-on-10.220.0.0/16>
```

Expected result: ping fails, proving subnet overlap is safe when UDNs are isolated.

### 3) CUDN validation (cross-namespace on same CUDN, should pass)
Example: two VMs in different namespaces matched by the same `ClusterUserDefinedNetwork` (`vm-cudn-a` in `udn-test3`, `vm-cudn-b` in `udn-test4`).

```bash
# Confirm CUDN is ready
oc get clusteruserdefinednetwork cluster-udn-test1 -o yaml

# Create VMs
oc apply -f part-1-udns/examples/vms-cudn.yaml

# Check VM IPs in both namespaces
oc get vmi -n udn-test3 -o wide
oc get vmi -n udn-test4 -o wide

# Ping across namespaces over the shared CUDN
virtctl console vm-cudn-a -n udn-test3
ping <vm-cudn-b-ip-in-udn-test4>
```

Expected result: ping succeeds.

### 4) Localnet validation (underlay reachability)
Example: VM attached to Localnet network (`vm-localnet-1`).

```bash
# Verify localnet CUDN
oc get clusteruserdefinednetwork localnet-physical -o yaml

# Create VM
oc apply -f part-1-udns/examples/vm-localnet.yaml

# Open VM console and test underlay connectivity
virtctl console vm-localnet-1 -n udn-localnet-test
ip addr
ping <underlay-gateway-ip>
ping <known-underlay-host-ip>
```

Expected result: VM can reach underlay targets allowed by your physical network policy.

### 5) Quick status checks when validation fails

```bash
oc get userdefinednetwork -A
oc get clusteruserdefinednetwork
oc get network-attachment-definition -A
oc describe userdefinednetwork <name> -n <namespace>
oc describe clusteruserdefinednetwork <name>
```

Focus on `status.conditions` messages first; they usually show the root cause.

### 6) One-shot demo setup (all validation resources)

```bash
oc apply -f part-1-udns/examples/all-validation-resources.yaml
```

This applies all namespaces, UDN/CUDN resources, and named VMs used in the validation section.
In this bundle, VMs are created in a stopped state (`running: false`) for GitOps-friendly health behavior.
Start them when needed:

```bash
virtctl start vm-l2-a -n udn-test1
virtctl start vm-l2-b -n udn-test1
virtctl start vm-l2-udn-bridged -n udn-test1
virtctl start vm-overlap-a -n udn-overlap-a
virtctl start vm-overlap-b -n udn-overlap-b
virtctl start vm-cudn-a -n udn-test3
virtctl start vm-cudn-b -n udn-test4
virtctl start vm-localnet-1 -n udn-localnet-test
```

### 7) Network-only bootstrap (no VMs)

```bash
oc apply -f part-1-udns/examples/all-network-bootstrap.yaml
```

This applies only namespaces and UDN/CUDN resources, so you can add VMs later as needed.

### 8) Cleanup after demo

```bash
bash part-1-udns/examples/cleanup-validation.sh
```

GitOps note: use the `Application` files in `gitops/`:
- `gitops/app-network-bootstrap.yaml`
- `gitops/app-full-validation.yaml`

---

## Practical Checks Before Production
- Keep namespace and network resource creation order consistent.
- Validate interface names and node capabilities for Localnet.
- Confirm VM connectivity and failover with realistic traffic tests.
- Document IP ranges and exclusions early.

These small checks prevent most late-stage surprises.

---

## Closing Thoughts
User-Defined Networks give virtualization teams a much cleaner networking model in Red Hat OpenShift Container Platform.  
Once your role, topology, and IP plan are standardized, the same approach can be reused across teams and environments with less rework.

## References
- Red Hat OpenShift Container Platform 4.21, Multiple networks: https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/multiple_networks/index
- Red Hat OpenShift Container Platform 4.21, About user-defined networks: https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html/multiple_networks/about-user-defined-networks
