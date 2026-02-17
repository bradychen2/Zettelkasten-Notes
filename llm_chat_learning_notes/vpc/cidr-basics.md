---
title: CIDR 是什麼？如何用 prefix length 理解 IPv4 網段大小？
tags:
  - reading-note
  - networking
  - cidr
  - vpc
  - subnet
status: draft
source: Gemini share dea848184b75 (Published 2026-02-17 11:16 AM)
created: 2026-02-17
updated: 2026-02-17
---
# CIDR 是什麼？如何用 prefix length 理解 IPv4 網段大小？

## Abstract

- CIDR 用「`IP/前綴長度`」描述網段大小，取代傳統 class-based 切法。[[#^ref-cidr-def|1]]
- prefix length 決定哪些 bits 是網路位元，進而決定可用位址範圍大小。[[#^ref-cidr-prefix|3]]
- 常見例子：`/16`、`/24`、`/28` 對應不同的位址數量。[[#^ref-cidr-16|4]]

## Purposes

1. **統一表達網段大小**：用 `IP/前綴長度` 直接描述網段範圍，避免只靠 class-based 直覺推估。[[#^ref-cidr-def|1]]
2. **連結「表示法」與「容量」**：理解 prefix length 與可分配位址數的關係，能快速估算網段規模。[[#^ref-cidr-prefix|3]]
3. **建立 AWS VPC 規劃的基礎**：先掌握 `/16`、`/24`、`/28` 這類常見大小，後續才能談 VPC/subnet 規劃。[[#^ref-cidr-28|6]]

## Definition

- CIDR（Classless Inter-Domain Routing）：一種更有效率管理與分配 IP 位址的方法。[[#^ref-cidr-def|1]]
- 表示法通常是 `10.0.0.0/16` 這類形式（IP + prefix length）。[[#^ref-cidr-notation|2]]

## How It Works

1. **IPv4 結構**：IPv4 是 32 bits，常以 4 個 octets 表示。[[#^ref-ipv4-structure|7]]
2. **prefix length 的意義**：`/24` 代表 32 bits 中有 24 bits 固定為網路位元。[[#^ref-cidr-prefix|3]]
3. **範圍大小示例**：`/16`、`/24`、`/28` 分別代表不同數量的位址。[[#^ref-cidr-16|4]]

## Example

- 若你看到 `10.0.0.0/24`，可以先把它視為「比 `/16` 更小、比 `/28` 更大」的網段；來源文字也直接給出 `/24` 的位址數量作為直覺參考。[[#^ref-cidr-24|5]]

## Pitfalls

- 只記 `/16`、`/24` 的數字但不理解「prefix length = 固定的網路位元數」會讓後續 subnetting/路由設計很容易混淆。[[#^ref-cidr-prefix|3]]
- 把 CIDR 當成「只在 AWS 才有」：其實 CIDR 是通用概念，AWS 只是把它用在 VPC/subnet 的容量與隔離上。[[#^ref-cidr-def|1]]

## Related Notes

- [[llm_chat_learning_notes/vpc/vpc-subnet-strategy|Subnet 策略規劃]]
- [[llm_chat_learning_notes/vpc/public-private-subnets-routing|Public vs Private Subnet 與路由]]
- [[llm_chat_learning_notes/vpc/nat-gateway-flow|NAT Gateway 流程]]
- [[llm_chat_learning_notes/vpc/vpc-connectivity-peering-tgw-hybrid|多網路互連（Peering/TGW/Hybrid）]]

## References

1. "CIDR, which stands for Classless Inter-Domain Routing, is a method used to manage and allocate IP addresses more efficiently than the older \"class-based\" system 🏷️." (Gemini 分享頁面 dea848184b75，body.txt 行 21) ^ref-cidr-def
2. "It works by appending a slash and a number (called a prefix length) to an IP address, such as 10.0.0.0/16." (Gemini 分享頁面 dea848184b75，body.txt 行 23) ^ref-cidr-notation
3. "The Prefix: The number after the slash (e.g., /24) tells you how many of those 32 bits are fixed for the network." (Gemini 分享頁面 dea848184b75，body.txt 行 29) ^ref-cidr-prefix
4. "A /16 provides 65,536 addresses." (Gemini 分享頁面 dea848184b75，body.txt 行 33) ^ref-cidr-16
5. "A /24 provides 256 addresses." (Gemini 分享頁面 dea848184b75，body.txt 行 35) ^ref-cidr-24
6. "A /28 (the smallest allowed in an AWS VPC) provides 16 addresses." (Gemini 分享頁面 dea848184b75，body.txt 行 37) ^ref-cidr-28
7. "The Structure: An IPv4 address is made of 32 bits, divided into four 8-bit sections called \"octets\"." (Gemini 分享頁面 dea848184b75，body.txt 行 27) ^ref-ipv4-structure
