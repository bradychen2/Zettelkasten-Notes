---
title: Security Group Referencing 用「身份」表達信任關係，比 CIDR 更可維護
tags: [permanent-note, aws, security-group, least-privilege]
status: draft
language: zh-tw
domain: [aws]
topics: [security-group, least-privilege]
created: 2026-02-20
updated: 2026-02-20
---

# Security Group Referencing 用「身份」表達信任關係，比 CIDR 更可維護

## Note

- 最小權限的核心是只允許資源正常運作所需的最小流量（縮小暴露面）。[[Sources/llm-chat/sg/security-groups-least-privilege#^ref-lp-minimum-traffic|src]]
- 用 **Security Group referencing**（以 SG ID 作為規則 source/destination）能用「身份」描述信任關係，而不是把規則綁死在不穩定的 IP/CIDR 上。[[Sources/llm-chat/sg/security-groups-least-privilege#^ref-sg-ref|src]]

## Implications / Decisions

- 在多層架構中，把 inbound 規則寫成「只允許上一層的 SG」通常比「允許整段 subnet CIDR」更符合最小權限，也更容易隨著擴容維持正確性。[[Sources/llm-chat/sg/security-groups-least-privilege#^ref-sg-ref|src]]

## Related Notes

- [[Sources/llm-chat/three-tier-ha-architecture|三層式高可用架構]] — 用 SG referencing 組出 ALB -> backend -> DB 的信任鏈。 
- [[Sources/llm-chat/api-gateway/api-gateway-vpc-link-private-integration|API Gateway + VPC Link 私有整合]] — internal ALB 的 SG inbound 來源需要被收斂到 VPC Link。 

## Source Anchors

- [[Sources/llm-chat/sg/security-groups-least-privilege#^ref-lp-minimum-traffic|src]] least privilege
- [[Sources/llm-chat/sg/security-groups-least-privilege#^ref-sg-ref|src]] SG referencing

