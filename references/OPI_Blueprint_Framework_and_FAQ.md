# OPI Blueprint - Framework & FAQ

Prepared for the OPI Technical Steering Committee
Prepared by WorldTech IT - Josh Brooks, Chief Solutions Architect - josh@worldtechit.com

## What is an OPI Blueprint (Intent and Goals)?

An OPI Blueprint is an example architecture that shows how to operationalize an open-source component within the OPI ecosystem. Rather than presenting raw code, APIs, or RFC specifications, a Blueprint takes an OPI-supported technology and demonstrates a practical, real-world deployment pattern that an enterprise customer or systems integrator could replicate.

The intent is to:

- Accelerate adoption by bridging the gap between OPI's open-source projects and production-ready deployments. Customers don't buy RFC adoption - they buy outcomes.
- Showcase the value of IPU/DPU technology in offloading complex networking, security, and storage functions to dedicated hardware, freeing host CPU cores for higher-value workloads.
- Drive services engagement by pairing the Blueprint with the integrator or partner who built it, so that enterprises interested in deploying the solution have a clear path to professional services, support, and hardware procurement.
- Strengthen the OPI vendor ecosystem by demonstrating multi-vendor interoperability across hardware (Dell, Intel, Marvell), software (F5 BIG-IP Next, NGINX, Red Hat OpenShift), and infrastructure automation (Terraform, Ansible).

## What constitutes a Blueprint (Deliverables)?

A complete Blueprint should include the following deliverables:

1. **Reference Architecture Diagram** - A visual topology showing the hardware, software, and network components and how they interconnect. Should be understandable by a solutions architect or IT decision-maker, not just a developer.
2. **Bill of Materials (BOM)** - A list of validated hardware (e.g., Dell chassis, Intel IPU E2100), software versions (e.g., RHEL 9.x, BIG-IP Next for K8s), and any licensing requirements.
3. **Deployment Guide** - Step-by-step documentation covering installation, configuration, and validation. Should include infrastructure-as-code artifacts (Terraform modules, Ansible playbooks, Helm charts, YAML manifests) where applicable.
4. **Use Case Narrative** - A description of the business problem the Blueprint solves, the target persona (e.g., network architect, platform engineer, CISO), and why IPU/DPU offload matters for this workload.
5. **Validation/Test Results** - Evidence that the Blueprint works as documented. Performance benchmarks, screenshots, or recorded walkthroughs.
6. **Partner/Integrator Attribution** - Clear branding and contact information for the contributing partner(s), so end-customers know who built it and who can help them operationalize it.

## How is it different from a Technical Demo?

A Technical Demo proves that a technology works. A Blueprint shows how to put it into production.

| Dimension | Technical Demo | Blueprint |
|---|---|---|
| Audience | Developers, project contributors | Solutions architects, IT decision-makers, enterprise customers |
| Purpose | Validate that the OPI API/framework functions correctly on target hardware | Show a complete, deployable solution pattern with real-world applicability |
| Scope | Single feature or integration point (e.g., NGINX proxy on a Marvell OCTEON DPU) | End-to-end architecture including HW, OS, orchestration, networking, and application layers |
| Depth | Often tied to RFCs, API specs, and low-level implementation details | Focused on operational readiness: how to deploy, manage, and scale |
| Output | Working proof-of-concept, often ephemeral or lab-only | Documented reference architecture with IaC artifacts, BOM, and deployment guide |
| Reusability | Limited - typically requires deep OPI expertise to reproduce | High - designed so an integrator or customer can replicate independently |
| Branding | OPI project branding only | OPI + contributing partner branding (e.g., WorldTech IT, Dell, Red Hat) |

In short: Technical Demos live in the world of development and validation. Blueprints live in the world of adoption and services. The Demo answers "does it work?" The Blueprint answers "how do I deploy this at my company?"

## How do Blueprints tie in to OPI?

Blueprints are the adoption arm of the OPI Project. The OPI Project's core mission is to create a vendor-neutral, open-source framework of APIs and tools for managing IPUs and DPUs. That work produces standardized interfaces, reference implementations, and tested integrations, but it doesn't inherently show an enterprise customer how to operationalize those components.

Blueprints close that gap by:

- Consuming OPI APIs and tools in validated, end-to-end architectures that prove multi-vendor interoperability.
- Providing the "last mile" between OPI's open-source projects (opi-api, sztp, DPU Operator) and what a customer actually needs to stand up in their data center.
- Creating a feedback loop where real-world deployment patterns surface gaps or enhancements needed in the OPI framework itself (e.g., the TSC discussion around a supportability audit and DPU/IPU hardware status matrix).
- Engaging OPI member vendor ecosystems (Dell, Intel, Red Hat, F5, Marvell) by demonstrating their products working together under the OPI umbrella, which strengthens the business case for continued investment in the project.

## I have a Blueprint idea - what should I do next?

1. **Draft a one-pager.** Describe the use case, target audience, which OPI components it exercises, the hardware/software stack, and who the contributing partner(s) would be. Keep it concise - this is a pitch, not a design doc.
2. **Bring it to the TSC.** Present the one-pager during a TSC meeting. The TSC evaluates alignment with project priorities, lab resource availability, and overlap with existing work.
3. **Get resource alignment.** Confirm who is contributing engineering time, whether the OPI Lab has the necessary hardware provisioned (historically a bottleneck), and agree on a realistic timeline with guard rails around time commitment.
4. **Build, document, and validate.** Stand up the solution in the OPI Lab (or a contributing partner's lab), capture all deliverables (architecture diagram, BOM, deployment guide, test results), and ensure branding/attribution is in place.
5. **Publish and present.** Once validated, the Blueprint gets published to the OPI Lab/repository and can be showcased at events (OCP Global Summit, GTC, Red Hat Summit, etc.) and through OPI marketing channels.

## How can end-customers benefit from the Blueprints?

- **Reduced time-to-value.** Start from a validated reference architecture and adapt it, instead of piecing together IPU/DPU infrastructure from scratch.
- **Vendor-neutral confidence.** Built on OPI's open standards, so customers aren't locked into a single vendor's proprietary stack and can swap components while keeping the same deployment pattern.
- **Clear path to professional services.** Each Blueprint identifies the partner/integrator who built it.
- **TCO visibility.** The BOM and architecture diagram give customers a concrete understanding of procurement and deployment footprint.
- **De-risked evaluation.** Blueprints live in the OPI Lab can be demonstrated or trialed before customers commit budget.

## Where do these Blueprints reside?

- **OPI Lab (Physical/Virtual).** The Linux Foundation-hosted OPI Lab is the primary environment where Blueprints are built and validated - the actual IPU/DPU/server hardware lives here. Contributing partners may host complementary lab environments to accelerate development when OPI Lab provisioning timelines are a constraint.
- **OPI GitHub Repository (Digital).** All Blueprint documentation, IaC artifacts, deployment guides, and architecture diagrams should be published to the OPI project's GitHub (e.g., under `opi-poc` or a dedicated blueprints repository) - version-controlled, community-accessible, maintainable over time.
- **OPI Website / Marketing Channels.** High-level summaries and architecture diagrams should also be published to OPI's public-facing channels.

Key principle: a Blueprint should be reproducible by anyone with the right hardware and the published documentation. It should not require access to a specific lab instance to understand or replicate.

## Does OPI prefer one Blueprint over another?

OPI does not mandate a ranked priority list, but practical factors make some Blueprints more strategically valuable:

- **Multi-vendor interoperability** - e.g., Dell chassis + Intel IPU + F5 BIG-IP Next + Red Hat OpenShift - reinforces OPI's vendor-neutrality value proposition.
- **Actively maintained components** - the TSC is working through a source audit and supportability assessment; Blueprints on well-supported components with clear community/vendor backing get prioritized.
- **Customer demand signal** - use cases with known enterprise demand (zero-touch provisioning, multi-tenant isolation on IPU/DPU, Kubernetes-native network function offload) get more traction.
- **Partner commitment** - a Blueprint with a committed contributing partner who will invest engineering time, maintain docs, and stand behind the solution carries more weight.

Bottom line: the best Blueprint solves a real customer problem, uses actively maintained OPI components on validated hardware, involves multiple OPI member vendors, and has a committed partner behind it ready to support adoption.
