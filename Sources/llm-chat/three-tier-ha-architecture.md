---
title: 在 AWS 上做高可用三層式架構（ALB + Private Backend + RDS）時，元件放哪裡？NAT 與 Endpoints 怎麼取捨？
tags: [reading-note, aws, architecture, ha, alb, asg, nat, vpc-endpoint]
status: draft
source: Gemini share dea848184b75 (Published 2026-02-17 11:16 AM)
created: 2026-02-17
updated: 2026-02-17
---

# 在 AWS 上做高可用三層式架構（ALB + Private Backend + RDS）時，元件放哪裡？NAT 與 Endpoints 怎麼取捨？

## Abstract

- 3-tier 是常見 production 架構：Web tier（ALB）在 public subnets，App/Data tiers 在 private subnets。[[#^ref-3tier-table|2]]
- 高可用通常至少跨兩個 AZ；ALB 與 backend 分散到多個 AZ。[[#^ref-ha-2az|1]]
- NAT per-AZ vs single NAT 是 HA vs cost 的權衡；VPC Endpoints 可降低對 NAT 的依賴並提升 AZ 韌性。[[#^ref-endpoints-strategy|9]]

## Purposes

1. **分層隔離風險**：只有 ALB 直接面向網際網路，backend/db 隱藏在 private subnets。[[#^ref-3tier-table|2]]
2. **提升可擴展性**：backend 透過 ASG 伸縮，ALB 做流量分配。[[#^ref-asg-private|4]]
3. **維持高可用**：跨 AZ 佈署，降低單一 AZ 故障衝擊。[[#^ref-ha-2az|1]]
4. **平衡成本與韌性**：NAT 的佈署方式與 endpoints 的導入影響成本、風險與可用性。[[#^ref-single-nat-risk|8]]

## How It Works

1. **跨 AZ 高可用**
   - 以至少兩個 AZ 分散基礎設施。[[#^ref-ha-2az|1]]
2. **3-tier 元件位置**
   - Web tier：ALB 在 public subnets。[[#^ref-3tier-alb|3]]
   - App tier：Backend API（EC2/containers）在 private subnets。[[#^ref-3tier-backend|5]]
   - Data tier：RDS 在 private subnets。[[#^ref-3tier-rds|6]]
3. **伸縮**
   - Backend 由 ASG 管理，依流量增減 instance。[[#^ref-asg-private|4]]
4. **NAT 的高可用 vs 成本**
   - 最佳實務：每個 AZ 一個 NAT Gateway。[[#^ref-nat-per-az|7]]
   - 節省成本：全 VPC 用單一 NAT，但會形成單點故障（SPOF）。[[#^ref-single-nat-spof|10]]
5. **Endpoints 作為替代/補強**
   - 若 private instances 主要存取 AWS services（S3/DynamoDB/CloudWatch），可用 gateway/interface endpoints。[[#^ref-endpoints-strategy|9]]
   - 可降低經 NAT 的資料量與費用，同時讓架構更具 AZ 韌性。[[#^ref-endpoints-benefit|11]]

## Example (Chain of Trust)

- 以 SG referencing 建立信任鏈（示意）：
  - ALB SG：允許 `443` 來自 `0.0.0.0/0`。[[#^ref-chain-alb|12]]
  - Backend SG：只允許來自 ALB 的 SG。[[#^ref-chain-backend|13]]
  - Database SG：只允許來自 Backend 的 SG。[[#^ref-chain-db|14]]

## Pitfalls

- 單一 NAT 的 AZ 故障風險：若 NAT 所在 AZ 出問題，其他 AZ 的 private subnets 會失去對外連線能力。[[#^ref-single-nat-risk|8]]
- 把所有對外依賴都綁在 NAT：若其實只需要存取 AWS 服務，可能更適合 endpoints。[[#^ref-endpoints-strategy|9]]

## Related Notes

- [[Sources/llm-chat/vpc/vpc-subnet-strategy|Subnet 策略規劃]]
- [[Sources/llm-chat/vpc/public-private-subnets-routing|Public vs Private Subnet 與路由]]
- [[Sources/llm-chat/vpc/nat-gateway-flow|NAT Gateway 流程]]
- [[Sources/llm-chat/sg/security-groups-least-privilege|Security Group 最小權限]]
- [[Sources/llm-chat/api-gateway/api-gateway-vpc-link-private-integration|API Gateway + VPC Link 私有整合]]

## References

1. "For high availability, the infrastructure is spread across at least two Availability Zones (AZs)." (Gemini 分享頁面 dea848184b75，body.txt 行 840) ^ref-ha-2az
2. "Tier\tComponent\tLocation\tFunction" (Gemini 分享頁面 dea848184b75，body.txt 行 842) ^ref-3tier-table
3. "Web Tier\tApplication Load Balancer (ALB) ⚖️\tPublic Subnets" (Gemini 分享頁面 dea848184b75，body.txt 行 843) ^ref-3tier-alb
4. "Your Backend API instances are managed by an Auto Scaling Group in the Private Subnets." (Gemini 分享頁面 dea848184b75，body.txt 行 862) ^ref-asg-private
5. "App Tier\tBackend API (EC2 or Containers) ⚙️\tPrivate Subnets" (Gemini 分享頁面 dea848184b75，body.txt 行 848) ^ref-3tier-backend
6. "Data Tier\tDatabase (RDS) 🗄️\tPrivate Subnets" (Gemini 分享頁面 dea848184b75，body.txt 行 853) ^ref-3tier-rds
7. "As you noted, the best practice for a production environment is to have one NAT Gateway in each Availability Zone." (Gemini 分享頁面 dea848184b75，body.txt 行 892) ^ref-nat-per-az
8. "The Risk: If AZ-1 (where your NAT Gateway lives) has an outage, the instances in AZ-2 and AZ-3 will lose all internet connectivity." (Gemini 分享頁面 dea848184b75，body.txt 行 904) ^ref-single-nat-risk
9. "The Strategy: Instead of a NAT Gateway, you can use Gateway Endpoints (which are free for S3/DynamoDB) or Interface Endpoints." (Gemini 分享頁面 dea848184b75，body.txt 行 910) ^ref-endpoints-strategy
10. "it becomes a \"Single Point of Failure.\"" (Gemini 分享頁面 dea848184b75，body.txt 行 916) ^ref-single-nat-spof
11. "The Benefit: This reduces the amount of data processed through the NAT Gateway" (Gemini 分享頁面 dea848184b75，body.txt 行 912) ^ref-endpoints-benefit
12. "ALB SG: Allows HTTPS (Port 443) from 0.0.0.0/0 (the world)." (Gemini 分享頁面 dea848184b75，body.txt 行 870) ^ref-chain-alb
13. "Backend SG: Allows traffic only from the ALB's Security Group ID." (Gemini 分享頁面 dea848184b75，body.txt 行 872) ^ref-chain-backend
14. "Database SG: Allows traffic only from the Backend's Security Group ID." (Gemini 分享頁面 dea848184b75，body.txt 行 874) ^ref-chain-db
