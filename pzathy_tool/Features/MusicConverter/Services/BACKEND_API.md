# YouTube → MP3 Backend API

This is the contract the iOS app (`BackendYouTubeAudioService`) expects from your
conversion server. The server is the "y2mate-style" piece: it runs the extraction
and transcoding that can't be done reliably (or shipped to the App Store) on-device.

The app is **already wired to this contract**. To turn it on, set the base URL:

- In code: `BackendConfig.defaultBaseURL` in `BackendYouTubeAudioService.swift`, or
- In `Info.plist`: key `YTBackendBaseURL` (and optional `YTBackendAPIKey`).

When no URL is set, the app keeps using the open-source Piped extractor.

---

## Endpoint

```
POST {baseURL}/api/convert
```

### Request headers

| Header          | Value                       | Notes                          |
|-----------------|-----------------------------|--------------------------------|
| `Content-Type`  | `application/json`          | required                       |
| `Accept`        | `application/json`          | required                       |
| `Authorization` | `Bearer <YTBackendAPIKey>`  | sent only if an API key is set |

### Request body

```json
{
  "url": "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
  "format": "mp3",
  "bitrate": 320
}
```

### Success — `200 OK`

```json
{
  "id": "dQw4w9WgXcQ",
  "title": "Rick Astley - Never Gonna Give You Up",
  "artist": "Rick Astley",
  "description": "Official video",
  "durationSeconds": 213,
  "thumbnailUrl": "https://img.youtube.com/vi/dQw4w9WgXcQ/hqdefault.jpg",
  "audioUrl": "https://cdn.yourdomain.com/files/dQw4w9WgXcQ.mp3",
  "mimeType": "audio/mpeg",
  "bitrate": 320
}
```

`audioUrl` is the **only required field** and must point to a real, playable MP3
(reachable by `AVPlayer` and `URLSession.download`). Everything else is optional —
the app fills sensible defaults (e.g. derives the thumbnail from the video id).

### Errors — any non-2xx

```json
{ "error": "Could not extract audio from this link.", "code": "EXTRACTION_FAILED" }
```

The app shows `error` to the user when present, and otherwise falls back to the
Piped extractor so conversion still yields something playable.

---

## Reference server (yt-dlp + ffmpeg)

Any stack works; the essentials per request are:

1. Validate the URL.
2. `yt-dlp -x --audio-format mp3 --audio-quality <bitrate> -o <id>.<ext> <url>`
   (yt-dlp invokes ffmpeg for the transcode).
3. Store the file somewhere the app can fetch (local static dir, S3, signed URL…).
4. Return the JSON above with `audioUrl` pointing at it.

Operational notes:
- Conversion is slow (download + transcode). The client waits up to **120 s**.
  For longer jobs, switch to a job/poll pattern (`202` + `GET /api/status/{id}`);
  the client can be extended to match.
- Cache by video id so repeat requests are instant.
- Keep `yt-dlp` auto-updating — YouTube breaks extraction often.
- Rate-limit and require the API key in production.

## Legal / distribution note

Downloading YouTube content violates YouTube's Terms of Service, and Apple's App
Store guidelines (5.2.3, 1.4.x) specifically reject YouTube downloaders. This
backend path is appropriate for personal, sideloaded, or educational use — plan
distribution accordingly.
