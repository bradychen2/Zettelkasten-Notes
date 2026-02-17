---
title: 連接多個網路時 CIDR 要注意什麼？VPC Peering、Transit Gateway、Hybrid 的差異？
tags: [reading-note, aws, vpc, connectivity]
status: draft
source: Gemini share dea848184b75 (Published 2026-02-17 11:16 AM)
created: 2026-02-17
updated: 2026-02-17
---
# 連接多個網路時 CIDR 要注意什麼？VPC Peering、Transit Gateway、Hybrid 的差異？

## Abstract

- VPC Peering 強調兩端 CIDR 不能重疊（no overlaps）。[[#^ref-peering-no-overlap|1]]
- Transit Gateway 用「集中式 hub」管理大量 VPC 的路由。[[#^ref-tgw-scale|2]]
- Hybrid connectivity 會牽涉 VPC CIDR 與 on-prem 網段（VPN/Direct Connect）的互動。[[#^ref-hybrid|3]]

## Purposes

1. **避免 CIDR 衝突**：跨 VPC/跨環境連線時，CIDR 重疊會讓路由與互通變得不可控。[[#^ref-peering-no-overlap|1]]
2. **支援大規模路由管理**：當 VPC 數量變多，用 Transit Gateway 以 hub 模式集中管理。[[#^ref-tgw-scale|2]]
3. **規劃雲地互通**：Hybrid 場景下要把 on-prem 網段一起納入 CIDR 與路由設計。[[#^ref-hybrid|3]]

## When to Use

- VPC Peering：少量 VPC 直接互連，且確保 CIDR 不重疊。[[#^ref-peering-no-overlap|1]]
- Transit Gateway：大量 VPC 互連或需要集中化路由治理。[[#^ref-tgw-scale|2]]
- Hybrid：要把 on-prem data center 與 VPC 串起來。[[#^ref-hybrid|3]]

## Pitfalls

- 先隨意挑 CIDR、後面才要互連：一旦出現重疊，常會被迫 re-IP 或大規模搬遷。[[#^ref-peering-no-overlap|1]]

## Related Notes

- [[llm_chat_learning_notes/vpc/cidr-basics|CIDR 基礎]]
- [[llm_chat_learning_notes/vpc/vpc-subnet-strategy|Subnet 策略規劃]]

## References

1. "VPC Peering: How CIDR blocks must be unique (no overlaps!) when connecting two VPCs directly. 🔗" (Gemini 分享頁面 dea848184b75，body.txt 行 185) ^ref-peering-no-overlap
2. "Transit Gateway: Managing CIDR routing at scale when you have dozens or hundreds of VPCs. 🏢" (Gemini 分享頁面 dea848184b75，body.txt 行 187) ^ref-tgw-scale
3. "Hybrid Cloud: How your VPC CIDR interacts with your on-premises data center range via VPN or Direct Connect. 🌍" (Gemini 分享頁面 dea848184b75，body.txt 行 189) ^ref-hybrid
