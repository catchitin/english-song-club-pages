# english-song-club-pages

English Song Cover Club 公開歌單／欣賞頁的**靜態鏡像**。

- 來源：GAS Web App（HtmlService）公開頁；`.github/workflows/mirror.yml` 每小時抓取發佈
- 為什麼：GAS 的 Google iframe 外殼在手機（LINE WebView／行動 Safari）常打不開；靜態頁手機秒開
- 網址：https://catchitin.github.io/english-song-club-pages/ （`appreciate.html`＝上週作品欣賞）
- 資料新鮮度：最多慢 1 小時；正本永遠是 GAS `/exec`
- 隱私：內容與公開 `/exec` 完全相同（只有英文 display 名）
- 個人提醒設計預覽：https://catchitin.github.io/english-song-club-pages/lab/reminders/ （不進主導覽、`noindex`）

`static/` 放刻意版本化的獨立頁面，部署時原樣併入 `out/`。`lab/reminders/` 是固定資料的設計預覽，不是第二份即時資料來源；正式提醒文案變更時，需同步受影響的預覽情境。
