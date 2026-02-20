---
title: 斷路器（Circuit Breaker）- 何時使用與顧慮
tags:
  - reading-note
  - architecture
  - patterns
  - resiliency
  - circuit-breaker
status: draft
source: aws-cloud-design-patterns.pdf
---
# 斷路器（Circuit Breaker）- 何時使用與顧慮

> 先看定義與意圖：[[什麼是斷路器（Circuit Breaker）模式？]]
> 延伸：[[AWS 雲端斷路器模式與解耦設計實踐]]

## 摘要

- 何時使用：當呼叫「大概率會失敗」或下游高延遲導致呼叫端超時/同步呼叫受阻時。[[#^ref-app-fail|1]] [[#^ref-app-high-latency-timeout|2]] [[#^ref-app-sync-unavailable|3]]
- 顧慮：斷路器要做成服務無關、可管理（可強制開/關）、避免逾時被多執行緒延長，以及具備可觀測性（logging）。[[#^ref-issue-agnostic-api|4]] [[#^ref-issue-admin-open-close|8]] [[#^ref-issue-expiration-not-endless|7]] [[#^ref-issue-logging-open|9]]

## 何時使用（Applicability）

1. 呼叫端發出的請求「大概率會失敗」時。[[#^ref-app-fail|1]]
2. 下游服務高延遲造成呼叫端超時時（例如慢速 DB 連線）。[[#^ref-app-high-latency-timeout|2]]
3. 呼叫端做同步呼叫，但下游不可用或高延遲時。[[#^ref-app-sync-unavailable|3]]

## 顧慮 / 議題（Issues and considerations）

1. 實作方式：偏向「微服務無關 (agnostic) + API 驅動」的斷路器物件，避免把重複邏輯散落在各服務。[[#^ref-issue-agnostic-api|4]]
2. 狀態復原：若有復原時間目標（RTO）需求，可讓下游恢復後主動把狀態更新為 `CLOSED`。[[#^ref-issue-callee-updates-closed|5]]
3. 逾時與多執行緒：當服務被多執行緒呼叫，需避免後續呼叫把逾時無限延長。[[#^ref-issue-expiration-defined|6]] [[#^ref-issue-expiration-not-endless|7]]
4. 可管理性：系統管理員應能強制開啟或關閉電路（例如透過更新資料庫值）。[[#^ref-issue-admin-open-close|8]]
5. 可觀測性：要有日誌/紀錄，能在電路開啟時辨識失敗呼叫。[[#^ref-issue-logging-open|9]]

## 參考資料

1. "The caller service makes a call that is most likely going to fail." (aws-cloud-design-patterns.pdf, p. 20) ^ref-app-fail
2. "A high latency exhibited by the callee service... causes timeouts to the caller service." (aws-cloud-design-patterns.pdf, p. 20) ^ref-app-high-latency-timeout
3. "The caller service makes a synchronous call, but the callee service isn't available or exhibits high latency." (aws-cloud-design-patterns.pdf, p. 20) ^ref-app-sync-unavailable
4. "implement the circuit breaker object in a microservice-agnostic and API-driven way." (aws-cloud-design-patterns.pdf, p. 20) ^ref-issue-agnostic-api
5. "When the callee recovers... they can update the circuit status to CLOSED." (aws-cloud-design-patterns.pdf, p. 20) ^ref-issue-callee-updates-closed
6. "The expiration timeout value is defined as the period of time the circuit remains tripped..." (aws-cloud-design-patterns.pdf, p. 20) ^ref-issue-expiration-defined
7. "Your implementation should ensure that subsequent calls do not move the expiration timeout endlessly." (aws-cloud-design-patterns.pdf, p. 20) ^ref-issue-expiration-not-endless
8. "System administrators should have the ability to open or close a circuit." (aws-cloud-design-patterns.pdf, p. 20) ^ref-issue-admin-open-close
9. "The application should have logging set up to identify the calls that fail when the circuit breaker is open." (aws-cloud-design-patterns.pdf, p. 20) ^ref-issue-logging-open
