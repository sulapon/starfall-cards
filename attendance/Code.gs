/*** 員工差勤表後端 — Google Apps Script (Code.gs)
 * 安裝步驟見 SETUP.md。試算表需有兩張工作表：
 *   employees: 第一列 name | dept
 *   records:   第一列 id | name | type | from | to | trip | note
 */

function doGet() {
  return ContentService.createTextOutput(JSON.stringify({ ok: true, msg: 'attendance api alive' }))
    .setMimeType(ContentService.MimeType.JSON);
}

function doPost(e) {
  try {
    var body = JSON.parse(e.postData.contents);
    var action = body.action;
    if (action === 'ping') return out({ ok: true, time: new Date() });
    if (action === 'list') return out({ ok: true, rows: listRows(body.table) });
    if (action === 'add') { addRow(body.table, body.row); return out({ ok: true }); }
    if (action === 'del') { delRow(body.table, body.id); return out({ ok: true }); }
    return out({ ok: false, error: 'unknown action' });
  } catch (err) {
    return out({ ok: false, error: String(err) });
  }
}

function out(o) {
  return ContentService.createTextOutput(JSON.stringify(o))
    .setMimeType(ContentService.MimeType.JSON);
}

function sheetOf(table) {
  var ss = SpreadsheetApp.openById('1eumw5hQDIa1ghK9usM_zwReJ8Ad5RGfGK4I5rH00m6w'); // 員工差勤DB（獨立專案無綁定試算表，改用 ID 開啟）
  var name = table === 'employees' ? 'employees' : 'records';
  var sh = ss.getSheetByName(name);
  if (!sh) {
    sh = ss.insertSheet(name);
    sh.appendRow(table === 'employees' ? ['name', 'dept'] : ['id', 'name', 'type', 'from', 'to', 'trip', 'note']);
  }
  return sh;
}

function listRows(table) {
  var sh = sheetOf(table);
  var vals = sh.getDataRange().getValues();
  if (vals.length < 2) return [];
  var head = vals[0];
  var rows = [];
  for (var i = 1; i < vals.length; i++) {
    var o = {};
    for (var j = 0; j < head.length; j++) {
      var v = vals[i][j];
      if (Object.prototype.toString.call(v) === '[object Date]') v = Utilities.formatDate(v, 'Asia/Taipei', 'yyyy-MM-dd');
      o[head[j]] = String(v == null ? '' : v);
    }
    if (table === 'employees' && !o.name) continue;
    if (table === 'records' && !o.id) continue;
    rows.push(o);
  }
  return rows;
}

function addRow(table, row) {
  var sh = sheetOf(table);
  if (table === 'employees') {
    sh.appendRow([row.name || '', row.dept || '']);
  } else {
    sh.appendRow([row.id || '', row.name || '', row.type || '', row.from || '', row.to || '', row.trip || '', row.note || '']);
  }
}

function delRow(table, id) {
  var sh = sheetOf(table);
  var vals = sh.getDataRange().getValues();
  var keyCol = table === 'employees' ? 0 : 0; // employees 用 name 當 key，records 用 id
  for (var i = vals.length - 1; i >= 1; i--) {
    if (String(vals[i][keyCol]) === String(id)) sh.deleteRow(i + 1);
  }
}
