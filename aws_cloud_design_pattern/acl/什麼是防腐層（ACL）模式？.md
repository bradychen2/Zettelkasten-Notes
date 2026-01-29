---
title: 什麼是防腐層（ACL）模式？
---
# 什麼是防腐層（ACL）模式？

## 目的

1. **降低轉型風險 / 減少業務中斷**：ACL 吸收模型與 API 的差異與變動，遷移或改造時呼叫端不必立刻修改程式。[[#^ref-risk|1]]
2. **對新服務的呼叫可透明進行**：呼叫端維持舊介面；ACL 在背後將請求轉向或轉換成新服務可理解的形式。[[#^ref-adapter-facade|2]]
3. **解耦團隊與系統依賴**：新服務模型變更時，通常只需調整 ACL；其他服務/團隊不必同步協調修改。[[#^ref-decouple-callees|3]]
4. **支援漸進式遷移（Strangler Fig）**：可以一次遷移一個能力；ACL 依情況把流量導向舊系統或新系統，直到舊系統退場。[[#^ref-strangler|4]]

## 參考資料

1. "ACL reduces migration risk by avoiding caller changes when calls are transparently redirected." (aws-cloud-design-patterns.pdf, p. 3) ^ref-risk
2. "ACL acts as an adapter/facade to allow transparent calls from monolith to microservices."(aws-cloud-design-patterns.pdf, p. 3) ^ref-adapter-facade
3. "ACL decouples callees by translating calls to match new service semantics." (aws-cloud-design-patterns.pdf, p. 4) ^ref-decouple-callees
4. "ACL can support incremental migration by routing/redirecting calls between old and new implementations during a transition." (aws-cloud-design-patterns.pdf, p. 3-4) ^ref-strangler
5. "ACL is a mediation layer that translates domain model semantics between systems." (aws-cloud-design-patterns.pdf, p. 3) ^ref-mediation
6. "ACL translates an upstream (monolith) model into a downstream (microservice) model." (aws-cloud-design-patterns.pdf, p. 3) ^ref-upstream-downstream
