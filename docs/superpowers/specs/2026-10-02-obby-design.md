# Classic stage obby: design

Date: 2026-10-02

## Purpose

A real, publishable Roblox game, built mostly by Claude through the Roblox Studio MCP server. The workflow itself is under evaluation, so the first release is kept small enough to exercise the whole pipeline: build, playtest, publish.

## Scope of the first release

- Classic stage obby with 10 stages and checkpoints.
- Bright, classic obby look: colored blocks in the sky, each stage its own color.
- Progress saves; a returning player resumes at their highest stage.
- Stage number shown on the built-in Roblox leaderboard.
- No monetization.

Out of scope for launch:

- Purchases of any kind (skip stage, game passes).
- Custom UI.
- A "play again" control for players who finished.
- Rideable moving platforms and disappearing platforms.
- Movement validation against teleporting exploiters.

## Assumptions

- Players are on phone, tablet, and desktop, so jumps must be fair on touch controls.
- Players share a server and see each other but do not interact.

## Done means

A stranger can join the published game, play stages 1 to 10, leave, and return to their saved stage.

## World structure

Everything below lives in `Workspace`.

- A `Stages` folder holds `Stage1` to `Stage10`, each a `Model`.
- Each stage begins with a checkpoint pad: a part tagged `Checkpoint` with a number attribute `Stage`. The pad is also where a player on that stage respawns.
- A final pad after stage 10, tagged `Checkpoint` with `Stage = 11`, marks completion.
- Hazards are parts tagged `KillPart`.
- Falling off is handled by the engine's built-in fall limit.
- The default `Baseplate` and `SpawnLocation` are removed. New players spawn on the stage 1 pad.

Stages live in the place, not in code. They are visible and adjustable by hand in Studio. Their history is Studio saves with version notes; git holds scripts only.

## Assets

The Creator Store is the first choice for obstacles and props. Claude searches it for free assets with `search_asset` and inserts them with `insert_asset`, and builds from plain parts only when nothing suitable is found.

Rules for every inserted asset:

- Free assets only.
- Before an asset is kept, its scripts are listed and read. Scripts that are not needed are deleted. An asset whose scripts are obfuscated or unclear is rejected.
- Behavior comes from this project's tags and server modules, not from scripts shipped inside assets. A store-bought lava brick has its own script removed and is tagged `KillPart`. This keeps one implementation of each rule and keeps backdoors out.
- An asset that only works with its own script is kept only if that script has been read in full and does nothing beyond its stated job.
- Assets are recolored where needed to fit the stage's color.

## Server code

All code is in `ServerScriptService.Server` (on disk: `src/server/Server`). Every file starts with `--!strict`. Each module exposes `start()`.

| Module | Job |
| --- | --- |
| `Main.server.luau` | Entry point. Requires the modules below and calls `start()` on each. |
| `PlayerData` | Loads a player's highest stage on join, holds it in memory, saves it. |
| `Checkpoints` | Handles touches on `Checkpoint` parts and advances the player's stage. |
| `Spawning` | On each respawn, places the character on the pad for the player's current stage. |
| `KillParts` | Handles touches on `KillPart` parts and kills the character. |
| `Leaderboard` | Shows each player's stage on the built-in leaderboard. |
| `Rules` | Pure functions for the two rules below, with no engine dependencies, so they can be unit tested. |

Tagged parts are found with `CollectionService`, including parts added after startup. No scripts are attached to parts in `Workspace`.

There is no client code and no shared code at launch. `ReplicatedStorage.Client` and `ReplicatedStorage.Shared` stay empty until a feature needs them.

### Rule: advancing a stage

A touch on a checkpoint advances the player only when the checkpoint's `Stage` is exactly one above the player's current stage. Any other touch does nothing.

A new player is on stage 1. A player on stage 10 who touches the pad with `Stage = 11` moves to stage 11, which means finished. The leaderboard shows the stored number, so a finished player shows 11.

### Rule: merging on save

A save writes whichever is higher: the stored stage or the in-memory stage.

## Cheat resistance

- All progress logic runs on the server. The client is never asked which stage it is on.
- The advancing rule makes touching or teleporting to a distant pad useless.
- An exploiter can still teleport from pad to pad in order. With no rewards or purchases tied to progress, the damage is a false leaderboard number. Accepted for launch.

## Saving

Follows Roblox's data store best practices.

- One data store, `PlayerData`. One key per player: `User_<UserId>`.
- The value is a table, `{ stage = <number> }`, so fields can be added later.
- Load once on join. Gameplay reads and writes the in-memory copy only.
- Save when the player leaves, when the server shuts down, and every 180 seconds per player with a random initial offset.
- Saves use `UpdateAsync` with the merge rule. There is no session locking; because stage only rises, concurrent writes from two servers cannot lose progress.

### Failures

- Every data store call is wrapped in `pcall` and tried up to 5 times. The delay between attempts starts at 1 second, doubles each time, and has random jitter added.
- If loading still fails, the player starts the session on stage 1 and plays normally. The merge rule guarantees that saving this session cannot lower stored progress.
- If saving still fails, the failure is logged and the next periodic save tries again.

### Constraints

- Data stores work only in a published place with Studio API access enabled. Before publishing, every Studio playtest takes the load-failure path. Saving is verified after publishing.
- A player who has finished respawns on the finish pad.
- The key pattern supports Roblox's automated right-to-be-forgotten processing, configured in the Creator Dashboard at publish time.

## Stages

Each stage introduces one idea.

| Stage | Idea |
| --- | --- |
| 1 | Wide platforms, short gaps |
| 2 | Smaller platforms, longer gaps |
| 3 | A path crossed by lava strips (first `KillPart`s) |
| 4 | Narrow beams |
| 5 | Stepping stones over lava, with turns |
| 6 | Climb and drop, using trusses |
| 7 | Conveyors pushing the player off course |
| 8 | Spinning lava bars |
| 9 | Thin zigzag between lava walls |
| 10 | Finale mixing all of the above |

- Conveyors use a part's surface velocity; no code.
- The spinner in stage 8 is physics-driven and tagged `KillPart`. If it proves jerky or unreliable in playtest, it is replaced by a small server or client module. This is the least certain piece of the design.

## Build order

1. Server modules, plus stages 1 and 2 as a test bed.
2. Stages 3 to 10, one at a time.
3. Lighting and color palette.
4. Publish (done by the user), then verify saving in the live place.

## Testing

- **Unit tests, written first**, for the two functions in `Rules`: advancing a stage and merging on save.
- **Systems by playtest through the MCP.** Claude starts a playtest, moves the character onto pads and hazards, and checks the leaderboard value, the respawn position, and the console for errors.
- **Stage geometry by measurement.** The real jump limits are measured once in stage 1. A script then checks every gap in every stage against those limits. Screenshots are taken of each stage.
- **Feel is judged by the user.** The user plays each stage on desktop and in the device simulator; Claude adjusts.
- **Saving** is tested after publishing.

## Manual steps for the user

- Save the place and, at the end, publish it.
- Enable Studio access to API services once the place is published.
- Play each stage and report what feels wrong.
- Configure right-to-be-forgotten processing in the Creator Dashboard.
