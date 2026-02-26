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
OCP 4.21 documentation for UDNs and virtualization workflows highlights three practical topology paths:

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

Topology should be selected based on traffic shape, failure domains, and external dependency requirements, not only on familiarity.

---

## Part 1 Walkthrough: Create Layer 2
From the repo (`Part1: Understanding and implementing UDNs`), apply:

```bash
oc apply -f part-1-udns/examples/primary-layer2-udn.yaml
```

Verify:

```bash
oc get network-attachment-definition primary-layer2-udn -n udn-test1
```

This example is a bridge-based setup in `udn-test1`, useful for validating L2-style connectivity behavior.

---

## Part 1 Walkthrough: Create Layer 3
Apply:

```bash
oc apply -f part-1-udns/examples/primary-layer3-udn.yaml
```

Verify:

```bash
oc get network-attachment-definition primary-layer3-udn -n udn-test2
```

This example uses `whereabouts` IPAM and is useful when you need managed address allocation and routing-friendly behavior.

---

## Part 1 Walkthrough: Create Localnet
Apply:

```bash
oc apply -f part-1-udns/examples/localnet.yaml
```

Verify:

```bash
oc get network-attachment-definition localnet-physical -n udn-test1
```

Because this pattern touches physical networking, coordinate early with your network team for interface, VLAN, and IP plan alignment.

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
- Red Hat OpenShift Container Platform docs (UDN): https://docs.openshift.com/container-platform/4.21/networking/multiple_networks/primary_networks/about-user-defined-networks.html
- OKD docs (UDN): https://docs.okd.io/4.21/networking/multiple_networks/primary_networks/about-user-defined-networks.html
- Red Hat blog on UDN and virtualization: https://www.redhat.com/en/blog/user-defined-networks-red-hat-openshift-virtualization
