# RapidAPI MP3 downloader — setup

The app converts YouTube links to MP3 via the RapidAPI endpoint
`youtube-mp3-audio-video-downloader`. It activates automatically as soon as a
key is available; with no key it falls back to the open-source Piped extractor.

> ⚠️ Never hard-code the key in source — it would be committed to git. The key
> shared in chat should be considered leaked; rotate it on RapidAPI.

## Where the key comes from (first match wins)

1. **Environment variable `RAPIDAPI_KEY`** — for local dev: Xcode → Product →
   Scheme → Edit Scheme → Run → Arguments → Environment Variables, add
   `RAPIDAPI_KEY = <your key>`.
2. **Info.plist key `RapidAPIKey`** — for builds you ship/share.

### Wiring via .xcconfig (already scaffolded in this repo — recommended)

The project is already wired so you only need to drop in your key:

1. Copy the example to the gitignored local file and add your key:
   ```sh
   cp Secrets.local.xcconfig.example Secrets.local.xcconfig
   # edit Secrets.local.xcconfig → RAPIDAPI_KEY = your_real_key
   ```
2. Build & run. That's it.

How it's wired (for reference):
- `Secrets.xcconfig` (committed, no secret) is set as the project's
  **base configuration** for Debug & Release. It `#include?`s
  `Secrets.local.xcconfig` (gitignored) and defaults `RAPIDAPI_KEY` to empty.
- The build setting `INFOPLIST_KEY_RapidAPIKey = $(RAPIDAPI_KEY)` injects the
  value into the generated Info.plist (this target uses
  `GENERATE_INFOPLIST_FILE = YES`, so there's no Info.plist file to edit).
- `RapidAPIConfig` reads `Bundle.main.object(forInfoDictionaryKey: "RapidAPIKey")`.

With no `Secrets.local.xcconfig` (fresh clone / CI), the key is empty and the
app falls back to the Piped extractor — no build break.

## How it works

- Video id is parsed from the link (`YouTubeLink.videoID`), e.g.
  `https://youtu.be/rVQ2i8q2Y9A` → `rVQ2i8q2Y9A`.
- Calls `GET /get_mp3_download_link/{id}?quality=low&wait_until_the_file_is_ready=true`.
- The returned file **404s until encoding finishes (20–300 s)**, so the client
  polls `file` then `reserved_file` (HEAD) until one is reachable before handing
  the URL to the player/downloader. This avoids 404s in AVPlayer.
- Title / artist / thumbnail are filled from YouTube's free oEmbed endpoint.

## Tunables (`RapidAPIConfig`)

| Setting               | Default | Notes                                        |
|-----------------------|---------|----------------------------------------------|
| `quality`             | `low`   | `low` or `high`                              |
| `waitUntilReady`      | `true`  | server holds request until ready (≤ 15 min)  |
| `maxWaitSeconds`      | `300`   | max client wait for the file to become ready |
| `pollIntervalSeconds` | `5`     | delay between reachability checks            |

## Legal / distribution note

Downloading YouTube content violates YouTube's ToS, and Apple's App Store
guidelines (5.2.3 / 1.4.x) reject YouTube downloaders. Suited to personal,
sideloaded, or educational use.
