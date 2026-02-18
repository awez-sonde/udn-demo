# Part 1: Understanding and Implementing UDNs

## Overview
This part of the blog series covers all User-Defined Network (UDN) types available in OpenShift Virtualization. You'll learn how to configure and use different UDN types to provide custom networking for your virtual machines.

## Table of Contents

1. [Primary Layer 2 UDN](./01-primary-layer2-udn.md)
   - Basic Layer 2 networking configuration
   - Testing in `udn-test1` namespace
   - Simple bridge-based networking

2. [Primary Layer 3 UDN](./02-primary-layer3-udn.md)
   - Layer 3 networking with IPAM
   - Testing in `udn-test2` namespace
   - IP address management and routing

3. [Secondary Layer 2 UDN](./03-secondary-layer2-udn.md)
   - Multi-homing setup
   - Adding secondary networks to VMs
   - Testing in `udn-test1` namespace

4. [Cluster UDN (CUDN)](./04-cluster-udn.md)
   - Creating cluster-wide UDNs
   - Making UDNs available across namespaces
   - Creating `cluster-udn-test1` and using it in `udn-test3`

5. [Localnet](./05-localnet.md)
   - Direct VM-to-physical network attachment
   - Bypassing the overlay network
   - Physical network integration

## Learning Path

Follow these guides in order to build your understanding progressively:
1. Start with Primary Layer 2 UDN for basic concepts
2. Move to Primary Layer 3 UDN to understand IPAM
3. Learn Secondary Layer 2 UDN for multi-homing
4. Explore Cluster UDN for namespace-wide networking
5. Finish with Localnet for physical network integration

## Next Steps

After completing Part 1, proceed to [Part 2: Services, Routes, Egress, and Network Policies](../part-2-services-routes-egress/README.md) to learn about advanced networking features and security.
