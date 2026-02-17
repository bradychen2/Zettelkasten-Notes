---
title: Public vs Private Subnet 差在哪？路由與位址分配如何影響對外可達性？
tags: [reading-note, aws, vpc, subnet, routing]
status: draft
source: Gemini share dea848184b75 (Published 2026-02-17 11:16 AM)
created: 2026-02-17
updated: 2026-02-17
---

# Public vs Private Subnet 差在哪？路由與位址分配如何影響對外可達性？

## Abstract

- 「公有/私有」不是 CIDR 本身決定，而是由 route table（與 IGW/NAT）決定。[[#^ref-rt-dont-know|2]]
- Public resources 仍有 private IP，但會額外對映到 public IPv4。[[#^ref-public-mapped|1]]
- 不論 public/private，AWS subnet 都保留特定 5 個位址做管理用途。[[#^ref-reserved-5|5]]

## Purposes

1. **釐清責任邊界**：CIDR 定義「範圍大小」，route table 定義「能否對外」。[[#^ref-rt-dont-know|2]]
2. **避免錯誤暴露**：理解 public resource 的 public IP 是額外對映，才能正確設計安全邊界。[[#^ref-public-mapped|1]]
3. **避免容量誤判**：把 AWS 保留位址納入容量估算，避免「看起來夠用，實際不夠用」。[[#^ref-reserved-5|5]]

## Definition

- Public subnet：其 route table 有 `0.0.0.0/0` 指向 Internet Gateway。[[#^ref-public-rt|3]]
- Private subnet：其 route table 通常把對外流量指向 NAT Gateway，或根本沒有對外路由。[[#^ref-private-rt|4]]

## How It Works

1. **位址分配（Address Assignment）**
   - Private/internal：從 subnet 的 CIDR 範圍分配 private IPv4。[[#^ref-private-addr|6]]
   - Internet-facing/public：同樣有 private IP，但會「額外對映」到 public IPv4 來讓外部可到達。[[#^ref-public-mapped|1]]
2. **route table 決定公私**
   - CIDR 本身不會「知道」它是 public 或 private，必須透過 route table 來定義。[[#^ref-rt-dont-know|2]]
3. **AWS subnet 保留位址**
   - AWS 會在每個 subnet CIDR block 保留 5 個位址作為管理用途。[[#^ref-reserved-5|5]]

## Implementation Notes

- 做 subnet 設計時，先確定每個 subnet 的 route table（尤其 `0.0.0.0/0`）指向何處，再決定放哪些資源。[[#^ref-public-rt|3]]
- 做容量規劃時，從總位址數扣掉 AWS 保留的 5 個。[[#^ref-reserved-5|5]]

## Pitfalls

- 把「有 public IP」當成「subnet 是 public」：本質上還是路由決定。[[#^ref-rt-dont-know|2]]
- 忽略保留位址：小 subnet（例如 `/28`）尤其容易踩到位址不足。[[#^ref-reserved-5|5]]

## Related Notes

- [[llm_chat_learning_notes/vpc/vpc-subnet-strategy|Subnet 策略規劃]]
- [[llm_chat_learning_notes/vpc/nat-gateway-flow|NAT Gateway 流程]]
- [[llm_chat_learning_notes/sg/security-groups-least-privilege|Security Group 最小權限]]
- [[llm_chat_learning_notes/three-tier-ha-architecture|三層式高可用架構]]

## References

1. "they are additionally mapped to a Public IPv4 address." (Gemini 分享頁面 dea848184b75，body.txt 行 109) ^ref-public-mapped
2. "The CIDR block doesn't \"know\" if it's public or private until you tell the Route Table how to handle traffic:" (Gemini 分享頁面 dea848184b75，body.txt 行 113) ^ref-rt-dont-know
3. "Public Subnets: The route table includes a path for 0.0.0.0/0 (all unknown traffic) pointing to an Internet Gateway." (Gemini 分享頁面 dea848184b75，body.txt 行 115) ^ref-public-rt
4. "Private Subnets: The route table typically points internet-bound traffic to a NAT Gateway or has no route to the internet at all." (Gemini 分享頁面 dea848184b75，body.txt 行 117) ^ref-private-rt
5. "AWS always reserves 5 IP addresses within every subnet CIDR block for networking management:" (Gemini 分享頁面 dea848184b75，body.txt 行 121) ^ref-reserved-5
6. "Internal (Private) Resources: These always use a Private IPv4 address from the CIDR range you assigned to the subnet." (Gemini 分享頁面 dea848184b75，body.txt 行 107) ^ref-private-addr
