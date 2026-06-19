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

### Wiring Info.plist without committing the key (recommended)

1. Create `Secrets.xcconfig` (add it to `.gitignore`):
   ```
   RAPIDAPI_KEY = your_key_here
   ```
2. Set the target's build configuration to use that `.xcconfig`.
3. In `Info.plist` add:
   ```xml
   <key>RapidAPIKey</key>
   <string>$(RAPIDAPI_KEY)</string>
   ```

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
