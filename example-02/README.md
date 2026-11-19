# Example 02: network and compute as separate stacks

This is the same setup as `../initial-infra`, split into two Terraform root modules. Each module has its **own state file**.
`initial-infra/` is not changed.

```
example-02/
├── network/   VPC, IGW, 2 public subnets, route table, security group   -> network/terraform.tfstate
└── compute/   SSH key pair + EC2 instance (nginx)                       -> compute/terraform.tfstate
```

## How compute finds the network

`compute/` does **not** read the network state (no `terraform_remote_state`). It finds each network component with data sources that filter on tags:

| Component | Lookup (`compute/data.tf`) |
|---|---|
| VPC | `Name = <project>-vpc`, `Project = <project>` |
| Public subnets | in that VPC, `Tier = public`, `Project = <project>` |
| Security group | in that VPC, `Name = <project>-web-sg`, `Project = <project>` |

`project_name` defaults to `capstone-ex02`, so these lookups never match the VPC that `initial-infra` created (`Project = capstone`).
Both stacks must use the same `project_name` and `aws_region`.

## Key pair

`compute/` generates an ED25519 key with the `tls` provider and registers it as `<project>-key`.
The private key is written to `compute/<project>-key.pem` (mode 0400, git-ignored).
The private key is also stored in `compute/terraform.tfstate`, so keep that state file private.

## Usage

Apply the network first, then compute:

```bash
cd example-02/network
cp terraform.tfvars.example terraform.tfvars   # set allowed_ssh_cidr to your IP/32
terraform init && terraform apply

cd ../compute
cp terraform.tfvars.example terraform.tfvars
terraform init && terraform apply
terraform output ssh_command
```

Open `http://<instance_public_ip>` to see the nginx page.

## Tear down

Destroy in reverse order. The network cannot be deleted while the instance still uses it.

```bash
cd example-02/compute && terraform destroy
cd ../network       && terraform destroy
```

## Notes
- Default CIDR is `10.20.0.0/16`, so it does not overlap `initial-infra` (`10.0.0.0/16`).
- To recreate the EC2 instance, run `apply` or `destroy` in `compute/` only. The network and its state are not affected.
- If the network stack is not applied yet, `compute` plans fail with "no matching VPC found".
