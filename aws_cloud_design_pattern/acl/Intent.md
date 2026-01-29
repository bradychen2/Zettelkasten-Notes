---
title: What's an anti-corruption layer pattern
---

# What's an anti-corruption layer pattern

## Purposes

1. **Reduce transformation risk / business disruption**:  
   The ACL absorbs model and API changes, so callers don’t need immediate changes when migrations happen. [[#^ref-risk|1]]
   > **降低轉型風險 / 減少業務中斷**：  
   ACL 吸收模型與 API 的差異與變動，遷移或改造時呼叫端不必立刻修改程式。
2. **Transparent calls to new services**:  
   Callers keep using the old interface; the ACL redirects or translates calls to the new service behind the scenes. [[#^ref-adapter-facade|2]]  
   > **對新服務的呼叫可透明進行**：  
   呼叫端維持舊介面；ACL 在背後將請求轉向或轉換成新服務可理解的形式。
3. **Decouple teams and systems**:  
   Only the ACL needs updates when the new service model changes, so other teams don’t have to coordinate every change. [[#^ref-decouple-callees|3]]  
   > **解耦團隊與系統依賴**：  
   新服務模型變更時，通常只需調整 ACL；其他服務/團隊不必同步協調修改。
4. **Support incremental migration (Strangler Fig)**:  
   You can migrate one capability at a time; the ACL routes calls to old or new systems until the old one is retired. [[#^ref-strangler|4]]  
   > **支援漸進式遷移（Strangler Fig）**：  
   可以一次遷移一個能力；ACL 依情況把流量導向舊系統或新系統，直到舊系統退場。

## References

1. "ACL reduces migration risk by avoiding caller changes when calls are transparently redirected." (aws-cloud-design-patterns.pdf, p. 3) ^ref-risk
2. "ACL acts as an adapter/facade to allow transparent calls from monolith to microservices."(aws-cloud-design-patterns.pdf, p. 3) ^ref-adapter-facade
3. "ACL decouples callees by translating calls to match new service semantics." (aws-cloud-design-patterns.pdf, p. 4) ^ref-decouple-callees
4. "ACL can support incremental migration by routing/redirecting calls between old and new implementations during a transition." (aws-cloud-design-patterns.pdf, p. 3-4) ^ref-strangler
5. "ACL is a mediation layer that translates domain model semantics between systems." (aws-cloud-design-patterns.pdf, p. 3) ^ref-mediation
6. "ACL translates an upstream (monolith) model into a downstream (microservice) model." (aws-cloud-design-patterns.pdf, p. 3) ^ref-upstream-downstream
