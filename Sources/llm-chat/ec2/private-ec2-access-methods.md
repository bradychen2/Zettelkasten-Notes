---
title: 沒有 Public IP 的 Private Subnet EC2 要怎麼安全登入操作？
tags: [reading-note, aws, ec2, access, bastion, ssm]
status: draft
source: Gemini share dea848184b75 (Published 2026-02-17 11:16 AM)
created: 2026-02-17
updated: 2026-02-17
---

# 沒有 Public IP 的 Private Subnet EC2 要怎麼安全登入操作？

## Abstract

- private subnet instance 沒有 public IP，無法直接從網際網路被連到，因此需要「跳板」或「受管控的連線方式」。[[#^ref-private-no-public-ip|1]]
- 常見三種：Bastion host、SSM Session Manager、EC2 Instance Connect Endpoint。[[#^ref-3-ways|2]]
- SSM 被描述為不需要開放 SSH 22 與 public IP 的現代 best practice。[[#^ref-ssm-best-practice|6]]

## Purposes

1. **維持 private subnet 隔離性**：在不暴露 public IP 的前提下仍能維運/配置。[[#^ref-private-no-public-ip|1]]
2. **降低 SSH 暴露面**：用 SSM 之類方式把「登入通道」移到受管控的管理平面。[[#^ref-ssm-best-practice|6]]
3. **提供多種權衡選項**：依安全性、操作便利性、成熟度選擇不同連線方式。[[#^ref-3-ways|2]]

## How It Works

1. **Bastion Host / Jump Box**
   - 在 public subnet 放一台小且 hardened 的 EC2 作為入口。[[#^ref-bastion-public|3]]
   - 先 SSH 到 Bastion，再從 Bastion SSH 到 private instance。[[#^ref-bastion-path|4]]
   - private instance 的 Security Group 只允許 Bastion 來源的 SSH（Port 22）。[[#^ref-bastion-sg|5]]
2. **AWS Systems Manager Session Manager**
   - 被描述為現代推薦 best practice：不需要 open SSH port 22，也不需要 public IP。[[#^ref-ssm-best-practice|6]]
   - 可直接從 AWS Console browser 開啟 terminal session（前提是 agent/路由/IAM 等條件滿足）。[[#^ref-ssm-console|7]]
3. **EC2 Instance Connect Endpoint**
   - 新一點的功能：不需要 public IP 或 bastion。[[#^ref-eic-no-bastion|8]]
   - 在 VPC 建 endpoint，透過 AWS CLI 把流量 tunnel 到 private instance。[[#^ref-eic-tunnel|9]]

## Pitfalls

- 把 private instance 的 SSH 來源開到廣泛 CIDR：會破壞「只能從受控入口到達」的設計初衷。[[#^ref-bastion-sg|5]]
- 只規劃 Bastion，但沒有建立後續的權限/稽核與替代方案（例如 SSM）。[[#^ref-ssm-best-practice|6]]

## Related Notes

- [[Sources/llm-chat/ec2/ssh-agent-forwarding-troubleshooting|SSH Agent Forwarding 與排錯]]
- [[Sources/llm-chat/sg/security-groups-least-privilege|Security Group 最小權限]]
- [[Sources/llm-chat/vpc/public-private-subnets-routing|Public vs Private Subnet 與路由]]
- [[Sources/llm-chat/vpc/nat-gateway-flow|NAT Gateway 流程]]

## References

1. "instances in a private subnet don't have public IP addresses" (Gemini 分享頁面 dea848184b75，body.txt 行 197) ^ref-private-no-public-ip
2. "There are three main ways to achieve this. Let's explore how they work:" (Gemini 分享頁面 dea848184b75，body.txt 行 199) ^ref-3-ways
3. "This is a classic method where you place a small, hardened EC2 instance in a public subnet." (Gemini 分享頁面 dea848184b75，body.txt 行 203) ^ref-bastion-public
4. "You SSH into the Bastion Host first" (Gemini 分享頁面 dea848184b75，body.txt 行 205) ^ref-bastion-path
5. "only allow SSH traffic (Port 22)" (Gemini 分享頁面 dea848184b75，body.txt 行 207) ^ref-bastion-sg
6. "This is the modern, recommended \"best practice\" because it doesn't require an open SSH port (Port 22) or a public IP!" (Gemini 分享頁面 dea848184b75，body.txt 行 211) ^ref-ssm-best-practice
7. "you can start a secure terminal session directly from the AWS Console browser." (Gemini 分享頁面 dea848184b75，body.txt 行 213) ^ref-ssm-console
8. "This is a newer feature that allows you to connect to instances in a private subnet without needing a public IP or a Bastion Host." (Gemini 分享頁面 dea848184b75，body.txt 行 217) ^ref-eic-no-bastion
9. "your traffic is tunneled through this endpoint" (Gemini 分享頁面 dea848184b75，body.txt 行 219) ^ref-eic-tunnel
