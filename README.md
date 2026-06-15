# Pzathy Tool

A SwiftUI multi-tool app for everyday work (IT, office, etc.). The concept is a
growing catalog: **Field → Category → Tool**. The first tool shipped is the
**Music Converter**.

- **Platform:** iOS 15+ (SwiftUI)
- **Architecture:** feature-based folders, `ObservableObject` managers injected
  as `@EnvironmentObject`
- **Theme:** natural, muted sage-green with a calm dark mode (light / dark / system)
- **Languages:** English & ខ្មែរ (Khmer), switchable live with no restart

## Demo accounts

Auth is intentionally a stub (no registration / reset / profile editing yet).
Three hard-coded users — tap a card on the login screen to autofill:

| Username  | Password     | Role          |
|-----------|--------------|---------------|
| `admin`   | `admin123`   | Administrator |
| `officer` | `officer123` | Office Staff  |
| `it`      | `it123`      | IT Support    |

## App structure

```
pzathy_tool/
├─ App/                 RootView (auth gate) + MainTabView (3 tabs + mini player)
├─ Core/
│  ├─ DesignSystem/     AppColor palette + ThemeManager
│  ├─ Localization/     LocalizationManager (en / km, runtime switch)
│  ├─ Ads/              AdsManager + AdBannerView (prepared, hidden, OFF)
│  ├─ Common/           ShareSheet, Thumbnail, formatters
│  └─ Storage/          FileStorage (JSON + downloads on disk)
└─ Features/
   ├─ Auth/             AuthManager + LoginView (3 dummy users)
   ├─ Home/             Dashboard (greeting, quick access, recents)
   ├─ Tools/            Catalog (Field → Category → Tool) + browsing
   ├─ Settings/         Profile header, language, theme, logout
   └─ MusicConverter/   The first tool (models, services, player, views)
```

### Tabs
1. **Home** – dashboard: greeting, quick access to live tools, recently played.
2. **Tools** – browse fields → categories → tools (only built tools are interactive; the rest show "Coming soon").
3. **Settings** – profile at top, language, theme, background-playback toggle, logout.

## Music Converter

- Paste a YouTube link → convert → get a track with **thumbnail, title, artist, description**.
- **In-app player** with a mini bar (above the tab bar) and a full Now-Playing screen.
- **Controls:** seek/scrub, previous, play/pause, next, **stop** (clears the bar).
- **Background playback** toggle (in the player and Settings) — uses the `audio`
  background mode + lock-screen / Control Center controls.
- **Download** to a file, **multi-share** (downloaded files or source links).
- **Playlists** (= albums): create, add/remove tracks, play, share.
- Library, playlists and downloads persist locally between launches.

### ⚠️ The YouTube → MP3 reality (important)

Real YouTube audio extraction **cannot** be done reliably on-device, and doing it
directly violates YouTube's Terms of Service and Apple's App Store rules.
Production apps run extraction on a **backend you control** (e.g. wrapping
`yt-dlp`) that returns a signed audio URL + metadata.

This app is built around that seam: the `YouTubeAudioService` protocol. Today it
ships `MockYouTubeAudioService`, which returns **real royalty-free audio**
(SoundHelix) so the whole app — player, downloads, playlists, sharing — works
end-to-end. To go live, implement `YouTubeAudioService` against your backend and
inject it where `MusicConverterViewModel` is created. Nothing else changes.

## Ads (prepared, hidden)

Ad scaffolding exists but is **OFF**: `AdsManager.adsEnabled = false`, and
`AdBannerView` renders nothing while disabled. When ready, flip the flag, add the
SDK (e.g. AdMob), and replace the placeholder in `AdBannerView`. The
background-playback toggle is already wired to `AdsManager` as a future
rewarded-ad hook.

## Notes

- App icon is still the Xcode placeholder (no logo yet).
- Fonts use the system default, per spec.
- Audio session only activates when playback starts, so launching the app never
  interrupts other apps' music.
