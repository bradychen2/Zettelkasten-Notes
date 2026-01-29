---
title: Centralized Outbound Routing with TGW (AWS CLI)
tags: [aws, networking, transit-gateway, vpc, nat, igw]
---

# Centralized Outbound Routing with TGW (AWS CLI)

## Overview
Hub-and-spoke design: Spoke VPCs (A/B) send all internet-bound traffic to a centralized egress VPC (C) that hosts NAT + IGW. TGW routes default traffic to the egress VPC and returns traffic back to spokes.

## Assumptions
- Spoke VPCs (A/B) exist with private subnets and their private route tables.
- Egress VPC (C) exists with:
  - **Public subnet** for NAT + IGW
  - **Private subnet(s)** for TGW attachment
- One TGW attachment subnet per AZ.

## Variables
```bash
REGION=us-east-1

# VPCs
VPC_A=vpc-aaaa
VPC_B=vpc-bbbb
VPC_E=vpc-eeee

# Subnets (private subnets for TGW attachments; one per AZ)
A_TGW_SUBNETS="subnet-a1 subnet-a2"
B_TGW_SUBNETS="subnet-b1 subnet-b2"
E_TGW_SUBNETS="subnet-e1 subnet-e2"   # private subnet(s) in egress VPC

# Route tables
RT_A_PRIVATE=rtb-aaaa
RT_B_PRIVATE=rtb-bbbb
RT_E_PRIVATE=rtb-epvt
RT_E_PUBLIC=rtb-epub

# Egress public subnet for NAT
E_PUBLIC_SUBNET=subnet-epub
```

## Step-by-step (AWS CLI)

### 1) Create the Transit Gateway
```bash
TGW_ID=$(aws ec2 create-transit-gateway \
  --description "Centralized egress TGW" \
  --region $REGION \
  --query 'TransitGateway.TransitGatewayId' --output text)
```

### 2) Create a TGW route table
```bash
TGW_RTB=$(aws ec2 create-transit-gateway-route-table \
  --transit-gateway-id $TGW_ID \
  --region $REGION \
  --query 'TransitGatewayRouteTable.TransitGatewayRouteTableId' --output text)
```

### 3) Create VPC attachments (A, B, and Egress)
```bash
ATT_A=$(aws ec2 create-transit-gateway-vpc-attachment \
  --transit-gateway-id $TGW_ID \
  --vpc-id $VPC_A \
  --subnet-ids $A_TGW_SUBNETS \
  --region $REGION \
  --query 'TransitGatewayVpcAttachment.TransitGatewayAttachmentId' --output text)

ATT_B=$(aws ec2 create-transit-gateway-vpc-attachment \
  --transit-gateway-id $TGW_ID \
  --vpc-id $VPC_B \
  --subnet-ids $B_TGW_SUBNETS \
  --region $REGION \
  --query 'TransitGatewayVpcAttachment.TransitGatewayAttachmentId' --output text)

ATT_E=$(aws ec2 create-transit-gateway-vpc-attachment \
  --transit-gateway-id $TGW_ID \
  --vpc-id $VPC_E \
  --subnet-ids $E_TGW_SUBNETS \
  --region $REGION \
  --query 'TransitGatewayVpcAttachment.TransitGatewayAttachmentId' --output text)
```

### 4) Associate attachments with the TGW route table
```bash
aws ec2 associate-transit-gateway-route-table \
  --transit-gateway-route-table-id $TGW_RTB \
  --transit-gateway-attachment-id $ATT_A \
  --region $REGION

aws ec2 associate-transit-gateway-route-table \
  --transit-gateway-route-table-id $TGW_RTB \
  --transit-gateway-attachment-id $ATT_B \
  --region $REGION

aws ec2 associate-transit-gateway-route-table \
  --transit-gateway-route-table-id $TGW_RTB \
  --transit-gateway-attachment-id $ATT_E \
  --region $REGION
```

### 5) Enable propagation for spoke CIDRs (return path)
```bash
aws ec2 enable-transit-gateway-route-table-propagation \
  --transit-gateway-route-table-id $TGW_RTB \
  --transit-gateway-attachment-id $ATT_A \
  --region $REGION

aws ec2 enable-transit-gateway-route-table-propagation \
  --transit-gateway-route-table-id $TGW_RTB \
  --transit-gateway-attachment-id $ATT_B \
  --region $REGION
```

### 6) Add default route on TGW to the egress VPC
```bash
aws ec2 create-transit-gateway-route \
  --transit-gateway-route-table-id $TGW_RTB \
  --destination-cidr-block 0.0.0.0/0 \
  --transit-gateway-attachment-id $ATT_E \
  --region $REGION
```

### 7) Egress VPC: IGW + NAT
```bash
# IGW
IGW_ID=$(aws ec2 create-internet-gateway \
  --region $REGION \
  --query 'InternetGateway.InternetGatewayId' --output text)

aws ec2 attach-internet-gateway \
  --internet-gateway-id $IGW_ID \
  --vpc-id $VPC_E \
  --region $REGION

# EIP for NAT
EIP_ALLOC=$(aws ec2 allocate-address --domain vpc --region $REGION \
  --query 'AllocationId' --output text)

# NAT in public subnet
NAT_ID=$(aws ec2 create-nat-gateway \
  --subnet-id $E_PUBLIC_SUBNET \
  --allocation-id $EIP_ALLOC \
  --region $REGION \
  --query 'NatGateway.NatGatewayId' --output text)
```

### 8) VPC route tables

#### Spoke private RTs → TGW
```bash
aws ec2 create-route \
  --route-table-id $RT_A_PRIVATE \
  --destination-cidr-block 0.0.0.0/0 \
  --transit-gateway-id $TGW_ID \
  --region $REGION

aws ec2 create-route \
  --route-table-id $RT_B_PRIVATE \
  --destination-cidr-block 0.0.0.0/0 \
  --transit-gateway-id $TGW_ID \
  --region $REGION
```

#### Egress private RT → NAT
```bash
aws ec2 create-route \
  --route-table-id $RT_E_PRIVATE \
  --destination-cidr-block 0.0.0.0/0 \
  --nat-gateway-id $NAT_ID \
  --region $REGION
```

#### Egress public RT → IGW + return routes to spokes
```bash
aws ec2 create-route \
  --route-table-id $RT_E_PUBLIC \
  --destination-cidr-block 0.0.0.0/0 \
  --gateway-id $IGW_ID \
  --region $REGION

# Return routes to spokes via TGW (replace with actual spoke CIDRs)
aws ec2 create-route \
  --route-table-id $RT_E_PUBLIC \
  --destination-cidr-block 10.10.0.0/16 \
  --transit-gateway-id $TGW_ID \
  --region $REGION

aws ec2 create-route \
  --route-table-id $RT_E_PUBLIC \
  --destination-cidr-block 10.20.0.0/16 \
  --transit-gateway-id $TGW_ID \
  --region $REGION
```

## Validation
```bash
aws ec2 describe-transit-gateway-route-tables \
  --transit-gateway-route-table-ids $TGW_RTB \
  --region $REGION

aws ec2 describe-transit-gateway-attachments \
  --filters Name=transit-gateway-id,Values=$TGW_ID \
  --region $REGION
```

> [!note]
> TGW attachments in the egress VPC must be in **private subnets**. If you place the attachment in a public subnet, IGW will drop traffic from spokes because instances do not have public IPs.

