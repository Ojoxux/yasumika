export const adminPageHtml = `<!doctype html>
<html lang="ja">
<head>
<meta charset="utf-8">
<title>カレンダー編集</title>
<style>
  body { font-family: sans-serif; max-width: 640px; margin: 2rem auto; padding: 0 1rem; }
  table { width: 100%; border-collapse: collapse; margin-bottom: 1rem; }
  th, td { border: 1px solid #ccc; padding: 0.4rem; text-align: left; }
  h2 { margin-top: 2rem; }
  button { cursor: pointer; }
</style>
</head>
<body>
<h1>カレンダー編集</h1>

<h2>休みの日 (closedDates)</h2>
<table id="closed-table"><tbody></tbody></table>
<button id="add-closed">+ 追加</button>

<h2>出勤の日 (openDates)</h2>
<table id="open-table"><tbody></tbody></table>
<button id="add-open">+ 追加</button>

<p><button id="save">保存</button> <span id="status"></span></p>

<script>
let state = { closedDates: [], openDates: [] };

async function load() {
  const res = await fetch("/admin/api/calendar");
  state = await res.json();
  render();
}

function render() {
  renderTable("closed-table", state.closedDates);
  renderTable("open-table", state.openDates);
}

function renderTable(tableId, entries) {
  const tbody = document.getElementById(tableId).querySelector("tbody");
  tbody.innerHTML = "";
  entries.forEach((entry, index) => {
    const tr = document.createElement("tr");

    const dateTd = document.createElement("td");
    const dateInput = document.createElement("input");
    dateInput.type = "date";
    dateInput.value = entry.date;
    dateInput.addEventListener("change", () => { entry.date = dateInput.value; });
    dateTd.appendChild(dateInput);

    const labelTd = document.createElement("td");
    const labelInput = document.createElement("input");
    labelInput.type = "text";
    labelInput.value = entry.label;
    labelInput.addEventListener("change", () => { entry.label = labelInput.value; });
    labelTd.appendChild(labelInput);

    const actionTd = document.createElement("td");
    const removeBtn = document.createElement("button");
    removeBtn.textContent = "削除";
    removeBtn.addEventListener("click", () => {
      entries.splice(index, 1);
      render();
    });
    actionTd.appendChild(removeBtn);

    tr.appendChild(dateTd);
    tr.appendChild(labelTd);
    tr.appendChild(actionTd);
    tbody.appendChild(tr);
  });
}

document.getElementById("add-closed").addEventListener("click", () => {
  state.closedDates.push({ date: new Date().toISOString().slice(0, 10), label: "休み" });
  render();
});

document.getElementById("add-open").addEventListener("click", () => {
  state.openDates.push({ date: new Date().toISOString().slice(0, 10), label: "出勤" });
  render();
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

load();
</script>
</body>
</html>
`;
