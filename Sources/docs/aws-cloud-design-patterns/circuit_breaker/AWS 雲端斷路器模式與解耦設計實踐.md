---
title: AWS 雲端斷路器模式與解耦設計實踐
tags: [reading-note, aws, architecture, patterns, resiliency, circuit-breaker, decoupling]
status: draft
source: AWS 雲端斷路器模式與解耦設計實踐
---
# AWS 雲端斷路器模式與解耦設計實踐

## Abstract

- 透過「被調用方恢復後主動更新斷路器狀態為 CLOSED」來滿足 RTO，讓流量更快恢復。[[#^ref-callee-recovers-closed|1]]
- 直接做反向通知容易引入循環依賴與死結風險；用「外部狀態 + 中介資料層/工作流」來解耦。
- 把斷路器狀態外部化到 DynamoDB，讓工作流（如 Step Functions）讀取狀態決定路徑。[[#^ref-sfn-express|3]] [[#^ref-sfn-retry-decision|4]]

## Key Takeaways

1. **縮短復原時間（RTO）**：讓 callee 在恢復後主動把斷路器狀態更新為 `CLOSED`，加速流量恢復。[[#^ref-callee-recovers-closed|1]]
2. **避免循環依賴**：把「反向通訊」轉成對外部狀態（DynamoDB）的更新，降低編譯時/執行時依賴與死結風險。
3. **服務無關實作**：斷路器物件以「microservice-agnostic + API-driven」方式落地，避免架構/程式碼臃腫。[[#^ref-agnostic-api-driven|2]]
4. **外部化狀態管理**：斷路器狀態存於 DynamoDB，而非存於任一服務的記憶體。
5. **用工作流做路由決策**：工作流（如 Step Functions）讀取 DynamoDB 的狀態來決定請求路徑。[[#^ref-sfn-express|3]]
## When to Use

- 你有明確的 **RTO** 需求，希望「下游恢復後」能更快恢復流量，而不是等待呼叫端的探測或逾時窗口。
- 你想在導入「callee 反向通知/狀態更新」時，仍保持系統解耦並避免循環依賴。

## How It Works (Conceptual Flow)

1. 下游（callee）從故障/效能問題恢復。
2. callee 不直接呼叫上游，而是把斷路器狀態更新為 `CLOSED`（寫入外部狀態）。
3. 狀態集中存於 DynamoDB，避免各服務內部狀態不一致。
4. 工作流（如 Step Functions）在下次調用前讀取該表並決定路徑（例如是否允許流量恢復）。[[#^ref-sfn-express|3]] [[#^ref-sfn-retry-decision|4]]
## Concerns / Pitfalls

- **循環依賴與死結**：分散式架構中循環依賴會讓程式碼更複雜、維護負擔增加，甚至引發死結。
- **解耦手段要到位**：用中介資料層通訊，避免服務間直接的編譯時/運行時循環依賴。
- **反向通訊路徑的取捨**：callee 更新狀態確實引入反向路徑；要靠外部狀態存儲與 API 設計把它「轉成異步更新」以平衡解耦與效能。[[#^ref-agnostic-api-driven|2]]

## Related Notes

- [[什麼是斷路器（Circuit Breaker）模式？]]
- [[斷路器（Circuit Breaker）- 何時使用與顧慮]]
## References (aws-cloud-design-patterns.pdf)

1. "When the callee recovers... they can update the circuit status to CLOSED." (aws-cloud-design-patterns.pdf, p. 20) ^ref-callee-recovers-closed
2. "implement the circuit breaker object in a microservice-agnostic and API-driven way." (aws-cloud-design-patterns.pdf, p. 20) ^ref-agnostic-api-driven
3. "The sample solution uses express workflows in AWS Step Functions to implement the circuit breaker pattern." (aws-cloud-design-patterns.pdf, p. 22) ^ref-sfn-express
4. "The Step Functions state machine lets you configure the retry capabilities and decision-based control flow required..." (aws-cloud-design-patterns.pdf, p. 22) ^ref-sfn-retry-decision
