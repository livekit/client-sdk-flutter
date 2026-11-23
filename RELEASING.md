# Releasing client-sdk-flutter

This repository releases with [verwalter](https://github.com/livekit/verwalter).
The commands that are the same in every repository are in the
[verwalter cheat sheet](https://github.com/livekit/verwalter/blob/main/docs/cheat-sheet.md).
This file holds what is specific to this repository.

## Packages

| Package | Tag | Goes to |
|---|---|---|
| `livekit_client` | `v<version>` | pub.dev, and a GitHub release with no assets |

Six files carry the version, and the release PR moves them together:

- `pubspec.yaml`
- `.version`
- `lib/src/livekit.dart`
- `ios/livekit_client.podspec`
- `macos/livekit_client.podspec`
- `README.md`

If the files disagree, `scripts/check_version.dart` fails CI.

## Workflows

| File | Starts when | Does |
|---|---|---|
| `changeset-check.yaml` | A PR is opened or updated | Fails a PR that changes the package without a changeset. Fails a breaking change without a `major` changeset, with dart-apitool. Fails the release PR when the publish dry run fails. |
| `release-pr.yaml` | A push to `main` | Keeps the release PR `release/main` current. |
| `release.yaml` | The release PR merges | `gate` checks that the PR is the release PR. Then it validates the package, tags and creates a draft GitHub release. Then it starts `publish.yaml` on the tag, waits for it and checks the end state. |
| `publish.yaml` | `release.yaml` starts it on the tag, or you run it by hand on a tag | Publishes to pub.dev, then makes the GitHub release public. |
| `pre-release.yaml` | Run by hand | Opens an rc PR from the branch it runs on. |

`publish.yaml` is a workflow of its own because pub.dev accepts trusted
publishing only from a run on a tag. It runs `dart pub publish --force`.
The exact `flutter_webrtc` pin always gives one pub validation warning,
and `--force` lets the publish continue past it. The check that the
package can publish is `dart pub publish --dry-run --ignore-warnings`:
it fails on a pub error and ignores warnings, like the publish. It runs
on every PR, as the publish dry run on the release PR, and in the
`validate` job of `release.yaml` before the tag. A new pub warning
shows only in the log.

## Release

The first release after the switch to verwalter is an rc: run
`gh workflow run pre-release.yaml --ref main` and merge the rc PR. It is
the first run of `release.yaml`, and the first start of `publish.yaml`
through `workflow_dispatch`, which pub.dev must allow. An rc on pub.dev
does not reach users who depend on `^2.x`. Remove this paragraph after
that rc is on pub.dev.

1. Merge the release PR.
2. Watch the run of `release.yaml`: `gh run list --workflow release.yaml --limit 1`.
   Its `publish` job waits for the run of `publish.yaml` on the new tag.

A complete release has two parts:

- a public GitHub release on the tag `v<version>`
- the version on pub.dev: `https://pub.dev/packages/livekit_client/versions/<version>`

The `verify` job of `release.yaml` checks both with `verwalter status --check`.

## Pre-release

`gh workflow run pre-release.yaml --ref main`. Merging the rc PR tags
`v<version>-rc.<n>` and publishes it to pub.dev as a pre-release.

## A release failed

Find the cause first. The paths by cause are in the
[recovery section](https://github.com/livekit/verwalter/blob/main/docs/release-workflows.md#recovery).

| Situation | Command |
|---|---|
| A job failed for a transient reason | `gh run rerun <run-id> --failed` |
| `validate` failed after the merge: pub reports an issue other than the `flutter_webrtc` pin | Merge the fix with the `internal` label and no changeset, and merge nothing else before the release. Then run `gh workflow run release.yaml -f ref=<fix commit>`. It tags the version that the release PR wrote on that commit. A fix with a changeset releases the next version instead, and leaves this version without a tag. |
| The publish to pub.dev failed after the tag | `gh workflow run publish.yaml --ref <tag>`. A version pub.dev has is skipped. |
| The workflow file needed a fix, and the fix is on `main` | `gh workflow run release.yaml -f ref=<tag>` |
| The released commit is wrong | `verwalter release --abandon <tag>`, then a changeset and the next version |

pub.dev does not let you delete or replace a version. A broken version
stays on pub.dev. Release the fix as the next version.
