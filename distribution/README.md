# Distribution

One engine, one setup file per brand.

- **Engine:** `.claude/skills/distribute/SKILL.md`. It uploads the video, posts to every platform, waits until each post is live, collects the links, sends them to Discord and flags anything that failed. You write it once and change it rarely.
- **Brands:** `distribution/brands/<brand>.json`. Accounts, Blotato IDs, Discord channels, caption rules and the confirm setting.

## Using it

After a video is finished in Claude, say something like:

> post this to emoney pokemon

## Adding a new brand

1. Copy `brands/emoney.json` to `brands/<new-brand>.json`.
2. Connect that brand's profiles in Blotato.
3. Fill in the handles, Blotato account IDs, Facebook page IDs and Discord channels.
4. Test on one video.

## eMoney status

Blocked until the Pokémon, Clearance and UGC Face profiles on TikTok, Instagram, YouTube and Facebook are connected in Blotato. Every `TODO` and `null` in `brands/emoney.json` has to be filled in before it can post.
