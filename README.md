# english-song-club-pages

English Song Cover Club 公開歌單／欣賞頁的**靜態鏡像**。

- 來源：GAS Web App（HtmlService）公開頁；`.github/workflows/mirror.yml` 每小時抓取發佈
- 為什麼：GAS 的 Google iframe 外殼在手機（LINE WebView／行動 Safari）常打不開；靜態頁手機秒開
- 網址：https://catchitin.github.io/english-song-club-pages/ （`appreciate.html`＝上週作品欣賞）
- 資料新鮮度：最多慢 1 小時；正本永遠是 GAS `/exec`
- 隱私：內容與公開 `/exec` 完全相同（只有英文 display 名）

`static/` 放刻意版本化的獨立頁面，部署時原樣併入 `out/`。舊 `lab/reminders/` 自 2026-09-20 停用，只保留歷史檔案，不更新或作為驗收來源。

## 排程保活與故障恢復（2026-10-12）

- `mirror.yml` 的獨立 `keepalive` job 使用內建 `GITHUB_TOKEN`，每月最多提交一次 `.github/health/scheduler-month.txt`，避免公開 repo 60 天閒置停用。即使抓取 GAS 失敗仍會保活。提交不會遞迴觸發工作流。
- 每次發布包含 `sync-status.json`，記錄 UTC 發布時間、來源 commit 與 run ID；只在 Pages 發布成功後成為公開證據。
- 抓頁最多三個同時請求，保留三次重試、120 秒 timeout 與完整批次成功才發布。mirror job 上限 40 分鐘，避免卡住阻塞後续同步。
- Windows 工作排程器 `EnglishSongClub-PagesWatchdog` 每小時執行 `scripts/watch-mirror.ps1`：官方 GitHub CLI 讀回排程狀態，停用則啟用並補跑；網站超過 3 小時未更新且無進行中工作則補跑，超過 4 小時或連線／首頁異常則通知。同類異常通知間隔至少 6 小時。
- 正常時靜默，執行視窗隱藏。狀態、恢復與錯誤紀錄在 repo 外 `G:/My Coding/english-song-club-local/pages-watchdog/`。使用已登入 Windows 使用者的 GitHub CLI 正式 OAuth；不存新 token。
- 異常通知留在 Windows 通知中心七天，通知 API 不可用時改用短暫對話框。`install-watchdog.ps1` 可重跑安裝；會以官方 Windows Shell API 註冊通知身分，在使用者開始選單存一個必要捷徑（Windows 規定的個人設定位置，其餘資料仍在 G 槽）。安裝時靜默寫入、讀回並移除測試通知，不跳出視窗。
- 驗證：`python -m unittest discover -s tests`、`powershell.exe -NoProfile -File tests/watchdog.test.ps1`。恢復情境測試使用隔離 mock，不停用正式排程。
- 手動驗證：`powershell.exe -NoProfile -File scripts/watch-mirror.ps1 -NoNotify`，成功 exit 0；異常 exit 1。
- 外部 watchdog 需要此電腦開機、使用者登入、G 槽可用及 gh 授權有效；電腦離線時 GitHub 保活與同步仍持續，但本機恢復／通知暫停。GitHub／GAS 停機或憑證失效仍可能造成延遲，不能保證零中斷。
