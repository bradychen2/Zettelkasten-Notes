---
title: NAT Gateway 是「受控出站」：路由決定出口、SNAT 決定對外位址
tags: [permanent-note, aws, vpc, nat, routing]
status: draft
language: zh-tw
domain: [aws]
topics: [vpc, nat-gateway, routing, snat]
created: 2026-02-20
updated: 2026-02-20
---

# NAT Gateway 是「受控出站」：路由決定出口、SNAT 決定對外位址

## Note

- Private subnet instance 的「能否對外」不是由 CIDR 或 subnet 名稱決定，而是由 **route table 是否把 `0.0.0.0/0` 指向 NAT Gateway** 決定。[[Sources/llm-chat/vpc/nat-gateway-flow#^ref-nat-rt-0|src]]
- NAT Gateway 的核心行為是 **SNAT**：把封包的 source 從 private IP 改成 NAT 的 Elastic IP，讓外部服務看到的是固定 public IP。[[Sources/llm-chat/vpc/nat-gateway-flow#^ref-nat-elastic-ip|src]]
- 這種設計使得 private instance 可以主動發起 outbound 連線，但外界無法主動對 private instance 建立 inbound 連線（設計上不可達）。[[Sources/llm-chat/vpc/nat-gateway-flow#^ref-nat-inbound|src]]

## Implications / Decisions

- 你要 debug private subnet 的「出不去」時，優先檢查 private route table 的 default route 是否正確指到 NAT Gateway。[[Sources/llm-chat/vpc/nat-gateway-flow#^ref-nat-rt-0|src]]
- 你需要固定 egress IP（例如 allowlist）時，關鍵在 NAT 的 Elastic IP，而不是 instance 自己的位址。[[Sources/llm-chat/vpc/nat-gateway-flow#^ref-nat-elastic-ip|src]]

## Related Notes

- [[Sources/llm-chat/vpc/public-private-subnets-routing|Public vs Private Subnet 與路由]] — 「public/private」由路由定義，不是 CIDR 本身。 
- [[Sources/llm-chat/three-tier-ha-architecture|三層式高可用架構]] — NAT 佈署（per-AZ vs single NAT）牽涉成本與可用性權衡。 

## Source Anchors

- [[Sources/llm-chat/vpc/nat-gateway-flow#^ref-nat-rt-0|src]] default route -> NAT
- [[Sources/llm-chat/vpc/nat-gateway-flow#^ref-nat-elastic-ip|src]] SNAT + Elastic IP
- [[Sources/llm-chat/vpc/nat-gateway-flow#^ref-nat-inbound|src]] inbound 不可達

