---
title: AWS VPC — Map of Content
tags: [moc, aws, vpc]
status: draft
language: zh-tw
domain: [aws]
topics: [vpc, networking]
created: 2026-02-20
updated: 2026-02-20
---

# AWS VPC — Map of Content

## Scope

- VPC / Subnet / Routing / NAT / VPC 互連（Peering/TGW/Hybrid）
- 不涵蓋：安全（SG/NACL）與 Compute（EC2）細節（改放到各自的 MOC）

## Map

### Concepts (Permanent Notes)

- [[Notes/aws/vpc/NAT-gateway-is-controlled-egress-via-SNAT|NAT Gateway 是受控出站（SNAT + 路由）]] — Private subnet egress 的核心心智模型

### Sources (Reading Notes)

- [[Sources/llm-chat/vpc/cidr-basics|CIDR 基礎]] — 網段表示法與容量直覺
- [[Sources/llm-chat/vpc/vpc-subnet-strategy|Subnet 策略規劃]] — AZ-scoped subnet、public/private 分層
- [[Sources/llm-chat/vpc/public-private-subnets-routing|Public vs Private Subnet 與路由]] — 公私本質由 route table 定義
- [[Sources/llm-chat/vpc/nat-gateway-flow|NAT Gateway 流程]] — SNAT、EIP、default route
- [[Sources/llm-chat/vpc/vpc-connectivity-peering-tgw-hybrid|多網路互連（Peering/TGW/Hybrid）]] — CIDR overlap 與 hub-and-spoke 取捨

### Playbooks (Procedures)

- [[Playbooks/aws/vpc/centralized_outbound_routing_with_TGW(AWS CLI)|Centralized Outbound Routing with TGW (AWS CLI)]] — Hub-and-spoke 集中 egress 的操作步驟

## Next Notes to Extract

- NAT per-AZ vs single NAT：成本/可用性權衡（從 [[Sources/llm-chat/three-tier-ha-architecture|三層式高可用架構]] 抽出）
- TGW hub-and-spoke：何時從 Peering 升級到 TGW（從 [[Sources/llm-chat/vpc/vpc-connectivity-peering-tgw-hybrid|多網路互連（Peering/TGW/Hybrid）]] 抽出）

