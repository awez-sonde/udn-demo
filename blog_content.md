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
