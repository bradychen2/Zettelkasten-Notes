---
title: API Gateway 如何安全地把流量送進 Private Subnet？VPC Link + Internal ALB 的 Private Integration 是什麼？
tags: [reading-note, aws, api-gateway, vpc-link, alb, private-integration]
status: draft
source: Gemini share dea848184b75 (Published 2026-02-17 11:16 AM)
created: 2026-02-17
updated: 2026-02-17
---

# API Gateway 如何安全地把流量送進 Private Subnet？VPC Link + Internal ALB 的 Private Integration 是什麼？

## Abstract

- Private Integration 的關鍵是 VPC Link：它把 public API Gateway 與 VPC 內部資源連起來。[[#^ref-vpc-link-connector|2]]
- 典型分層：API Gateway（public）-> VPC Link -> Internal ALB -> Backend services（private subnets）。[[#^ref-layering|3]]
- 落實最小權限時，Internal ALB 的 SG 需要只允許來自 VPC Link 的流量。[[#^ref-alb-sg-from-vpclink|9]]

## Purposes

1. **保護 private backend 不直接暴露**：API Gateway 在前面做「入口」，backend 藏在 private subnets。[[#^ref-layering|3]]
2. **把入口能力與內部執行解耦**：API Gateway 側偏向管理與保護，ALB 側偏向把流量分散到後端執行單元。[[#^ref-alb-internal|4]]
3. **維持最小權限**：用 SG 只允許必要來源，避免開到 `0.0.0.0/0`。[[#^ref-alb-sg-from-vpclink|9]]

## Definition

- VPC Link：API Gateway 的一個功能，用來啟用 private integrations。[[#^ref-vpc-link-def|1]]

## How It Works

1. **分層架構**
   - API Gateway（Public）：處理 API 前端需求。[[#^ref-api-gateway-public|5]]
   - VPC Link：把流量安全 tunnel 到 VPC。[[#^ref-vpc-link-connector|2]]
   - Internal ALB：位於 private subnets，接收 VPC Link 流量並做後端分流。[[#^ref-alb-internal|4]]
2. **安全性**
   - 流量留在 AWS 網路內，不走公開網際網路。[[#^ref-traffic-stays-aws|6]]

## Practical Implementation Steps

1. 建立 VPC Link：在 API Gateway console 的 VPC Links 建立。[[#^ref-create-vpclink-console|7]]
2. 設定 integration：method 使用 Private Integration。[[#^ref-private-integration|8]]
3. 指定目標：選 VPC Link 並提供 internal load balancer 的 DNS/ARN。[[#^ref-specify-link|10]]
4. 最小權限：調整 Internal ALB 的 SG inbound，只允許 VPC Link 來源。[[#^ref-alb-sg-from-vpclink|9]]

## Pitfalls

- 直接把 Internal ALB 的 SG 開到 `0.0.0.0/0`：違反最小權限。[[#^ref-alb-sg-from-vpclink|9]]
- 忽略 SG 設定：VPC Link 不會「自動繞過 SG」。[[#^ref-alb-sg-from-vpclink|9]]

## Related Notes

- [[llm_chat_learning_notes/sg/security-groups-least-privilege|Security Group 最小權限]]
- [[llm_chat_learning_notes/three-tier-ha-architecture|三層式高可用架構]]

## References

1. "A VPC Link is a feature of API Gateway that enables private integrations." (Gemini 分享頁面 dea848184b75，body.txt 行 1090) ^ref-vpc-link-def
2. "VPC Link: A dedicated connector that securely tunnels traffic from the API Gateway into your VPC." (Gemini 分享頁面 dea848184b75，body.txt 行 1048) ^ref-vpc-link-connector
3. "In this setup, the components are usually layered like this:" (Gemini 分享頁面 dea848184b75，body.txt 行 1044) ^ref-layering
4. "Application Load Balancer (Internal): Sits in your private subnets." (Gemini 分享頁面 dea848184b75，body.txt 行 1050) ^ref-alb-internal
5. "Amazon API Gateway (Public): Handles the \"front-end\" of your API, such as rate limiting, authentication (like JWT), and request validation." (Gemini 分享頁面 dea848184b75，body.txt 行 1046) ^ref-api-gateway-public
6. "Security: Traffic stays within the AWS network and never traverses the public internet." (Gemini 分享頁面 dea848184b75，body.txt 行 1094) ^ref-traffic-stays-aws
7. "you navigate to \"VPC Links\" and create a new one" (Gemini 分享頁面 dea848184b75，body.txt 行 1102) ^ref-create-vpclink-console
8. "you choose Private Integration as the integration type." (Gemini 分享頁面 dea848184b75，body.txt 行 1104) ^ref-private-integration
9. "Add an Inbound Rule to the Internal ALB's Security Group to allow traffic from the VPC Link's IP range." (Gemini 分享頁面 dea848184b75，body.txt 行 1114) ^ref-alb-sg-from-vpclink
10. "provide the DNS name or ARN of your internal load balancer." (Gemini 分享頁面 dea848184b75，body.txt 行 1106) ^ref-specify-link
