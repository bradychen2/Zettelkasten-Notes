---
title: AWS Security Group 如何做最小權限？Referencing、Strict Egress、以及 NACL 的角色
tags: [reading-note, aws, security-group, nacl, least-privilege]
status: draft
source: Gemini share dea848184b75 (Published 2026-02-17 11:16 AM)
created: 2026-02-17
updated: 2026-02-17
---

# AWS Security Group 如何做最小權限？Referencing、Strict Egress、以及 NACL 的角色

## Abstract

- 最高安全標準以最小權限（Least Privilege）為核心：只允許必要的最小流量。[[#^ref-lp-minimum-traffic|1]]
- Security Group referencing 是關鍵實務：用 SG ID 作為 source/destination，不依賴不穩定的 IP。[[#^ref-sg-ref|2]]
- SG 是 stateful、NACL 是 stateless；這影響你是否需要另外放行回程流量。[[#^ref-sg-stateful|6]]

## Purposes

1. **縮小暴露面**：只允許資源正常運作所需的最小 traffic。[[#^ref-lp-minimum-traffic|1]]
2. **提升可維護性與可擴展性**：用 SG referencing 讓擴容時不用頻繁改規則。[[#^ref-sg-ref|2]]
3. **降低操作錯誤**：少寫 CIDR/IP，改用 SG identity 來描述信任關係。[[#^ref-sg-ref|2]]
4. **建立分層防護**：SG 做 instance-level，必要時 NACL 做 subnet-level 粗顆粒防護。[[#^ref-nacl-second-layer|8]]

## How It Works

1. **Least Privilege 原則**
   - 目標是「只允許必要流量」。[[#^ref-lp-minimum-traffic|1]]
2. **Security Group Referencing**
   - 以 SG ID 作為規則來源/目的，而非固定 IP/CIDR。[[#^ref-sg-ref|2]]
   - 常見做法：web tier 只允許來自 ALB 的 SG。[[#^ref-sg-web-from-alb|3]]
3. **管理管理面（SSH）**
   - 不要對全世界開放 SSH（`0.0.0.0/0`）。[[#^ref-no-ssh-world|4]]
   - 一個替代方向是用 Session Manager，達到不需要開 inbound ports 的效果。[[#^ref-ssm-no-inbound|5]]
4. **Stateful vs Stateless**
   - SG 是 stateful（回程自動允許），NACL 是 stateless（回程要明確放行）。[[#^ref-sg-stateful|6]]

## Example (Pattern)

- 3-tier 常見「信任鏈」：
  - `SG-ALB` -> `SG-Web`：只允許 `SG-ALB` 來源進入 web tier。[[#^ref-sg-web-from-alb|3]]
  - `SG-Web` -> `SG-DB`：DB inbound 只允許 web tier 的 SG。[[#^ref-db-inbound-from-web|7]]

## Pitfalls

- 用 CIDR 大範圍放行（例如整個 private subnet CIDR）：容易破壞最小權限的精神。[[#^ref-lp-minimum-traffic|1]]
- 忽略 NACL 的 stateless 特性：只放 inbound 不放 outbound/ephemeral ports 會造成連線卡住。[[#^ref-sg-stateful|6]]

## Related Notes

- [[llm_chat_learning_notes/three-tier-ha-architecture|三層式高可用架構]]
- [[llm_chat_learning_notes/vpc/public-private-subnets-routing|Public vs Private Subnet 與路由]]
- [[llm_chat_learning_notes/ec2/ssh-agent-forwarding-troubleshooting|SSH Agent Forwarding 與排錯]]
- [[llm_chat_learning_notes/api-gateway/api-gateway-vpc-link-private-integration|API Gateway + VPC Link 私有整合]]

## References

1. "you only allow the absolute minimum traffic necessary for a resource to function" (Gemini 分享頁面 dea848184b75，body.txt 行 576) ^ref-lp-minimum-traffic
2. "Instead of typing in IP addresses or CIDR blocks (like 10.0.1.0/24), you can set the Source of a rule to be another Security Group ID." (Gemini 分享頁面 dea848184b75，body.txt 行 582) ^ref-sg-ref
3. "The Rule: In SG-Web, you allow traffic on Port 80/443 only from SG-ALB." (Gemini 分享頁面 dea848184b75，body.txt 行 586) ^ref-sg-web-from-alb
4. "Never use 0.0.0.0/0 for SSH (Port 22): This opens your instance to the entire world." (Gemini 分享頁面 dea848184b75，body.txt 行 592) ^ref-no-ssh-world
5. "use AWS Systems Manager Session Manager, which requires no open inbound ports at all!" (Gemini 分享頁面 dea848184b75，body.txt 行 596) ^ref-ssm-no-inbound
6. "Stateful (Return traffic is automatic)" (Gemini 分享頁面 dea848184b75，body.txt 行 631) ^ref-sg-stateful
7. "Referencing the Security Group ID of the web servers in the database's inbound rules." (Gemini 分享頁面 dea848184b75，body.txt 行 644) ^ref-db-inbound-from-web
8. "production environments also use Network ACLs at the subnet level as a second layer of \"coarse-grained\" security." (Gemini 分享頁面 dea848184b75，body.txt 行 608) ^ref-nacl-second-layer
