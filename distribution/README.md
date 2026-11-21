# Distribution

One engine, one setup file per brand.

- **Engine:** `.claude/skills/distribute/SKILL.md`. It uploads the video, posts to every platform, waits until each post is live, collects the links, sends them to Discord and flags anything that failed. You write it once and change it rarely.
- **Brands:** `distribution/brands/<brand>.json`. Accounts, Blotato IDs, Discord channels, caption rules and the confirm setting.

## Using it

After a video is finished in Claude, say something like:

> post this to emoney pokemon

## Account-level skill (for Claude Projects and regular chats)

The repo skill only loads in Claude Code sessions with this repo. To use it anywhere in Claude, run `distribution/build_skill.sh` and upload `distribution/distribute-skill.zip` in Claude under Settings, then Skills. After changing the engine or a brand file, rebuild and re-upload, or the uploaded copy goes stale.

## Adding a new brand

1. Copy `brands/emoney.json` to `brands/<new-brand>.json`.
2. Connect that brand's profiles in Blotato.
3. Fill in the handles, Blotato account IDs, Facebook page IDs and Discord channels.
4. Test on one video.

## eMoney status

All 12 profiles are connected and filled in:

| Account | Key | TikTok | Instagram | YouTube | Facebook |
|---|---|---|---|---|---|
| Pokémon | `pokemon` | @pokedealradar | @pokedealradar | Poke deal radar | Poke deal radar |
| Faceless Clearance | `clearance_faceless` | @theprofitplugdaily | @theprofitplugdaily | The profit plug daily | The Profit Plug Daily |
| UGC Clearance | `clearance_ugc` | @juneresells | @june.resells | June Resells | June resells |

Discord is manual: the engine prints a message ready to paste.
