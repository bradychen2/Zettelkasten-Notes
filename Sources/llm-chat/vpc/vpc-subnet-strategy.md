---
title: 在 AWS VPC 中要怎麼規劃 Subnet 策略？
tags: [reading-note, aws, vpc, subnet]
status: draft
source: Gemini share dea848184b75 (Published 2026-02-17 11:16 AM)
created: 2026-02-17
updated: 2026-02-17
---

# 在 AWS VPC 中要怎麼規劃 Subnet 策略？

## Abstract

- Subnet 規劃核心是把 VPC 分段，目標同時涵蓋 HA、安全與可擴展性。[[#^ref-subnet-goal|1]]
- Subnet 要跨 AZ 來做容錯；每個 subnet 綁定單一 AZ，不能跨 AZ。[[#^ref-subnet-az-scope|2]]
- Subnet 類型（public/private）與大小（CIDR）共同決定可用容量與連線模式。[[#^ref-subnet-sizing|4]]

## Purposes

1. **提升可用性與容錯**：用多個 AZ 分散資源，降低單一 AZ 故障的風險。[[#^ref-subnet-az-scope|2]]
2. **分離連線需求**：把「必須被網際網路直接到達」與「不應直接暴露」的資源用不同 subnet 型態隔離。[[#^ref-subnet-public-def|3]]
3. **避免容量不足**：用合適的 CIDR 讓 subnet 不會太小而影響擴容。[[#^ref-subnet-sizing|4]]
4. **提升營運可管理性**：用 tags 清楚標示 subnet 用途，讓規模變大後仍能維持可讀性。[[#^ref-subnet-tags|6]]

## Definition

- Subnet strategy：把 VPC 切成更小區段（subnets）的設計方法，用來滿足 HA、安全、scalability 等目標。[[#^ref-subnet-goal|1]]

## When to Use

- 你要在同一個 VPC 裡同時承載 public-facing 與 internal services，並希望能擴容且便於管理。[[#^ref-subnet-goal|1]]

## How It Works

1. **跨 AZ 規劃**：subnet 是 AZ-scoped，不跨 AZ；因此要用多個 AZ 來做高可用。[[#^ref-subnet-az-scope|2]]
2. **按連線型態分 subnet**：
   - Public subnet：放必須被網際網路直接到達的資源（例如 LB、web server）。[[#^ref-subnet-public-def|3]]
   - Private subnet：放不應直接暴露的資源（例如 app server、DB）。[[#^ref-subnet-private-def|7]]
3. **決定 CIDR 大小**：AWS subnet 可在 `/28` 到 `/16` 之間選擇；VPC 常建議先選較大的 primary CIDR（例如 `/16`）預留空間。[[#^ref-vpc-sizing|5]]
4. **補充控制面**：
   - subnet 層可選擇使用 NACL 來做額外的入/出站控制。[[#^ref-subnet-nacl|8]]
   - 用 tags 做一致的命名與分類。[[#^ref-subnet-tags|6]]

## Example (Checklist)

1. 選定 VPC primary CIDR（例如先以 `/16` 留餘裕）。[[#^ref-vpc-sizing|5]]
2. 至少選兩個 AZ，為每個 AZ 規劃 public 與 private subnets。[[#^ref-subnet-az-scope|2]]
3. 設定 subnet CIDR，確保大小落在 `/28` 到 `/16` 並符合容量需求。[[#^ref-subnet-sizing|4]]
4. 設定 NACL（若需要 subnet 層的額外防護）。[[#^ref-subnet-nacl|8]]
5. 設計 tags 規範（如 `Public-AZ-1`、`Database-AZ-2`）。[[#^ref-subnet-tags|6]]

## Pitfalls

- 把所有資源都放 public subnet：會讓暴露面增加，後續再「搬回 private」成本高。[[#^ref-subnet-public-def|3]]
- subnet CIDR 太小：即使架構正確也可能因位址耗盡而卡住擴容。[[#^ref-subnet-sizing|4]]
- 不用 tags：規模一大就很難快速判斷每個 subnet 的用途。[[#^ref-subnet-tags|6]]

## Related Notes

- [[Sources/llm-chat/vpc/cidr-basics|CIDR 基礎]]
- [[Sources/llm-chat/vpc/public-private-subnets-routing|Public vs Private Subnet 與路由]]
- [[Sources/llm-chat/vpc/nat-gateway-flow|NAT Gateway 流程]]
- [[Sources/llm-chat/three-tier-ha-architecture|三層式高可用架構]]

## References

1. "Planning a subnet strategy involves designing how to divide your Virtual Private Cloud (VPC) into smaller segments to optimize for high availability, security, and scalability." (Gemini 分享頁面 dea848184b75，body.txt 行 63) ^ref-subnet-goal
2. "A subnet itself is specific to a single AZ and cannot span across multiple ones." (Gemini 分享頁面 dea848184b75，body.txt 行 67) ^ref-subnet-az-scope
3. "Public Subnets: Use these for resources that must be directly reachable from the internet, such as load balancers or web servers." (Gemini 分享頁面 dea848184b75，body.txt 行 73) ^ref-subnet-public-def
4. "Subnet Sizing: In AWS, the smallest allowed subnet is a /28 (16 IP addresses) and the largest is a /16." (Gemini 分享頁面 dea848184b75，body.txt 行 83) ^ref-subnet-sizing
5. "VPC Sizing: Start with a large primary CIDR block (e.g., /16) to provide plenty of room for subnets." (Gemini 分享頁面 dea848184b75，body.txt 行 81) ^ref-vpc-sizing
6. "Organization: Use Tags to identify subnets by their purpose (e.g., \"Public-AZ-1\" or \"Database-AZ-2\") to make management easier as your infrastructure grows." (Gemini 分享頁面 dea848184b75，body.txt 行 93) ^ref-subnet-tags
7. "Private Subnets: Use these for resources that should not be directly accessible from the internet, such as application servers or databases." (Gemini 分享頁面 dea848184b75，body.txt 行 75) ^ref-subnet-private-def
8. "Security: Use Network ACLs as an optional layer of security at the subnet level to control inbound and outbound traffic." (Gemini 分享頁面 dea848184b75，body.txt 行 91) ^ref-subnet-nacl
