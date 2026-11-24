# Example 04: shared modules + SSM access to Redis

Same web + Redis setup as `../03-example`, with two differences:

1. It uses the **shared modules in `../modules/`** rather than a local copy.
2. The private Redis instance gets an **IAM role with `AmazonSSMManagedInstanceCore`**, so you can open a shell on it with **AWS Systems Manager Session Manager**. You don't need SSH, a jump host or open inbound ports for this.

```
capstone-project/
├── modules/
│   ├── network/           VPC, subnets, route tables, optional NAT, S3 gateway endpoint,
│   │                      optional SSM interface endpoints (ssm, ssmmessages, ec2messages)
│   ├── security_groups/   web SG and redis SG
│   ├── iam/               EC2 role + instance profile with AmazonSSMManagedInstanceCore
│   └── compute/           key pair, web + redis instances (optional instance profiles), provisioners
└── 04-example/            root: provider + module calls (one state file)
```

## How SSM reaches the private instance

Redis has no public IP. The SSM agent (preinstalled on Amazon Linux 2023) must reach the `ssm`, `ssmmessages` and `ec2messages` services over HTTPS. It can do that in one of two ways:

| Setting | Path to SSM | Cost |
|---|---|---|
| `enable_ssm_endpoints = true` (default) | Interface endpoints in the private subnets, private DNS on, SG allows 443 from the VPC CIDR | 3 endpoints × number of private subnets, billed hourly + per GB |
| `enable_nat_gateway = true` | Through the NAT gateway to the public SSM endpoints | NAT hourly + data |

A validation requires at least one of the two.

## Usage

```bash
cd 04-example
cp terraform.tfvars.example terraform.tfvars   # set allowed_ssh_cidr etc.
terraform init
terraform apply
terraform output app_url
```

Connect to Redis with Session Manager. You need the AWS CLI plus the [session-manager-plugin](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html):

```bash
$(terraform output -raw redis_ssm_command)
# then on the instance:
redis6-cli ping
```

After the instance boots, the agent can take a few minutes to register. Check with:

```bash
aws ssm describe-instance-information --filters Key=InstanceIds,Values=$(terraform output -raw redis_instance_id)
```

SSH through the web host still works (`terraform output redis_ssh_command`). The provisioners use SSH to configure the instances.

## Tear down

```bash
terraform destroy
```

## Notes
- Default CIDR is `10.40.0.0/16` and `project_name` is `capstone-ex04`. Neither collides with 01–03.
- IAM names: `capstone-ex04-redis-ssm-role` / `capstone-ex04-redis-ssm-profile`.
- Requires Terraform >= 1.9.
