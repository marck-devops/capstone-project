#!/bin/bash
# Run by the terraform_data.redis_setup provisioner (not user_data).
# Safe to re-run: every step is idempotent.
set -euxo pipefail

# On first boot SSH can come up before cloud-init finishes; wait so dnf isn't locked.
cloud-init status --wait || true

dnf install -y redis6
# Listen on all interfaces so the web instance can connect.
# Access is limited by the redis security group (web SG only).
sed -i -e 's/^bind .*/bind 0.0.0.0/' -e 's/^protected-mode yes/protected-mode no/' /etc/redis6/redis6.conf
systemctl enable redis6
systemctl restart redis6
