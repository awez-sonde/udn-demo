# OpenShift Virtualization User-Defined Networks in OCP 4.21

## Why this matters
When you run virtual machines (VMs) in OpenShift, you often need stronger network separation than the default cluster network provides.

User-Defined Networks (UDNs) help you:
- isolate one team or application from another
- reuse the same IP range in different isolated networks
- choose where and how VMs connect

For this demo blog, the target platform is **OpenShift Container Platform (OCP) 4.21**.

---

## What a UDN is
A UDN is an additional network you define for pods and VMs.

In OCP 4.21, you will commonly see two custom resources:
- **`UserDefinedNetwork`**: namespace-scoped network definition
- **`ClusterUserDefinedNetwork`**: cluster-scoped network definition that can apply to multiple namespaces

Both are managed by OVN-Kubernetes.

---

## Primary vs secondary networks (simple view)
- **Primary network:** the main network interface used by workloads in that namespace selection.
- **Secondary network:** an extra interface attached for specific traffic needs.

Use primary when you want a namespace to run mainly on that network.  
Use secondary when you need an additional path (for example, app traffic on one network and another function on a separate network).

---

## Topology options in OCP 4.21
For virtualization use cases, documentation highlights these practical choices:

- **Layer2:** workloads share one broadcast domain; useful when VMs need behavior similar to a traditional subnet.
- **Layer3:** per-node segmentation with routing between nodes; useful for larger scale and controlled broadcast behavior.
- **Localnet:** used in secondary network scenarios when connecting to external Layer 2 infrastructure.

Choose topology based on your traffic pattern, scale, and external network requirements.

---

## Beginner-friendly design tips
1. Start with **one small namespace** and test connectivity first.
2. Use **Layer2** for the easiest first demo with VMs.
3. Keep your CIDR plan simple and document it early.
4. Apply namespace labels and network resources in the correct order.
5. Verify status after creation (`oc get ... -o yaml`) before onboarding workloads.

---

## Important limitations to know
Based on current OCP/OKD UDN documentation, plan for these behaviors:
- namespace labels used for primary UDN workflows must be set at namespace creation time
- DNS and default network service behavior can differ from the default cluster network
- some traffic policy expectations do not apply between fully isolated primary networks
- changing UDN/CUDN definitions after creation is restricted, so design carefully first

These are normal platform constraints, not configuration mistakes.

---

## Conclusion
In OCP 4.21, UDNs provide a clear and supported way to build tenant-aware VM networking.  
They are a strong fit when you need clean isolation, predictable IP planning, and a repeatable network model that is easier to operate than custom one-off solutions.

## References
- OpenShift Container Platform 4.21 documentation: https://docs.openshift.com/container-platform/4.21/networking/multiple_networks/primary_networks/about-user-defined-networks.html
- OKD 4.21 documentation: https://docs.okd.io/4.21/networking/multiple_networks/primary_networks/about-user-defined-networks.html
- Red Hat Blog: https://www.redhat.com/en/blog/user-defined-networks-red-hat-openshift-virtualization
