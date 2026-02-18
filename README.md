# OpenShift Virtualization: User-Defined Networking (UDN) Blog Series

## Overview
This repository contains a comprehensive two-part blog series focused on **User-Defined Networking (UDN)** within OpenShift Virtualization. The series provides detailed guides, examples, and practical configurations to help users move beyond the default pod network and implement advanced networking scenarios.

## Blog Series Structure

### Part 1: Understanding and Implementing UDNs
This part covers all User-Defined Network types and configurations:
- **Primary Layer 2 UDN**: Basic Layer 2 networking in `udn-test1`
- **Primary Layer 3 UDN**: Layer 3 networking with IPAM in `udn-test2`
- **Secondary Layer 2 UDN**: Multi-homing setup in `udn-test1`
- **Cluster UDN (CUDN)**: Creating and using cluster-wide UDNs (`cluster-udn-test1` in `udn-test3`)
- **Localnet**: Direct VM-to-physical network attachment

📖 [Read Part 1: Understanding and Implementing UDNs](./part-1-udns/README.md)

### Part 2: Services, Routes, Egress, and Network Policies
This part covers advanced networking features and security:
- **Services & Routes**: Validating ingress connectivity and service exposure
- **Egress**: Configuring external access and egress policies
- **Network Policies**: Securing traffic with network policies

📖 [Read Part 2: Services, Routes, Egress, and Network Policies](./part-2-services-routes-egress/README.md)

## Repository Structure

```
udn-demo/
├── README.md (this file)
├── part-1-udns/
│   ├── README.md
│   ├── 01-primary-layer2-udn.md
│   ├── 02-primary-layer3-udn.md
│   ├── 03-secondary-layer2-udn.md
│   ├── 04-cluster-udn.md
│   ├── 05-localnet.md
│   └── examples/
│       ├── primary-layer2-udn.yaml
│       ├── primary-layer3-udn.yaml
│       ├── secondary-layer2-udn.yaml
│       ├── cluster-udn.yaml
│       └── localnet.yaml
└── part-2-services-routes-egress/
    ├── README.md
    ├── 01-services-and-routes.md
    ├── 02-egress.md
    ├── 03-network-policies.md
    └── examples/
        ├── service-example.yaml
        ├── route-example.yaml
        ├── egress-policy.yaml
        └── network-policy.yaml
```

## Getting Started

1. Start with [Part 1](./part-1-udns/README.md) to understand the fundamentals of UDNs
2. Progress to [Part 2](./part-2-services-routes-egress/README.md) for advanced networking and security
3. Use the example YAML files in each part's `examples/` directory as starting points

## Prerequisites

- OpenShift cluster with Virtualization enabled
- Cluster admin or appropriate permissions to create NetworkAttachmentDefinitions
- Basic understanding of Kubernetes networking concepts

