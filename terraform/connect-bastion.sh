#!/bin/bash

# Connect to bastion host using AWS nameservers for DNS resolution
ssh -i "$(pwd)/keys/deployment_key.pem" \
    -o "ProxyCommand=dig @ns-94.awsdns-11.com bastion.bunny970077.com +short | xargs -I{} nc {} 22" \
    ec2-user@bastion.bunny970077.com
