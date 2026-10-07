const test = require("node:test")
const assert = require("node:assert/strict")
const fs = require("node:fs")
const path = require("node:path")
const vm = require("node:vm")
const Model = require("../Model.js")

const qml = fs.readFileSync(path.join(__dirname, "..", "Panel.qml"), "utf8")

function functionSource(name) {
  return qml.match(new RegExp("^  function " + name + "\\([\\s\\S]*?^  }", "m"))[0]
}

function panelFunction(name, root, globals = {}) {
  return vm.runInNewContext("(" + functionSource(name) + ")", { root, Model, ...globals })
}

function scaleRoot(overrides = {}) {
  const calls = []
  const root = Object.assign({
    focusedScaleAvailable: true,
    focusedScaleEnabled: true,
    focusedScaleValue: "2",
    focusedScalePreviewQueued: false,
    selectedOutputKey: "samsung|panel|1",
    editPending: false,
    editOutput(fields, key) {
      calls.push({ fields, key })
      root.editPending = true
    }
  }, overrides)
  root.setFocusedScale = panelFunction("setFocusedScale", root)
  return { root, calls }
}

test("the scale row sits between Text size and Monitor Management and follows the selected display", () => {
  const row = qml.indexOf("id: compactScaleField")
  assert.ok(row > qml.indexOf("TextSizeControl {"))
  assert.ok(row < qml.indexOf('text: "MONITOR MANAGEMENT"'))
  assert.ok(row < qml.indexOf("id: expandedEditor"))
  assert.match(qml, /readonly property var focusedScalePresets: Model\.scalePresets\(root\.editorDocument\.displays, root\.selectedOutputKey,/)
  assert.match(qml, /id: compactScaleField\s+visible: root\.focusedScaleAvailable/)
  assert.match(qml, /onChanged: function\(value\) \{ root\.setFocusedScale\(value\) \}/)
})

test("a new scale edits the selected display through hyprmoncfgd", () => {
  const { root, calls } = scaleRoot()
  root.setFocusedScale("1.6")
  assert.deepEqual(JSON.parse(JSON.stringify(calls)), [{ fields: { scale: 1.6 }, key: "samsung|panel|1" }])
  assert.equal(root.focusedScalePreviewQueued, true)
})

test("the current scale, a busy panel and a rejected edit change nothing", () => {
  const same = scaleRoot()
  same.root.setFocusedScale("2")
  assert.equal(same.calls.length, 0)

  const busy = scaleRoot({ focusedScaleEnabled: false })
  busy.root.setFocusedScale("1.6")
  assert.equal(busy.calls.length, 0)

  const rejected = scaleRoot({ editOutput() {} })
  rejected.root.setFocusedScale("1.6")
  assert.equal(rejected.root.focusedScalePreviewQueued, false, "an edit that never sent leaves nothing queued")
})

test("the edited draft is previewed so Keep or Revert decides it", () => {
  assert.match(qml, /if \(root\.focusedScalePreviewQueued\) \{\s+root\.focusedScalePreviewQueued = false\s+Qt\.callLater\(function\(\) \{\s+if \(root\.sourceProfile !== ""\) root\.previewDraft\(\)\s+else root\.applyDraft\(\)/)
  assert.match(qml, /if \(method === "edit_profile"\) \{\s+root\.editPending = false\s+root\.focusedScalePreviewQueued = false/)
  assert.match(qml, /readonly property bool focusedScaleEnabled: root\.managedChecked && !root\.editPending && !root\.previewPending\s+&& root\.previewTransaction === "" && !root\.draftDirty && !root\.focusedScalePreviewQueued/)
})

test("the keyboard reaches Scale between Text size and Management, and skips it when unavailable", () => {
  const cursor = { cursorIndex: 0, cursorActive: false, textSizeAvailable: true, focusedScaleAvailable: true,
    focusedScaleValue: "2", focusedScaleCursor: "", itemCount: () => 3 }
  const move = panelFunction("moveCursor", cursor)
  move(-1)
  assert.equal(cursor.cursorIndex, -1)
  assert.equal(cursor.focusedScaleCursor, "2", "entering the row starts at the current scale")
  move(-1)
  assert.equal(cursor.cursorIndex, -2)
  move(1)
  assert.equal(cursor.cursorIndex, -1)

  const hidden = { cursorIndex: -2, cursorActive: true, textSizeAvailable: true, focusedScaleAvailable: false,
    focusedScaleValue: "", focusedScaleCursor: "", itemCount: () => 3 }
  const moveHidden = panelFunction("moveCursor", hidden)
  moveHidden(1)
  assert.equal(hidden.cursorIndex, 0)
  moveHidden(-1)
  assert.equal(hidden.cursorIndex, -2)
})

test("h and l move the highlight and Enter applies it", () => {
  const presets = [{ value: "1" }, { value: "1.6" }, { value: "2" }]
  const root = { focusedScalePresets: presets, focusedScaleCursor: "1.6", focusedScaleValue: "2" }
  const step = panelFunction("stepFocusedScale", root)
  step(1)
  assert.equal(root.focusedScaleCursor, "2")
  step(1)
  assert.equal(root.focusedScaleCursor, "2", "arrows stop at the last pill")
  assert.match(qml, /else if \(!root\.expanded && dx !== 0 && root\.cursorIndex === -1\) root\.stepFocusedScale\(dx\)/)
  assert.match(functionSource("activateCursor"), /if \(root\.cursorIndex === -1\) \{\s+root\.setFocusedScale\(root\.focusedScaleCursor\)/)
})

test("the scale row never writes monitor config itself", () => {
  for (const name of ["setFocusedScale", "stepFocusedScale", "moveCursor"]) {
    assert.doesNotMatch(functionSource(name), /hyprctl|monitors\.lua|Process|command/, name)
  }
  assert.doesNotMatch(qml, /"hyprctl", "(keyword|eval)"/)
})
