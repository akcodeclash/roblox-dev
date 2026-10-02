# roblox-dev

Roblox game project. The game lives in a Roblox Studio place; this folder holds a mirror of its scripts for git.

The game is a classic stage obby. Design: `docs/superpowers/specs/2026-10-02-obby-design.md`. Plan: `docs/superpowers/plans/2026-10-02-obby.md`.

## How the pieces fit

- **Studio is the source of truth.** Claude edits the open place through the `Roblox_Studio` MCP server (configured in `.mcp.json`).
- **Script Sync** (built into Studio) mirrors scripts between Studio and `src/` in both directions, so they can be committed to git.
- **Only scripts and folders reach disk.** Parts, models, UI, and properties are not in git. Their only history is Studio saves, so save with version notes (`Cmd+Option+S`).

## Layout

| Studio | Disk | Contents |
| --- | --- | --- |
| `ServerScriptService.Server` | `src/server/Server` | server entry script and server modules |
| `ReplicatedStorage.Client` | `src/client/Client` | client entry script and client modules |
| `ReplicatedStorage.Shared` | `src/shared/Shared` | modules used by both sides |
| `ServerStorage.UnitTest` | `src/tests/UnitTest` | unit test runner and cases |

`tools/` holds Luau preludes that are pasted into `execute_luau` calls (stage builder, gap checker, playtest helpers). They are not synced into Studio.

The doubled names (`src/server/Server`) are how Script Sync laid the folders out; they are expected.

File naming on disk decides the instance type in Studio:

| File | Instance |
| --- | --- |
| `name.luau` | `ModuleScript` |
| `name.server.luau` | `Script` with `RunContext = Server` |
| `name.client.luau` | `Script` with `RunContext = Client` |
| `name.local.luau` | `LocalScript` |
| `name/` | `Folder` |
| `name/init.*.luau` | script with children |

## Working through the MCP

- Call `list_roblox_studios` first; every tool call needs a `studio_id`.
- **Scripts:** create and edit with `multi_edit`, or edit the `.luau` file on disk and let sync carry it in.
- **Everything else** (parts, models, UI, properties, queries): `execute_luau`.
- `execute_luau` cannot parent a `Script`, `LocalScript`, or `ModuleScript` anywhere. Its thread is sandboxed and the call fails with a `Capabilities` error. It can create folders and other instances.
- `execute_luau` cannot `require` a `ModuleScript` either, for the same reason. To check game state during a playtest, read instances (for example `player.leaderstats.Stage.Value`), not module internals.
- After stopping a playtest, the server may spend about 20 seconds retrying saves. Calling `start_stop_play` during that time can leave it stuck on "Start play hasn't finished yet", which only the user can clear in Studio. Wait first: `execute_luau` in Edit with `task.wait(25)`.
- `multi_edit` works in Edit mode only. Input simulation and `character_navigation` need a running playtest (`Client` datamodel).
- `search_game_tree` returns 200 nodes by default; pass `path` to narrow it.
- `http_get` only reaches Roblox docs, and URLs must end in `.md` or be `llms.txt`. Index: `https://create.roblox.com/docs/llms.txt`.
- Publishing to Roblox is manual; the MCP has no publish tool.

## Script Sync rules

- Stop sync in Studio (right-click > Script Sync > Stop Sync) before deleting a synced root folder. Starting and stopping sync can only be done by the user in Studio.
- Do not put attributes or tags on synced scripts; sync ignores them and they can be lost.
- Keep non-script instances out of the synced folders.
- Script names must be valid, unique file names.

## Conventions

These follow Roblox's own guidance (`scripting/locations.md` and the `scripting/security/` pages in the docs).

- One server entry point (`.server.luau` in `Server`) and one client entry point (`.client.luau` in `Client`). All other code is `ModuleScript`s that expose `start()` and are required from an entry point.
- Avoid `LocalScript`s and the `Starter*` containers for code.
- `--!strict` at the top of every script.
- Do not attach scripts to instances in `Workspace`. Tag the instances and handle them from one module with `CollectionService`.
- Anything that matters (prices, rewards, game rules, player data) stays in `ServerScriptService`. Clients can read everything in `ReplicatedStorage`.
- The server validates every remote: type, `math.isfinite` on numbers, value range, then permission and distance. Rate limit anything a client can trigger, including `ProximityPrompt` and `ClickDetector`.
- Inspect the scripts in any Creator Store asset before inserting it. Insert into a folder in `ServerStorage` first, where scripts do not run, and move the asset into `Workspace` only after its scripts are removed.

## The game

- Stages live in `Workspace.Stages` as `Stage1` to `Stage10`. Each pad is tagged `Checkpoint` with a number attribute `Stage`; the finish pad is `Stage = 11`. Hazards are tagged `KillPart`.
- The stage 1 pad is a `SpawnLocation`. Conveyors are anchored parts with `AssemblyLinearVelocity` set; spinners are unanchored bars on a `HingeConstraint` motor, tagged `Spinner` so the server keeps their network ownership. Neither needs code to move.
- Characters are in the `Players` collision group and pass through each other.
- Every part a player walks on has a number attribute `Order`. After moving or adding parts, run `tools/check_gaps.luau` through `execute_luau` to confirm every jump is still possible.
- Unit tests run automatically at server start in Studio (`UnitTestRunner.server.luau`). Start a playtest and read `get_console_output` for the `[SUMMARY]` line.
- Data stores do not work in Studio until "Enable Studio Access to API Services" is on, so `[PlayerData]` and `DataStoreService` warnings are expected. With it on, progress persists between playtests.
