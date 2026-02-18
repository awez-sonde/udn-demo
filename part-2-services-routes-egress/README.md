# Part 2: Services, Routes, Egress, and Network Policies

## Overview
This part of the blog series covers advanced networking features and security for virtual machines using User-Defined Networks in OpenShift Virtualization. You'll learn how to expose VMs via services and routes, configure egress policies, and secure traffic with network policies.

## Table of Contents

1. [Services & Routes](./01-services-and-routes.md)
   - Exposing VMs via Kubernetes Services
   - Creating Routes for external access
   - Validating ingress connectivity
   - Service types and configurations

2. [Egress](./02-egress.md)
   - Configuring egress IPs
   - Egress policies and rules
   - External access control
   - Egress router configuration

3. [Network Policies](./03-network-policies.md)
   - Securing traffic with network policies
   - Ingress and egress rules
   - Policy enforcement
   - Best practices for network security

## Learning Path

Follow these guides to understand how to:
1. Expose your VMs to the cluster and external networks using Services and Routes
2. Control outbound traffic with Egress policies
3. Secure your network traffic with Network Policies

## Prerequisites

Before starting Part 2, you should have completed Part 1 and understand:
- How to create and configure UDNs
- How to attach networks to VMs
- Basic networking concepts in Kubernetes

## Next Steps

After completing Part 2, you'll have a comprehensive understanding of:
- Exposing VMs via Services and Routes
- Controlling egress traffic
- Securing network traffic with policies
