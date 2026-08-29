# Production-Style 3-Tier Azure

Terraform implementation of the architecture in [plan.txt](plan.txt): Application
Gateway + WAF fronting an autoscaling VMSS web/app tier, a VNet-integrated
PostgreSQL Flexible Server in a private subnet, Azure Bastion for management
access, and Key Vault / Storage Account reachable via private endpoints.

## Layout

```
main.tf, variables.tf, outputs.tf   Root module - wires everything together
modules/network      VNet, 5 subnets, NSGs, NAT gateway for outbound egress
modules/dns          Private DNS zones for Postgres, Key Vault, Blob storage
modules/appgw        Application Gateway (WAF_v2) + WAF policy (OWASP 3.2)
modules/vmss         Linux VMSS (Ubuntu 22.04) + CPU-based autoscaling
modules/database     PostgreSQL Flexible Server, VNet-injected, private access
modules/bastion      Azure Bastion host
modules/keyvault     Key Vault (RBAC auth) + private endpoint
modules/storage      Storage Account (private) + private endpoint
```

Network layout matches plan.txt:

| Subnet | CIDR | Purpose |
|---|---|---|
| snet-appgw | 10.0.1.0/24 | Application Gateway |
| snet-webapp | 10.0.2.0/24 | VMSS (2-5 instances) |
| snet-db | 10.0.3.0/24 | PostgreSQL Flexible Server (delegated) |
| AzureBastionSubnet | 10.0.4.0/24 | Azure Bastion |
| snet-private-endpoints | 10.0.5.0/24 | Key Vault / Storage private endpoints |

## Usage

```bash
cp terraform.tfvars.example terraform.tfvars
# edit terraform.tfvars: set admin_ssh_public_key (or leave blank to auto-generate)

terraform init
terraform plan
terraform apply
```

After apply:
- Browse `terraform output appgw_public_ip` to hit the demo nginx page through
  the Application Gateway/WAF.
- Connect to a VMSS instance via Bastion (`terraform output bastion_fqdn` /
  Azure Portal > Bastion) using the admin username and either your own SSH
  key or the generated `generated_vmss_ssh_key.pem`.
- From a VM reachable inside the VNet (e.g. via Bastion), the Postgres FQDN
  (`terraform output postgres_server_fqdn`) resolves privately.

## Notable design decisions

- **State**: starts local. `versions.tf` has a commented `backend "azurerm"`
  block to switch to once a state storage account exists (chicken-and-egg
  problem on the very first run).
- **Key Vault networking**: public network access is left **enabled** so
  Terraform, running from outside the VNet, can write secrets (admin
  password, generated SSH private key) via the data plane. A private
  endpoint is still provisioned so in-VNet consumers get a private path. For
  a stricter posture, set `public_network_access_enabled = false` in
  `modules/keyvault/main.tf` and run Terraform from a host inside the VNet
  (e.g. through Bastion or a self-hosted CI runner) for secret writes.
  Storage Account and Postgres, by contrast, have public access fully
  disabled - the storage container is created via ARM (not the data plane)
  and Postgres administration doesn't require Terraform-initiated data-plane
  calls.
- **Egress**: the web/app subnet has a NAT Gateway so VMSS instances (no
  public IPs) can reach the internet for package installs / extensions,
  since Azure's legacy default-outbound-access is being deprecated.
- **App Gateway backend pool**: the pool is declared empty inside the `appgw`
  module and VMSS attaches itself to it via `application_gateway_backend_address_pool_ids`;
  `lifecycle.ignore_changes` on the pool avoids Terraform fighting over it.
- **Autoscaling**: VMSS scales 2-5 instances on CPU (>70% scale out, <25%
  scale in); the Application Gateway itself autoscales 1-3 capacity units.

## Costs

This deploys billable resources (Application Gateway WAF_v2, NAT Gateway,
Bastion, Postgres Flexible Server, Standard public IPs). Remember to
`terraform destroy` when done experimenting.
