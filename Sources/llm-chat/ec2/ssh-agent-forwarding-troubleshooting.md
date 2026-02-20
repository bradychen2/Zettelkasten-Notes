---
title: SSH Agent Forwarding 是什麼？如何用它連 Bastion 再跳到 Private EC2，並排查常見錯誤？
tags:
  - reading-note
  - aws
  - ssh
  - bastion
  - troubleshooting
  - ec2
status: draft
source: Gemini share dea848184b75 (Published 2026-02-17 11:16 AM)
created: 2026-02-17
updated: 2026-02-17
---
# SSH Agent Forwarding 是什麼？如何用它連 Bastion 再跳到 Private EC2，並排查常見錯誤？

## Abstract

- SSH Agent Forwarding 讓你不用把 private key 放到 Bastion，就能完成第二跳登入。[[#^ref-agent-forwarding|1]]
- 基本流程：本機 `ssh-add` 加 key，`ssh -A` 連 Bastion，第二跳由本機 agent 代為簽章驗證。[[#^ref-first-jump-a|3]]
- 常見問題包括：agent 沒載入 identities、key 檔權限太寬、以及 Bastion 連線 timeout（SG/路由/NACL）。[[#^ref-no-identities|6]]

## Purposes

1. **避免 key 落地到 Bastion**：降低 Bastion 被入侵時 key 外洩的風險。[[#^ref-agent-forwarding|1]]
2. **支援多把 key 的分層管理**：Bastion 與 private instance 可用不同 key；本機 agent 像 key ring 一樣管理多把 key。[[#^ref-different-keys-ok|5]]
3. **建立可重複的排錯流程**：把常見錯誤（permissions、route、NACL）變成 checklist。[[#^ref-perms-too-open|8]]

## Definition

- SSH Agent Forwarding：把本機 SSH agent 的憑證能力「轉送」到 Bastion，Bastion 只當中繼，不需要持有 key 檔。[[#^ref-agent-forwarding|1]]

## How It Works

1. **本機把 key 交給 agent**
   - 使用 `ssh-add` 把 private key 加進本機 agent。[[#^ref-local-ssh-add|2]]
2. **第一跳到 Bastion（啟用轉送）**
   - 連 Bastion 時加上 `-A` 啟用 forwarding。[[#^ref-first-jump-a|3]]
3. **第二跳到 private instance**
   - private instance 發出 challenge，本機 agent 以對應 key 簽章回應；過程中不需要把 key 檔傳到 Bastion。[[#^ref-no-key-sent|4]]

## Troubleshooting (Checklist)

1. **確認 agent 有 identities**
   - 檢查：`ssh-add -l`。[[#^ref-ssh-add-l|7]]
   - 若顯示 agent 沒有 identities，代表 key 沒載入。[[#^ref-no-identities|6]]
2. **修正 key 檔權限（permissions too open）**
   - 錯誤訊息：permissions 太寬會導致 key 被忽略。[[#^ref-perms-too-open|8]]
   - 修正：用 `chmod 400` 收緊權限後再 `ssh-add`。[[#^ref-chmod-400|11]]
3. **Bastion 連線 timeout**
   - 常見原因：Security Group inbound 沒允許 SSH 22。[[#^ref-require-ssh-22|12]]
   - 常見原因：`0.0.0.0/0` route 沒指向 IGW，subnet 不會是 public。[[#^ref-need-igw-route|14]]
   - 常見原因：NACL 是 stateless，需明確放行 inbound 22 與 outbound ephemeral ports。[[#^ref-nacl-stateless|15]]

## Pitfalls

- agent forwarding 仍有風險：若 Bastion 被拿到 root 權限，有機會劫持活躍的 agent 連線；這也是不少人傾向改用 SSM 的原因之一。[[#^ref-agent-forwarding-risk|16]]

## Related Notes

- [[Sources/llm-chat/ec2/private-ec2-access-methods|Private EC2 的登入方式]]
- [[Sources/llm-chat/sg/security-groups-least-privilege|Security Group 最小權限]]

## References

1. "Instead, the \"precise detail\" you're looking for is a technique called SSH Agent Forwarding." (Gemini 分享頁面 dea848184b75，body.txt 行 233) ^ref-agent-forwarding
2. "Local Setup: You add your private key to your local SSH agent (e.g., using ssh-add my-key.pem) 💻." (Gemini 分享頁面 dea848184b75，body.txt 行 239) ^ref-local-ssh-add
3. "The First Jump: You connect to the Bastion host with a special flag that enables forwarding (e.g., ssh -A ec2-user@bastion-public-ip) 🏹." (Gemini 分享頁面 dea848184b75，body.txt 行 241) ^ref-first-jump-a
4. "without ever sending the actual key file over the network." (Gemini 分享頁面 dea848184b75，body.txt 行 243) ^ref-no-key-sent
5. "the private instance does not have to use the same key-pair as the Bastion host!" (Gemini 分享頁面 dea848184b75，body.txt 行 259) ^ref-different-keys-ok
6. "'The agent has no identities'" (Gemini 分享頁面 dea848184b75，body.txt 行 426) ^ref-no-identities
7. "ssh-add -l" (Gemini 分享頁面 dea848184b75，body.txt 行 408) ^ref-ssh-add-l
8. "Permissions 0644 for '/path/to/<my-key>.pem' are too open." (Gemini 分享頁面 dea848184b75，body.txt 行 493) ^ref-perms-too-open
9. "It is required that your private key files are NOT accessible by others." (Gemini 分享頁面 dea848184b75，body.txt 行 495) ^ref-perms-required
10. "This private key will be ignored." (Gemini 分享頁面 dea848184b75，body.txt 行 497) ^ref-perms-ignored
11. "chmod 400 /path/to/your-key.pem" (Gemini 分享頁面 dea848184b75，body.txt 行 512) ^ref-chmod-400
12. "The Requirement: You must have a rule that allows SSH (Port 22) traffic." (Gemini 分享頁面 dea848184b75，body.txt 行 546) ^ref-require-ssh-22
13. "the \"Source\" should be your local computer's public IP address" (Gemini 分享頁面 dea848184b75，body.txt 行 548) ^ref-ssh-source-ip
14. "There must be a route for 0.0.0.0/0 (all traffic)" (Gemini 分享頁面 dea848184b75，body.txt 行 556) ^ref-need-igw-route
15. "they are stateless" (Gemini 分享頁面 dea848184b75，body.txt 行 560) ^ref-nacl-stateless
16. "if someone has \"root\" (administrator) access on the Bastion host" (Gemini 分享頁面 dea848184b75，body.txt 行 247) ^ref-agent-forwarding-risk
