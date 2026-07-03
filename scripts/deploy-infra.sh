#!/bin/bash
set -e
cd deploy/terraform
terraform init
terraform apply -auto-approve
