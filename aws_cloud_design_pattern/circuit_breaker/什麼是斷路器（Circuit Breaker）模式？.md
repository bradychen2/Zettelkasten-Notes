---
title: 什麼是斷路器（Circuit Breaker）模式？
tags:
  - reading-note
  - architecture
  - patterns
  - resiliency
  - circuit-breaker
---

# 什麼是斷路器（Circuit Breaker）模式？

## 定義

- 斷路器是一個位於呼叫端（caller）與被呼叫端（callee）之間的保護元件：當下游持續失敗/超時時，會「跳閘」並快速失敗，避免持續重試造成資源耗盡。[[#^ref-intent-prevent-retry|1]] [[#^ref-motivation-situated-trips|6]]
- 斷路器也用來偵測下游恢復正常功能後，讓呼叫可以逐步恢復。[[#^ref-intent-detect-functional|2]]

## Intent

1. 防止呼叫端在「已知會反覆超時/失敗」的情境下仍不斷重試下游呼叫。[[#^ref-intent-prevent-retry|1]]
2. 偵測被呼叫端恢復正常功能的時間點，以便恢復呼叫。[[#^ref-intent-detect-functional|2]]

## Motivation

1. 微服務協作處理請求時，單一服務不可用或高延遲可能導致整體失敗。[[#^ref-motivation-unavailable-latency|3]]
2. 同步呼叫的超時/失敗容易形成雪崩 (cascading) 效應，造成糟糕的使用者體驗。[[#^ref-motivation-cascading|4]]
3. 盲目重試會造成網路競爭與資料庫資源耗盡，進一步惡化整體效能。[[#^ref-motivation-contention-threadpool|5]]
4. 因此需要一個能在呼叫端與下游之間自動「跳閘」的機制，阻斷失敗請求流。[[#^ref-motivation-situated-trips|6]]
5. 缺少斷路器的重複呼叫還會影響成本與效能。[[#^ref-motivation-cost-performance|7]]

## 參考資料

1. "The circuit breaker pattern can prevent a caller service from retrying a call to another service (callee)..." (aws-cloud-design-patterns.pdf, p. 19) ^ref-intent-prevent-retry
2. "The pattern is also used to detect when the callee service is functional again." (aws-cloud-design-patterns.pdf, p. 19) ^ref-intent-detect-functional
3. "one or more services might become unavailable or exhibit high latency." (aws-cloud-design-patterns.pdf, p. 19) ^ref-motivation-unavailable-latency
4. "During synchronous execution, the cascading of timeouts or failures can cause a poor user experience." (aws-cloud-design-patterns.pdf, p. 19) ^ref-motivation-cascading
5. "these retries might result in network contention and database thread pool consumption." (aws-cloud-design-patterns.pdf, p. 19) ^ref-motivation-contention-threadpool
6. "situated between the caller and the callee service, and trips if the callee is unavailable." (aws-cloud-design-patterns.pdf, p. 19) ^ref-motivation-situated-trips
7. "repeated calls with no circuit breaker can affect cost and performance." (aws-cloud-design-patterns.pdf, p. 19) ^ref-motivation-cost-performance

## 延伸

- [[斷路器（Circuit Breaker）- 何時使用與顧慮]]
