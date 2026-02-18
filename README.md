# udn-demo

Here is a friendly, readable introduction for your blog series in Markdown, completely customized to the testing scenarios you outlined.

I've also addressed your question about Layer 2 vs. Layer 3 capabilities below the draft!

Exploring User-Defined Networking (UDN) in OpenShift Virtualization
Welcome to our deep dive into User-Defined Networking (UDN) with OpenShift Virtualization! If you are a cloud architect, cluster admin, or network engineer looking to unlock advanced networking capabilities for your Virtual Machines (VMs), you are in the right place.

Networking in Kubernetes has traditionally been pod-centric, but as we bring traditional VM workloads into OpenShift, we need more flexibility. That is where UDN comes in. It allows us to step outside the default pod network and create isolated, custom-tailored Layer 2, Layer 3, and Localnet topologies that behave exactly how our VM workloads expect them to.

In this blog series, we aren't just going to talk about theory—we are going to get our hands dirty. We will walk through a series of practical, real-world testing scenarios to see exactly how UDN behaves in the wild.

What We Are Going to Test
To fully explore what UDN can do, we have set up a comprehensive testing lab. Here is the roadmap of the scenarios we will be covering:

1. The Foundation: Layer 2 vs. Layer 3 Primary UDNs

We will start by creating two isolated environments to compare how different network layers operate as the primary interface for our VMs:

Namespace udn-test1: Configured with a Layer 2 UDN as the primary network.

Namespace udn-test2: Configured with a Layer 3 UDN as the primary network.

The Workloads: We will deploy two Red Hat Enterprise Linux VMs (rhel-test-udn-test1 and rhel-test-udn-test2), one in each namespace, to establish our baselines.

2. Complex Interfaces: Adding a Secondary UDN

Virtual machines often need multiple network interfaces (e.g., one for management, one for data processing). We will test this by adding a Secondary Layer 2 UDN to our udn-test1 namespace and attaching it to our existing VM.

3. Traffic Management: Services, Routes, and Egress

How do we get traffic in and out of these custom networks? We will attempt to configure Kubernetes Services (SVC), OpenShift Routes, and Egress rules for the primary UDNs in both namespaces to see how external connectivity and ingress/egress routing behave. (Spoiler alert: Layer 2 and Layer 3 handle this very differently!)

4. Bridging to the Outside: Localnet UDN

Next, we will look at connecting our VMs directly to external physical networks. We will attach a local interface on a localnet network, exploring how the Localnet UDN topology bridges our OpenShift cluster with our broader datacenter infrastructure.

5. Microsegmentation: Fine-Grained Network Policies

Finally, we will spin up additional VMs in both namespaces to test security. We will apply fine-grained Network Policies to ensure that VMs within the same namespace can only communicate with each other on specifically designated ports, proving that UDNs don't sacrifice Kubernetes-native security controls.

Stick around as we break down each of these scenarios step-by-step, share the YAML manifests, and look at the actual outcomes!

💡 Addressing Your Doubt: Layer 2 vs. Layer 3 for Services, Routes, and Egress

You have excellent intuition—you are completely correct that you will face limitations trying to create standard Services, Routes, and Egress policies for a pure Layer 2 UDN. Here is why: OpenShift's standard traffic management (like ClusterIP Services, Routes handling HTTP traffic, and Egress NATing) relies heavily on Layer 3/Layer 4 IP routing handled by the OVN-Kubernetes SDN.

Layer 3 UDNs integrate well with these Kubernetes-native constructs because the cluster is fully aware of the IP routing and subnets.

Layer 2 UDNs, on the other hand, act like a virtual switch spanning your nodes. Because it operates at the MAC address level, standard Kubernetes Services and Routes don't natively know how to route or load-balance traffic into that flat Layer 2 overlay.

Testing this in your blog will actually make for a fantastic learning moment for your readers! You can show them how Layer 3 easily handles Routes/Services, and then document the exact limitations (or alternative external load-balancing workarounds) when dealing with Layer 2.

Would you like me to start drafting the step-by-step YAML guide for the first scenario (setting up the namespaces and primary UDNs)?
