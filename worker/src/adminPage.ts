export const adminPageHtml = `<!doctype html>
<html lang="ja">
<head>
<meta charset="utf-8">
<title>カレンダー編集</title>
<style>
  body {
    font-family: sans-serif;
    max-width: 420px;
    margin: 2rem auto;
    padding: 0 1rem;
  }
  h1 { font-size: 1.2rem; }
  .nav {
    display: flex;
    align-items: center;
    justify-content: space-between;
    margin: 1rem 0;
  }
  .nav button {
    cursor: pointer;
    padding: 0.4rem 0.8rem;
  }
  #month-label { font-weight: bold; font-size: 1.1rem; }
  .calendar {
    display: grid;
    grid-template-columns: repeat(7, 1fr);
    gap: 4px;
  }
  .weekday {
    text-align: center;
    font-weight: bold;
    padding: 0.3rem 0;
    font-size: 0.85rem;
  }
  .weekday.sun { color: #e53e3e; }
  .weekday.sat { color: #2b6cb0; }
  .day {
    aspect-ratio: 1;
    display: flex;
    align-items: center;
    justify-content: center;
    border: 1px solid #ddd;
    border-radius: 6px;
    cursor: pointer;
    user-select: none;
    font-size: 0.95rem;
  }
  .day:hover { background: #f0f0f0; }
  .day.empty { border: none; cursor: default; visibility: hidden; }
  .day.sun { color: #e53e3e; }
  .day.sat { color: #2b6cb0; }
  .day.closed {
    background: #ffdde0;
    border-color: #e0526b;
    font-weight: bold;
  }
  .day.closed:hover { background: #ffc9cf; }
  .legend {
    margin-top: 0.8rem;
    font-size: 0.85rem;
    color: #555;
  }
  .legend span.sample {
    display: inline-block;
    width: 0.9rem;
    height: 0.9rem;
    background: #ffdde0;
    border: 1px solid #e0526b;
    border-radius: 3px;
    vertical-align: middle;
    margin-right: 0.3rem;
  }
  #save-row {
    margin-top: 1.2rem;
    display: flex;
    align-items: center;
    gap: 0.6rem;
  }
  #save { cursor: pointer; padding: 0.5rem 1rem; }
</style>
</head>
<body>
<h1>休みのカレンダー編集</h1>

<div class="nav">
  <button id="prev">← 前の月</button>
  <span id="month-label"></span>
  <button id="next">次の月 →</button>
</div>

<div id="calendar" class="calendar"></div>

<p class="legend"><span class="sample"></span>クリックで休み登録・解除できます</p>

<div id="save-row">
  <button id="save">保存</button>
  <span id="status"></span>
</div>

<script>
let state = { closedDates: [], openDates: [] };
let viewYear;
let viewMonth;

function pad(n) {
  return String(n).padStart(2, "0");
}

function toDateKey(y, m, d) {
  return y + "-" + pad(m + 1) + "-" + pad(d);
}

function findClosedIndex(dateKey) {
  return state.closedDates.findIndex((entry) => entry.date === dateKey);
}

function toggleDate(dateKey) {
  const index = findClosedIndex(dateKey);
  if (index >= 0) {
    state.closedDates.splice(index, 1);
  } else {
    state.closedDates.push({ date: dateKey, label: "休み" });
  }
  renderCalendar();
}

function renderCalendar() {
  const calendar = document.getElementById("calendar");
  calendar.innerHTML = "";

  const weekdayNames = ["日", "月", "火", "水", "木", "金", "土"];
  weekdayNames.forEach((name, i) => {
    const cell = document.createElement("div");
    cell.className = "weekday" + (i === 0 ? " sun" : "") + (i === 6 ? " sat" : "");
    cell.textContent = name;
    calendar.appendChild(cell);
  });

  const firstDay = new Date(viewYear, viewMonth, 1);
  const startWeekday = firstDay.getDay();
  const daysInMonth = new Date(viewYear, viewMonth + 1, 0).getDate();

  for (let i = 0; i < startWeekday; i++) {
    const cell = document.createElement("div");
    cell.className = "day empty";
    calendar.appendChild(cell);
  }

  for (let d = 1; d <= daysInMonth; d++) {
    const dateKey = toDateKey(viewYear, viewMonth, d);
    const weekday = new Date(viewYear, viewMonth, d).getDay();
    const entryIndex = findClosedIndex(dateKey);

    const cell = document.createElement("div");
    cell.className =
      "day" +
      (weekday === 0 ? " sun" : "") +
      (weekday === 6 ? " sat" : "") +
      (entryIndex >= 0 ? " closed" : "");
    cell.textContent = String(d);

    if (entryIndex >= 0 && state.closedDates[entryIndex].label !== "休み") {
      cell.title = state.closedDates[entryIndex].label;
    }

    cell.addEventListener("click", () => toggleDate(dateKey));
    calendar.appendChild(cell);
  }

  document.getElementById("month-label").textContent = viewYear + "年" + (viewMonth + 1) + "月";
}

document.getElementById("prev").addEventListener("click", () => {
  viewMonth -= 1;
  if (viewMonth < 0) {
    viewMonth = 11;
    viewYear -= 1;
  }
  renderCalendar();
});

document.getElementById("next").addEventListener("click", () => {
  viewMonth += 1;
  if (viewMonth > 11) {
    viewMonth = 0;
    viewYear += 1;
  }
  renderCalendar();
});

document.getElementById("save").addEventListener("click", async () => {
  const statusEl = document.getElementById("status");
  statusEl.textContent = "保存中...";
  const res = await fetch("/admin/api/calendar", {
    method: "PUT",
    headers: { "content-type": "application/json" },
    body: JSON.stringify(state),
  });
  if (res.ok) {
    statusEl.textContent = "保存しました";
  } else {
    const text = await res.text();
    statusEl.textContent = "エラー: " + text;
  }
});

async function load() {
  const res = await fetch("/admin/api/calendar");
  state = await res.json();
  const today = new Date();
  viewYear = today.getFullYear();
  viewMonth = today.getMonth();
  renderCalendar();
}

load();
</script>
</body>
</html>
`;
