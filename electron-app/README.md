# Pip 🐾 — Electron port (Windows / macOS / Linux)

A cross-platform [Electron](https://www.electronjs.org/) port of [Pip](https://github.com/TenzinDhonyoe/pip-mascot),
the Claude-usage-aware desktop mascot (the original is a macOS-only Swift app).

Pip is a small, transparent, always-on-top character that walks along the bottom edge of
your screen and changes mood based on your **live Claude Code usage**. Everything runs
locally — it reads your existing Claude Code login, no API key or cloud account required.

![Pip walking](../mascot/front.png)

---

## Run it

```bash
cd electron-app
npm install
npm start
```

That's it on **macOS** and **Windows**. On **Linux/Wayland** the app forces itself onto
XWayland automatically (see [Platform notes](#platform-notes)).

For console logging while developing:

```bash
npm run start:dev
```

## Build installers

```bash
npm run build:win     # NSIS installer (.exe)
npm run build:mac     # .dmg
npm run build:linux   # AppImage + .deb
```

Output lands in `dist/`. Builds are produced with
[electron-builder](https://www.electron.build/).

---

## How it works

Pip is two processes that talk over IPC:

| Process | File | Responsibility |
|---|---|---|
| **Main** (Node) | [`main.js`](main.js) | Owns the OS window + tray, reads your token, polls usage, moves the window |
| **Renderer** (web page) | [`src/`](src/) | Draws and animates Pip on a `<canvas>` |
| **Bridge** | [`preload.js`](preload.js) | Exposes a safe `window.pip` API to the page |

**The window is the character.** It's a 280×230 frameless, transparent, always-on-top
window. To "walk," the app moves the whole window across the screen (`win.setPosition`)
rather than moving the sprite inside it.

**Usage drives the mood.** Every 30 s the poller fetches your usage and feeds a
`UsageStore`, which maps the numbers to a mood:

| Your 5-hour usage | Mood | Behavior |
|---|---|---|
| no data | `sleepy` | sits still |
| on/under pace | `happy` / `focused` | normal walk |
| way under pace near reset | `antsy` / `mad` | hurries (you're wasting quota) |
| ≥ 90 % | `worried` | slows down |

The [`WalkEngine`](src/walk-engine.js) is a per-frame state machine (walk / turn / idle /
sit / peek / drag) that picks a sprite frame from [`assets/`](assets) and a facing
direction; [`renderer.js`](src/renderer.js) draws it.

### Where the usage numbers come from

Claude Code's official usage endpoint (`/api/oauth/usage`) currently returns persistent
HTTP 429 for many accounts — a known server-side issue
([#31021](https://github.com/anthropics/claude-code/issues/31021),
[#30930](https://github.com/anthropics/claude-code/issues/30930),
[#31637](https://github.com/anthropics/claude-code/issues/31637)). So instead, the poller
reads the same numbers Claude Code's own status line uses: the
`anthropic-ratelimit-unified-*` **response headers** returned by a minimal Messages API
call. This is local-token, no extra account, and not affected by the broken endpoint.

> Trade-off: each poll makes a tiny (~1 output token) Messages call. To poll less often,
> raise `pollInterval` in [`src/oauth-poller.js`](src/oauth-poller.js).

The OAuth token is read from your existing Claude Code login:

- **macOS** — the `Claude Code-credentials` Keychain item
- **Windows / Linux** — `~/.claude/.credentials.json` (or `$CLAUDE_CONFIG_DIR`)

---

## Tray menu

Click the 🐾 tray icon for: Pause, Click-Through (let clicks pass through Pip),
Refresh Usage, Show Usage Details, Quit.

---

## Platform notes

- **Windows** — frameless transparent window uses `thickFrame: false` to avoid the resize
  border. Token is read from `%USERPROFILE%\.claude\.credentials.json`.
- **macOS** — the window uses the `panel` level so it floats above full-screen apps, and
  the app hides from the Dock.
- **Linux** — Electron is forced onto **X11/XWayland** (`ozone-platform=x11`) from inside
  `main.js`, because transparent always-on-top windows misbehave on some Wayland
  compositors. No environment variables needed.

---

## Relationship to the original

This is the Electron port. The original macOS/Swift app lives at the repo root
(`Pip.xcodeproj`, `Pip/`) and on GitHub at
[TenzinDhonyoe/pip-mascot](https://github.com/TenzinDhonyoe/pip-mascot). Shared art lives
in [`../mascot`](../mascot); this port also ships its own frame-by-frame sprites in
[`assets/`](assets).
