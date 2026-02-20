---
title: NAT Gateway 如何讓 Private Subnet 對外連線但不被外界主動連入？
tags: [reading-note, aws, vpc, nat, routing]
status: draft
source: Gemini share dea848184b75 (Published 2026-02-17 11:16 AM)
created: 2026-02-17
updated: 2026-02-17
---

# NAT Gateway 如何讓 Private Subnet 對外連線但不被外界主動連入？

## Abstract

- private subnet 的 instance 以 private IP 出站，NAT Gateway 以 Elastic IP 對外，完成 SNAT。[[#^ref-nat-elastic-ip|3]]
- route table 會把 `0.0.0.0/0` 指向 NAT Gateway，形成 private subnet 的對外出口。[[#^ref-nat-rt-0|2]]
- 外界無法主動連到 private instance（inbound blocked by reachability / design），但 instance 可對外發起連線。[[#^ref-nat-inbound|5]]

## Purposes

1. **提供安全的對外出口**：讓 private instance 可對外抓更新/呼叫外部 API，同時避免外界主動連入。[[#^ref-nat-inbound|5]]
2. **隔離位址與可達性**：instance 仍使用 private IP；對外的公開位址由 NAT Gateway 的 Elastic IP 承擔。[[#^ref-nat-elastic-ip|3]]
3. **把「對外」變成可控路由**：透過 route table 明確把 `0.0.0.0/0` 指向 NAT Gateway。[[#^ref-nat-rt-0|2]]

## How It Works

1. **位址層（Private IP）**
   - private instance 依然從 private subnet 的 CIDR 範圍分配 private IP。[[#^ref-private-ip-assigned|1]]
2. **路由層（0.0.0.0/0 -> NAT）**
   - 在 private subnet 的 route table 設定 `0.0.0.0/0` 指向 NAT Gateway。[[#^ref-nat-rt-0|2]]
3. **轉換層（SNAT + Elastic IP）**
   - NAT Gateway 收到封包後，會把 private source IP 替換成自己的 Elastic IP。[[#^ref-nat-elastic-ip|3]]
   - 接著再透過 Internet Gateway (IGW) 把封包送出。[[#^ref-nat-via-igw|4]]
4. **可達性（Inbound vs Outbound）**
   - 外部使用者無法從網際網路主動對 private instance 建立連線（設計上不可達）。[[#^ref-nat-inbound|5]]

## Example

- 典型「private with NAT」：
  1. instance 送出封包，source 是 private IP。[[#^ref-private-ip-source|6]]
  2. route table 把 `0.0.0.0/0` 導向 NAT Gateway。[[#^ref-nat-rt-0|2]]
  3. NAT Gateway 以 Elastic IP 對外送出並經 IGW 出口。[[#^ref-nat-via-igw|4]]

## Pitfalls

- 忘記在 private subnet 的 route table 設定 `0.0.0.0/0` 指向 NAT Gateway：private subnet 會失去對外能力。[[#^ref-nat-rt-0|2]]
- 混淆「NAT Gateway 在 public subnet」與「private instance 在 private subnet」：NAT 在 public subnet 才能經 IGW 對外。[[#^ref-nat-via-igw|4]]

## Related Notes

- [[Sources/llm-chat/vpc/public-private-subnets-routing|Public vs Private Subnet 與路由]]
- [[Sources/llm-chat/vpc/vpc-subnet-strategy|Subnet 策略規劃]]
- [[Sources/llm-chat/ec2/private-ec2-access-methods|Private EC2 的登入方式]]
- [[Sources/llm-chat/three-tier-ha-architecture|三層式高可用架構]]

## References

1. "The EC2 instance is assigned a Private IP from the private subnet's CIDR range" (Gemini 分享頁面 dea848184b75，body.txt 行 149) ^ref-private-ip-assigned
2. "You define a route for 0.0.0.0/0 (all internet traffic)" (Gemini 分享頁面 dea848184b75，body.txt 行 153) ^ref-nat-rt-0
3. "The NAT Gateway receives it and replaces that private source IP with its own Elastic IP (a static, public IP)." (Gemini 分享頁面 dea848184b75，body.txt 行 161) ^ref-nat-elastic-ip
4. "The NAT Gateway then sends the packet through the Internet Gateway (IGW)." (Gemini 分享頁面 dea848184b75，body.txt 行 163) ^ref-nat-via-igw
5. "external users on the internet cannot initiate a connection to it." (Gemini 分享頁面 dea848184b75，body.txt 行 167) ^ref-nat-inbound
6. "The packet leaves the private subnet with its Private IP as the source." (Gemini 分享頁面 dea848184b75，body.txt 行 159) ^ref-private-ip-source
