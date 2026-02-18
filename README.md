# OpenShift Virtualization: User-Defined Networking (UDN) Blog Series

## Overview
[cite_start]This repository hosts the technical guides and manifests for a scenario-based blog series focused on **User-Defined Networking (UDN)**[cite: 2]. [cite_start]We explore how to move beyond the default pod network to provide advanced, isolated networking for Virtual Machines (VMs)[cite: 6, 8].

## Project Goals
* [cite_start]Create a detailed guide for configuring Layer 2 and Layer 3 primary/secondary network attachments[cite: 6].
* [cite_start]Provide validated YAML manifests for real-world scenarios including Ingress, Egress, and Services[cite: 13, 23].
* [cite_start]Target audience: Cloud architects, OpenShift administrators, and network engineers[cite: 8].

## Testing Roadmap
1. [cite_start]**Primary UDNs**: Compare Layer 2 (`udn-test1`) and Layer 3 (`udn-test2`) primary interfaces[cite: 21, 23].
2. [cite_start]**Multi-NIC**: Adding Secondary Layer 2 UDNs to existing VMs.
3. [cite_start]**Connectivity**: Implementing Services (SVC), Routes, and Egress (and analyzing L2 vs L3 limitations).
4. [cite_start]**Localnet**: Bridging to external infrastructure via Localnet UDN.
5. [cite_start]**Security**: Applying fine-grained Network Policies for microsegmentation.
