const ARTIFACT_ID = "carousel-theme-comparison.v1";
const STORAGE_KEY = "opendesign." + ARTIFACT_ID;

const themes = {
  baseline: {
    index: "01 / CURRENT",
    name: "目前炭黑紫",
    summary: "霧面炭黑把資訊壓得很穩，紫色動作不常見、辨識度高；本週進度改用深靛紫，仍屬同一家族但一眼看得出是狀態總覽。",
    colors: ["#111318", "#6f63e8", "#52d5a1", "#171526"],
    differences: [
      ["表面", "霧面深色、低彩度邊線"],
      ["動作", "紫色實心矩形按鈕"],
      ["狀態卡", "深靛紫底與較沉的紫色按鈕"]
    ]
  },
  princess: {
    index: "02 / SWEET",
    name: "甜美公主風",
    summary: "奶油白與霧粉把卡片做得更親近，莓果紅保留足夠對比；圓潤比例與較寬留白帶出甜美感，但不靠裝飾圖案。",
    colors: ["#fff9f5", "#f8e4e8", "#a82e62", "#eee8f0"],
    differences: [
      ["表面", "奶油白、霧粉分層與大圓角"],
      ["動作", "莓果紅膠囊按鈕"],
      ["狀態卡", "灰紫霧面，降低待辦感"]
    ]
  },
  minimal: {
    index: "03 / QUIET",
    name: "極簡質感米白",
    summary: "暖米白像未塗佈紙張，墨黑文字配細棕線，靠留白建立層次。按鈕更克制，適合偏好安靜、長看不累的方向。",
    colors: ["#f7f2e8", "#b8ad9b", "#2f2d28", "#ded7ca"],
    differences: [
      ["表面", "紙張米白、髮絲線與方正圓角"],
      ["動作", "墨黑實心、短半徑按鈕"],
      ["狀態卡", "暖灰石色，按鈕改成細框"]
    ]
  },
  candy: {
    index: "04 / CANDY",
    name: "多巴胺糖果風",
    summary: "桃紅、藍、橘、青各自負責一類任務，深靛線條維持秩序。彩度最高，也最有活動感；卡片之間不只換背景，而是各有明確角色。",
    colors: ["#ffe56b", "#df2472", "#275bd8", "#007d75"],
    differences: [
      ["表面", "牛奶白、厚邊線與彩色狀態塊"],
      ["動作", "按任務類型分色的厚實按鈕"],
      ["狀態卡", "固定薰衣草紫，與動作卡分流"]
    ]
  }
};

const cards = [
  {
    kind: "pick",
    context: "W7｜2026 Q3",
    title: "本週選歌",
    descriptionLabel: "本週主題",
    description: "A song for yourself",
    status: "✓ 已完成",
    statusDetail: "Eternal Flame – The Bangles",
    statusTone: "done",
    metaLabel: "選曲期限",
    meta: "8/10（一）23:59",
    actionLabel: "查看選曲",
    payload: "選曲"
  },
  {
    kind: "submit",
    context: "W7｜2026 Q3",
    title: "交歌",
    descriptionLabel: "目前作品",
    description: "Eternal Flame – The Bangles",
    status: "✓ 已完成",
    statusTone: "done",
    metaLabel: "交歌期限",
    meta: "8/16（日）23:59",
    actionLabel: "查看交歌",
    payload: "交歌"
  },
  {
    kind: "reflection",
    context: "W7｜2026 Q3",
    title: "心得",
    descriptionLabel: "填寫說明",
    description: "選曲後即可填寫，不必等交歌。",
    status: "✓ 已完成",
    statusTone: "done",
    metaLabel: "心得期限",
    meta: "8/16（日）23:59",
    actionLabel: "查看心得",
    payload: "心得"
  },
  {
    kind: "progress",
    role: "progress",
    context: "W7｜2026 Q3",
    title: "本週進度",
    descriptionLabel: "本週流程",
    description: "選曲 → 交歌 → 心得",
    statusLabel: "完成狀態",
    steps: [
      { marker: "✓", label: "選曲" },
      { marker: "✓", label: "交歌" },
      { marker: "✓", label: "心得" }
    ],
    metaLabel: "本週結果",
    meta: "本週三步驟已完成",
    actionLabel: "查看詳細進度",
    payload: "任務詳情"
  },
  {
    kind: "next",
    context: "W8｜2026 Q3",
    title: "下週選曲",
    descriptionLabel: "下週主題",
    description: "A song that can comfort you when you’re feeling down",
    status: "✓ 已選曲",
    statusDetail: "How Does A Moment Last Forever – Celine Dion",
    statusTone: "done",
    metaLabel: "選曲期限",
    meta: "8/17（一）23:59",
    actionLabel: "查看下週選曲",
    payload: "預先選曲 W8"
  },
  {
    kind: "activity",
    context: "W9–W10｜2026 Q3",
    title: "驚喜活動投票",
    descriptionLabel: "玩法選擇",
    description: "交換歌曲、合唱，或這次不參加配對。",
    status: "○ 尚未投票",
    statusTone: "pending",
    metaLabel: "投票期限",
    meta: "8/17（一）08:00",
    actionLabel: "立即投票",
    payload: "投票"
  }
];

const defaultState = { theme: "baseline", cardWidth: 286, showRoutes: false };
let state = loadState();

function loadState() {
  try {
    const saved = JSON.parse(localStorage.getItem(STORAGE_KEY) || "null");
    const next = Object.assign({}, defaultState, saved || {});
    if (!themes[next.theme]) next.theme = defaultState.theme;
    next.cardWidth = Math.min(310, Math.max(258, Number(next.cardWidth) || defaultState.cardWidth));
    next.showRoutes = Boolean(next.showRoutes);
    return next;
  } catch (error) {
    localStorage.removeItem(STORAGE_KEY);
    return Object.assign({}, defaultState);
  }
}

function saveState() {
  localStorage.setItem(STORAGE_KEY, JSON.stringify(state));
}

function escapeHtml(value) {
  return String(value == null ? "" : value)
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#039;");
}

function cardHtml(card, index) {
  const status = card.steps
    ? '<div class="steps">' + card.steps.map(function (step) {
      return '<div class="step"><strong>' + escapeHtml(step.marker) + '</strong><span>' + escapeHtml(step.label) + '</span></div>';
    }).join("") + '</div>'
    : '<strong class="status-value" style="--status-color: var(--status-' + escapeHtml(card.statusTone) + ')">' +
      escapeHtml(card.status) + '</strong>' + (card.statusDetail
      ? '<span class="status-detail">' + escapeHtml(card.statusDetail) + '</span>'
      : "");
  return '<article class="card" data-kind="' + escapeHtml(card.kind) + '" data-role="' + escapeHtml(card.role || "action") + '">' +
    '<header class="card__header"><div class="card__eyebrow"><strong class="card__count">卡片 ' + (index + 1) + '/' + cards.length + '</strong>' +
    '<span class="card__context">' + escapeHtml(card.context) + '</span></div><h3 class="card__title">' + escapeHtml(card.title) + '</h3></header>' +
    '<div class="card__body"><div class="field"><span class="label">' + escapeHtml(card.descriptionLabel) + '</span>' +
    '<span class="value">' + escapeHtml(card.description) + '</span></div>' +
    '<div class="status-panel"><span class="label">' + escapeHtml(card.statusLabel || "目前狀態") + '</span>' + status + '</div>' +
    '<div class="field"><span class="label">' + escapeHtml(card.metaLabel) + '</span><span class="value">' + escapeHtml(card.meta) + '</span></div></div>' +
    '<footer class="card__footer"><button class="card__button" type="button" data-action-index="' + index + '">' + escapeHtml(card.actionLabel) + '</button>' +
    '<code class="route"' + (state.showRoutes ? "" : " hidden") + '>message: ' + escapeHtml(card.payload) + '</code></footer></article>';
}

function renderCards() {
  document.getElementById("carousel").innerHTML = cards.map(cardHtml).join("");
  document.querySelectorAll("[data-action-index]").forEach(function (button) {
    button.addEventListener("click", function () {
      const card = cards[Number(button.dataset.actionIndex)];
      document.getElementById("tap-result").innerHTML = "<strong>" + escapeHtml(card.actionLabel) + "</strong><br>message action：" + escapeHtml(card.payload);
    });
  });
}

function renderTheme() {
  const theme = themes[state.theme];
  document.querySelector(".preview-shell").dataset.theme = state.theme;
  document.documentElement.style.setProperty("--card-width", state.cardWidth + "px");
  document.getElementById("theme-index").textContent = theme.index;
  document.getElementById("theme-name").textContent = theme.name;
  document.getElementById("theme-summary").textContent = theme.summary;
  document.getElementById("swatches").innerHTML = theme.colors.map(function (color) {
    return '<span class="swatch" style="--swatch:' + escapeHtml(color) + '" title="' + escapeHtml(color) + '"></span>';
  }).join("");
  document.getElementById("difference-list").innerHTML = theme.differences.map(function (item) {
    return "<li><strong>" + escapeHtml(item[0]) + "</strong><span>" + escapeHtml(item[1]) + "</span></li>";
  }).join("");
  document.querySelectorAll("[data-theme-button]").forEach(function (button) {
    button.setAttribute("aria-pressed", String(button.dataset.themeButton === state.theme));
  });
  document.getElementById("theme-select").value = state.theme;
  document.getElementById("width-range").value = state.cardWidth;
  document.getElementById("width-output").textContent = state.cardWidth + " px";
  document.getElementById("route-toggle").checked = state.showRoutes;
  renderCards();
  saveState();
}

function selectTheme(theme) {
  if (!themes[theme]) return;
  state.theme = theme;
  renderTheme();
}

document.querySelectorAll("[data-theme-button]").forEach(function (button) {
  button.addEventListener("click", function () { selectTheme(button.dataset.themeButton); });
});

document.getElementById("theme-select").addEventListener("change", function (event) {
  selectTheme(event.target.value);
});

document.getElementById("width-range").addEventListener("input", function (event) {
  state.cardWidth = Number(event.target.value);
  renderTheme();
});

document.getElementById("route-toggle").addEventListener("change", function (event) {
  state.showRoutes = event.target.checked;
  renderTheme();
});

document.getElementById("carousel").addEventListener("scroll", function (event) {
  const carousel = event.currentTarget;
  const firstCard = carousel.querySelector(".card");
  if (!firstCard) return;
  const gap = 9;
  const current = Math.min(cards.length, Math.max(1, Math.round(carousel.scrollLeft / (firstCard.offsetWidth + gap)) + 1));
  document.getElementById("page-indicator").textContent = "卡片 " + current + "/" + cards.length;
}, { passive: true });

const tweaks = document.getElementById("tweaks");

function setTweaksActive(active) {
  tweaks.hidden = !active;
}

function hostMessageType(message) {
  if (typeof message === "string") return message;
  if (!message || typeof message !== "object") return "";
  return message.action || message.type || "";
}

/* Listener first; availability is posted only after this registration. */
window.addEventListener("message", function (event) {
  const type = hostMessageType(event.data);
  if (type === "activate" || type === "tweaks:activate" || type === "opendesign:tweaks:activate") setTweaksActive(true);
  if (type === "deactivate" || type === "tweaks:deactivate" || type === "opendesign:tweaks:deactivate") setTweaksActive(false);
});

window.parent.postMessage({ type: "opendesign:tweaks:available", action: "available", artifactId: ARTIFACT_ID }, "*");

document.getElementById("close-tweaks").addEventListener("click", function () {
  setTweaksActive(false);
  window.parent.postMessage({ type: "opendesign:tweaks:deactivate", action: "deactivate", artifactId: ARTIFACT_ID }, "*");
});

const requestedTheme = new URLSearchParams(window.location.search).get("theme");
if (themes[requestedTheme]) state.theme = requestedTheme;
setTweaksActive(window.self === window.top);
renderTheme();
