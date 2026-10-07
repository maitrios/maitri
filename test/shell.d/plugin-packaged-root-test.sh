#!/bin/bash

set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

require_command jq

TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

packaged="$TMPDIR/packaged"
builtin="$TMPDIR/builtin"
home="$TMPDIR/home"
user="$home/.config/maitri/plugins"

write_manifest() {
  local file="$1" id="$2" name="$3"

  mkdir -p "$(dirname "$file")"
  jq -n --arg id "$id" --arg name "$name" '{
    schemaVersion: 1, id: $id, name: $name, version: "1.0.0",
    kinds: ["service", "bar-widget", "panel"],
    entryPoints: {service: "Service.qml", barWidget: "BarWidget.qml", panel: "App.qml"},
    barWidget: {displayName: $name, description: $name, category: "Test", allowMultiple: false}
  }' >"$file"
}

write_manifest "$packaged/mail/manifest.json" maitri.mail "Packaged Mail"
write_manifest "$packaged/mail/ui/manifest.json" maitri.nested "Nested in a package"
write_manifest "$packaged/clock/manifest.json" maitri.clock "Packaged Clock"
write_manifest "$builtin/panels/clock/manifest.json" maitri.clock "Built-in Clock"
write_manifest "$user/acme.weather/manifest.json" acme.weather "Acme Weather"
write_manifest "$user/acme.mail/manifest.json" maitri.mail "Spoofed Mail"

export PACKAGED_ROOT="$packaged" BUILTIN_ROOT="$builtin" USER_ROOT="$user"

run_node_test <<'JS'
const fs = require('fs')
const vm = require('vm')
const { spawnSync } = require('child_process')

const registrySource = fs.readFileSync(path.join(root, 'shell/services/PluginRegistry.qml'), 'utf8')
const shellSource = fs.readFileSync(path.join(root, 'shell/shell.qml'), 'utf8')

function loadFunctions(source, names, context) {
  for (const name of names) {
    const match = source.match(new RegExp(`^  function ${name}\\([^\\n]*\\) \\{[\\s\\S]*?^  \\}`, 'm'))
    if (!match) fail(`production function is present: ${name}`)
    vm.runInContext(match[0], context)
  }
}

const registry = vm.createContext({
  Util: { isPlainObject: value => !!value && typeof value === 'object' && !Array.isArray(value) },
  console: { warn() {} },
  registry: {
    packagedDir: process.env.PACKAGED_ROOT,
    firstPartyDir: process.env.BUILTIN_ROOT,
    pluginsDir: process.env.USER_ROOT
  },
  installedPlugins: {},
  registryRevision: 0,
  scanning: true,
  pluginsChanged() {},
  scanFinished() {}
})
loadFunctions(registrySource, [
  'isSafeEntryPoint', 'validateManifest', 'trustedCapabilities',
  'stampHostCapabilities', 'parseScanOutput', 'scanCommand'
], registry)

const command = registry.scanCommand()
assertDeepEqual(
  command.slice(3),
  [process.env.PACKAGED_ROOT, process.env.BUILTIN_ROOT, process.env.USER_ROOT],
  'the scan walks the packaged root, then the built-in root, then the user root'
)

const scan = spawnSync(command[0], command.slice(1), { encoding: 'utf8' })
assertEqual(scan.status, 0, 'the scan script runs without a compositor')
registry.parseScanOutput(scan.stdout)
const plugins = registry.installedPlugins

assert(!!plugins['maitri.mail'], 'a packaged plugin is discovered')
assertEqual(plugins['maitri.mail'].__isFirstParty, true, 'a packaged plugin is first-party')
assertEqual(
  plugins['maitri.mail'].__sourceDir,
  path.join(process.env.PACKAGED_ROOT, 'mail'),
  'a packaged plugin loads from its package directory, not from a user plugin claiming its id'
)
assertEqual(plugins['maitri.mail'].name, 'Packaged Mail', 'a user plugin cannot take over a packaged id')
assert(!plugins['maitri.nested'], 'only top-level package directories are plugins')
assertEqual(plugins['maitri.clock'].name, 'Built-in Clock', 'a built-in plugin wins over a packaged one with the same id')
assertEqual(plugins['acme.weather'].__isFirstParty, false, 'user plugins stay third-party')

assert(
  /readonly property string packagedPluginsDir: "\/usr\/share\/maitri-plugins"/.test(shellSource),
  'the shell scans the fixed packaged root, independent of MAITRI_PATH'
)
assert(
  /"packagedPluginsDir=" \+ shell\.packagedPluginsDir/.test(shellSource),
  'the shell logs the packaged root at startup'
)
assert(
  /pluginRegistry\.packagedDir = shell\.packagedPluginsDir/.test(shellSource),
  'the shell hands the packaged root to the plugin registry'
)
JS

catalog=$(HOME="$home" MAITRI_PATH="$ROOT" MAITRI_PACKAGED_PLUGINS_DIR="$packaged" "$ROOT/bin/maitri-plugin-catalog")

jq -e --arg dir "$packaged/mail" '
  any(.[]; .id == "maitri.mail" and .firstParty and .sourceDir == $dir and .barWidgetPath == $dir + "/BarWidget.qml")
' <<<"$catalog" >/dev/null || fail "the plugin catalog lists packaged plugins as first-party" "$catalog"
pass "the plugin catalog lists packaged plugins as first-party"

jq -e 'all(.[]; .id != "maitri.nested")' <<<"$catalog" >/dev/null ||
  fail "the plugin catalog reads only top-level package directories"
pass "the plugin catalog reads only top-level package directories"

jq -e --arg root "$ROOT/shell/plugins/" '
  [.[] | select(.id == "maitri.clock")] | length == 1 and (.[0].sourceDir | startswith($root))
' <<<"$catalog" >/dev/null || fail "the plugin catalog prefers a built-in over a packaged plugin with the same id"
pass "the plugin catalog prefers a built-in over a packaged plugin with the same id"

jq -e 'any(.[]; .id == "acme.weather" and (.firstParty | not))' <<<"$catalog" >/dev/null ||
  fail "the plugin catalog keeps user plugins third-party"
pass "the plugin catalog keeps user plugins third-party"
