---
name: distribute
description: Post a finished video to every platform for a brand account (TikTok, Instagram, YouTube, Facebook) through Blotato, collect the live links, and send them to Discord. Use right after a video is finished (for example at the end of the eMoney deals video skill), or when June says "post this", "distribute this", "send it out", or names a brand and an mp4.
---

# Distribution engine

One engine, one setup file per brand. The engine never changes per brand. Everything brand-specific lives in `distribution/brands/<brand>.json`.

## Inputs

- **Video**: a finished mp4 (local path in this session, or a public URL).
- **Brand**: which file in `distribution/brands/` (for example `emoney`).
- **Account**: which account inside that brand (for eMoney: `pokemon`, `clearance_faceless`, `clearance_ugc`). If the video came from a skill that already knows the account, use that. Otherwise ask. Never guess the account.
- **Caption / title**: from the video skill if it wrote one. Otherwise write one using the brand's `caption_rules`, then show it in the confirmation step.

## Step 0. Load and check the brand file

1. Read `distribution/brands/<brand>.json`.
2. Stop and tell June exactly what is missing if any of these are true for the chosen account:
   - an `enabled` platform has `blotato_account_id` set to `null`, or a value starting with `TODO`
   - a Facebook target has no `page_id`
   - Discord `mode` is `blotato` but this account has no `channel_id` (not needed for `manual`)
3. Call `blotato_list_accounts` and confirm every `blotato_account_id` (and Facebook `page_id`) in the file still exists. If one is gone, stop and say which profile got disconnected. Do not post to the rest and leave one out without saying so.

## Step 1. Confirm (if the brand asks for it)

If `confirm_before_posting` is `true`, show June one short block and wait for a yes:

```
Posting to <account label>:
  TikTok    @handle
  Instagram @handle (Reel)
  YouTube   <channel> (Short)
  Facebook  <page> (Reel)
Caption: "<caption>"
YouTube title: "<title>"
Post it? (yes / edit / no)
```

If it's `false`, skip straight to Step 2.

## Step 2. Get the video to a public URL

- **Public URL already**: use it as-is.
- **Local file**: call `blotato_create_presigned_upload_url`, then upload the bytes with
  `curl -sS -X PUT -H "Content-Type: video/mp4" --data-binary @<file> "<uploadUrl>"`
  and check for HTTP 200. Only then use the returned `publicUrl`.
- If the upload fails, retry once. If it fails again, stop and report it. Do not post a missing file.

## Step 3. Post to every enabled platform

Make one `blotato_create_post` call per platform, using `mediaUrls: [publicUrl]` and the values from the brand file:

| Platform  | Fields from brand file |
|-----------|------------------------|
| tiktok    | `privacyLevel`, `disabledComments`, `disabledDuet`, `disabledStitch`, `isBrandedContent`, `isYourBrand`, `isAiGenerated` |
| instagram | `mediaType: "reel"`, `shareToFeed` |
| youtube   | `title`, `privacyStatus`, `shouldNotifySubscribers`, `containsSyntheticMedia` |
| facebook  | `pageId`, `mediaType: "reel"` |

Post right away (no `scheduledTime`) unless June asks for a specific time.

## Step 4. Wait for each post to go live and collect links

- If `blotato_create_post` returns a live URL, record it.
- If it returns a `postSubmissionId` that's still processing, poll `blotato_get_post_status` about every 20 seconds, for up to 10 minutes per post.
- Record each platform as one of: `live` (with the public URL), `failed` (with the error), or `still processing after 10 min`.

## Step 5. Report failures loudly

If any platform is not `live`, the first line of the reply is:

```
NOT POSTED: <platform> for <account>. Reason: <error>
```

Then offer to retry just that platform. Never call the run "done" while a platform failed. The whole point of this engine is that nothing quietly goes unposted.

## Step 6. Send links to Discord

Build the message from the brand's `discord.message_template`.

- **`discord.mode = "blotato"`**: call `blotato_create_post` with the Blotato Discord `accountId` and the account's `channel_id`, as a text-only post (`mediaUrls: []`).
- **`discord.mode = "manual"`**: print the finished message in a code block so June can copy-paste it in one move.

Only include `live` links. If something failed, put the failure line in the message too, so the Discord channel never shows a full set when one is missing.

## Step 7. Final summary

End with one block:

```
<account label>. <date/time>
  TikTok     <url | FAILED: reason>
  Instagram  <url | FAILED: reason>
  YouTube    <url | FAILED: reason>
  Facebook   <url | FAILED: reason>
Discord: sent to #<channel> | ready to paste | FAILED
```

## Rules

- Never post to an account or platform that isn't in the brand file.
- Never guess an account ID, page ID or channel ID. They come from the brand file, checked against `blotato_list_accounts`.
- One video goes to one account's platforms. Never cross-post into another account's profiles.
- Never post to Discord as June's personal user (self-bot). Only through the Blotato Discord connection or manually.
