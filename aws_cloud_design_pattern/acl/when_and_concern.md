---
title: When should I use the ACL pattern, and what are the concerns?
tags: [reading-note, architecture, ddd, patterns]
status: draft
source: aws-cloud-design-patterns.pdf
---

# When should I use the ACL pattern, and what are the concerns?

## TL;DR

- Use ACL to translate between mismatched models/semantics during migration or external integration. [[#^ref-when-migrate-model-mismatch|1]]
  > 在遷移或外部整合時，用 ACL 隔離並轉換不相容的模型/語義。
- Main risks: ops overhead, SPOF, latency, scaling bottleneck, and “temporary layer” tech debt. [[#^ref-concern-ops-overhead|5]]
  > 主要風險：維運成本、單點故障、延遲、擴展瓶頸，以及「暫時層」演變成技術債。
- Mitigate with resilience patterns, observability, perf testing, scalable design, and planned decommissioning. [[#^ref-mitigate-retry-cb|10]]
  > 緩解方式：韌性設計、可觀測性、效能測試、可擴展設計，以及規劃退場（拆除）。

## When to Use

- Monolith → microservices migration where the new service’s domain model/semantics differ and you need translation to keep communication stable. [[#^ref-when-migrate-model-mismatch|1]]
  > 單體遷移到微服務後，新舊領域模型/語義不一致，需要透過 ACL 做翻譯以維持穩定通訊。
- Two systems must exchange data but their semantics/models differ and changing either system isn’t practical. [[#^ref-when-semantics-incompatible|2]]
  > 兩個系統必須交換資料，但語義/模型不相容，且修改任一方成本過高或不可行。
- Integrating with external/3rd-party systems you don’t control. [[#^ref-when-external-system|3]]
  > 與不受你控制的外部/第三方系統整合時，用 ACL 隔離外部變動與語義差異。
- Minimize migration impact: keep callers stable while routing/translating behind the scenes to reduce disruption/risk. [[#^ref-when-minimize-caller-change|4]]
  > 想把遷移影響降到最低：讓呼叫端維持原介面，由 ACL 在背後做路由/轉換以降低中斷與風險。

## When NOT to Use

- For small applications, where refactoring complexity is low, it might be more efficient to rewrite the application in microservices architecture instead of migrating it. [[#^ref-when-not-small-apps|15]]
  > 對小型系統（重構複雜度低）而言，直接以微服務架構重寫，可能比透過 ACL 做遷移更有效率。
- Consider whether the ACL will be a transient/interim solution or a long-term solution. [[#^ref-when-not-long-term-solution|16]]
  > 評估 ACL 是過渡方案還是長期方案；若會變成長期負擔，就要重新審視是否值得。

## Concerns / trade-offs

- Operational overhead: extra component to run/monitor/alert/release. [[#^ref-concern-ops-overhead|5]]
  > 維運開銷：多了一層需要部署、監控、告警、發布與維護。
- Single point of failure: ACL failure can make the target service unreachable. [[#^ref-concern-spof|6]]
  > 單點故障：ACL 掛掉可能直接讓目標服務不可達。
- Added latency: extra hop + translation work. [[#^ref-concern-latency|7]]
  > 延遲增加：多一次網路跳轉與轉換處理。
- Implementation choice complexity: decide whether ACL is a shared object or service-specific classes (affects design/maintenance). [[#^ref-concern-impl-choice|17]]
  > 實作選擇的複雜度：需要決定 ACL 要做成共用元件或服務專用類別，會影響設計與維護。
- Scaling bottleneck: ACL can become the throughput limit if it doesn’t scale with load. [[#^ref-concern-scaling|8]]
  > 擴展瓶頸：若 ACL 無法跟著流量/目標服務一起擴展，容易成為效能瓶頸。
- Technical debt & decommissioning: treat as transitional if applicable, track it, and remove after callers migrate. [[#^ref-concern-techdebt-decommission|9]]
  > 技術債/退場：若 ACL 只是過渡方案，必須被追蹤並在呼叫端完成遷移後拆除。

## Mitigations / best practices

- Build resilience into ACL: retries + circuit breaker patterns. [[#^ref-mitigate-retry-cb|10]]
  > 在 ACL 內建韌性：重試機制與斷路器（Circuit Breaker）。
- Add logging + alerting to reduce MTTR. [[#^ref-mitigate-logging-alerting|11]]
  > 強化可觀測性：日誌與告警，縮短 MTTR。
- Define and test performance tolerance before production (for latency-sensitive workloads). [[#^ref-mitigate-perf-tolerance|12]]
  > 上線前先定義並測試效能/延遲容忍度（尤其是對延遲敏感的系統）。
- Ensure ACL scales with the target service to avoid bottlenecks. [[#^ref-mitigate-scale-with-service|13]]
  > 讓 ACL 具備可擴展性，並能隨目標服務/流量同步擴展。
- Integrate ACL into existing CI/CD + monitoring/ops workflows. [[#^ref-mitigate-integrate-cicd-obs|14]]
  > 把 ACL 納入既有 CI/CD、監控與維運流程，避免成為孤島元件。

## References

1. "acting as an adapter or a facade layer that translates the calls into the newer semantics." (aws-cloud-design-patterns.pdf, p. 3) ^ref-when-migrate-model-mismatch
2. "Two systems have different semantics and need to exchange data, but it isn't practical to modify one system to be compatible with the other system." (aws-cloud-design-patterns.pdf, p. 3) ^ref-when-semantics-incompatible
3. "Your application is communicating with an external system." (aws-cloud-design-patterns.pdf, p. 3) ^ref-when-external-system
4. "It also reduces transformation risk and business disruption by preventing changes to callers when their calls have to be redirected transparently to the target system." (aws-cloud-design-patterns.pdf, p. 3) ^ref-when-minimize-caller-change
5. "Operational overhead: The ACL pattern requires additional effort to operate and maintain." (aws-cloud-design-patterns.pdf, p. 4) ^ref-concern-ops-overhead
6. "Single point of failure: Any failures in the ACL can make the target service unreachable, causing application issues." (aws-cloud-design-patterns.pdf, p. 4) ^ref-concern-spof
7. "Latency: The additional layer can introduce latency due to the conversion of requests from one interface to another." (aws-cloud-design-patterns.pdf, p. 4) ^ref-concern-latency
8. "Scaling bottleneck: In high-load applications where services can scale to peak load, ACL can become a bottleneck and might cause scaling issues." (aws-cloud-design-patterns.pdf, p. 4) ^ref-concern-scaling
9. "If it's an interim solution, you should record the ACL as a technical debt and decommission it after all dependent callers have been migrated." (aws-cloud-design-patterns.pdf, p. 4) ^ref-concern-techdebt-decommission
10. "To mitigate this issue, you should build in retry capabilities and circuit breakers." (aws-cloud-design-patterns.pdf, p. 4) ^ref-mitigate-retry-cb
11. "Setting up appropriate alerts and logging will improve the mean time to resolution (MTTR)." (aws-cloud-design-patterns.pdf, p. 4) ^ref-mitigate-logging-alerting
12. "We recommend that you define and test performance tolerance in applications that are sensitive to response time before you deploy ACL into production environments." (aws-cloud-design-patterns.pdf, p. 4) ^ref-mitigate-perf-tolerance
13. "If the target service scales on demand, you should design ACL to scale accordingly." (aws-cloud-design-patterns.pdf, p. 4) ^ref-mitigate-scale-with-service
14. "This work includes integrating ACL with monitoring and alerting tools, the release process, and continuous integration and continuous delivery (CI/CD) processes." (aws-cloud-design-patterns.pdf, p. 4) ^ref-mitigate-integrate-cicd-obs
15. "For small applications, where the complexity of complete refactoring is low, it might be more efficient to rewrite the application in microservices architecture instead of migrating it." (aws-cloud-design-patterns.pdf, p. 80) ^ref-when-not-small-apps
16. "consider whether the ACL will be a transient or interim solution, or a long-term solution." (aws-cloud-design-patterns.pdf, p. 4) ^ref-when-not-long-term-solution
17. "You can design ACL as a shared object to convert and redirect calls to multiple services or service-specific classes." (aws-cloud-design-patterns.pdf, p. 4) ^ref-concern-impl-choice
