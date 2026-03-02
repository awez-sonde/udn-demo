# UDN Demo on Red Hat OpenShift Container Platform

This repository demonstrates how to design and validate VM networking with User-Defined Networks (UDN) in Red Hat OpenShift Container Platform.

## Start Here
For the complete Part 1 blog content, open:

- [`part-1-udns/README.md`](./part-1-udns/README.md)

This is the primary entry point for the walkthrough.

## UDN and CUDN Basics
Red Hat OpenShift Container Platform provides two main UDN APIs:

- `UserDefinedNetwork` (UDN): namespace-scoped resource for tenant or project-level network segmentation.
- `ClusterUserDefinedNetwork` (CUDN): cluster-scoped resource that can apply a network definition across multiple namespaces via label selectors.

In practical terms:

- Use UDN when a single namespace/team owns the network.
- Use CUDN when platform teams want consistent networking across many namespaces.
- Both are implemented through OVN-Kubernetes behavior in OpenShift.

UDN/CUDN and NAD are not mutually exclusive:

- UDN/CUDN is the higher-level OpenShift-native API for most segmentation use cases.
- `NetworkAttachmentDefinition` (NAD) remains useful for plugin-specific secondary networking scenarios.

## Repository Layout
- `part-1-udns/`: Part 1 blog and hands-on UDN/CUDN walkthroughs
- `part-1-udns/examples/`: runnable manifests (UDN/CUDN, VMs, bundles, cleanup)
- `gitops/`: OpenShift GitOps `Application` manifests for bootstrap and validation flows

## Documentation Sources
- Red Hat OpenShift Container Platform 4.21, Multiple networks:  
  https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/multiple_networks/index
- Red Hat OpenShift Container Platform 4.21, About user-defined networks:  
  https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html/multiple_networks/about-user-defined-networks


