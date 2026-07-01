# AGENTS.md

## Cursor Cloud specific instructions

### What this repo is
This is a **Q-SYS Designer Lua plugin** ("Fast Deploy"), not a client/server app. See `README.md` for feature/usage docs. The plugin runs *inside* QSC's proprietary **Q-SYS Designer 9.0+** on a **Q-SYS Core** (or its emulator). Neither Q-SYS Designer nor the Core runs on Linux, so there is **no application/GUI to launch in this VM** and no local server/service to start. Validation here is limited to linting, syntax/compile checking, and running the plugin's Lua logic against mocked Q-SYS APIs.

### Source layout (non-obvious)
- `plugin.lua` is the framework entry point. The `.lua` fragments (`info`, `properties`, `controls`, `layout`, `runtime`, `model`, `pages`, `pins`, `wiring`, `components`, `rectify_properties`) are **not standalone modules** — they are inlined into `plugin.lua`'s function bodies at compile time via `--[[ #include "file.lua" ]]` directives.
- `runtime.lua` (the event logic) only executes when the host has populated the global `Controls` table. It depends on host-injected globals: `Controls`, `Properties`, `Design`, `Timer`, `HttpClient`, `Network`, `Ping`, and the `rapidjson` module.
- Committed `.qplug` files (`FastDeploy.qplug`, `FastDeployPlugin.qplug`) are prebuilt/compiled artifacts.

### Lint
Use `luacheck`. Q-SYS runtime globals are host-injected, so a bare `luacheck *.lua` reports them as "undefined variable" / "non-standard global" — that is expected noise, not real errors. Declare the Q-SYS globals (via a `--std`/`globals` config) to get a clean run; the meaningful signal is **0 errors** (remaining items are style warnings: trailing whitespace, unused args).

### Build / compile
- The real compile+sign toolchain (`plugincompile/PLUGCC.exe`, `pluginsigning/plugin_tool.exe`) is **Windows-only** and the `.exe`s are **not in the repo** — you cannot produce a signed `.qplug` on Linux.
- To syntax-check on Linux, inline the `#include` directives into one file and run `luac5.4 -p` on the result.
- `plugincompile/compile_plugin.sh` (version bump / GUID / line-ending fix) is committed with **CRLF line endings and uses bashisms**, so `dash`/`sh` chokes on it. Run a `dos2unix`'d copy with `bash` (do not modify the committed file). It edits `info.lua` in place — revert with `git checkout -- info.lua` if you only meant to test it.

### Run plugin logic locally
There is no host to run in. To exercise the logic, load the fragments and `runtime.lua` in `lua5.4` with mock implementations of `Design` / `Timer` / `HttpClient` / `Network` / `Ping` / `rapidjson`, build a mock `Controls` table from `controls.lua`, then drive the flow by calling control `EventHandler`s (e.g. `Controls.Get.EventHandler()` for discovery, `Controls.Assign.EventHandler()` for pairing). `rapidjson` is a Q-SYS built-in with no drop-in Linux package, so mock it.
