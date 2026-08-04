# mirror-caddyserver

OCX mirror for [Caddy](https://github.com/caddyserver/caddy). One repository,
one spec directory per package.

| Package | Spec | Publishes to | Announced as | Upstream SPDX |
|---|---|---|---|---|
| [caddy](https://github.com/caddyserver/caddy) | [`caddy/mirror.yml`](caddy/mirror.yml) | `ghcr.io/ocx-contrib/caddyserver/caddy` | [`ocx.sh/caddyserver/caddy`](https://index.ocx.sh/caddyserver/caddy) | `Apache-2.0` |

Each upstream release is discovered, re-bundled, smoke-tested per
`(version, platform)` and only then pushed with cascade tags, after which the
result is announced into the OCX index.

## Layout

```
mirror-base.yml         repo-wide policy every spec inherits via `extends:`
caddy/
├── mirror.yml          the spec — never at the repo root
├── metadata.json       bundle interface
├── CATALOG.md          → ocx package describe
├── logo.svg / logo.png describe assets, 512px PNG
└── tests/smoke.star    Starlark smoke test
```

`LICENSE` and `NOTICE.md` are shared at the root. Logos are **not** — each
package carries its own, because a repo-root `logo.*` sits in no workflow's
`paths:` filter, so replacing it would publish nothing until some unrelated
edit happened to fire.

⚠️ `extends:` is a **shallow** merge of top-level keys. A spec that restates
`platforms:` to change one runner drops every `containers:` entry with it, and
nothing reds — the legs simply stop existing, and every `os.features` claim
goes back to being asserted rather than verified. `platforms:` is deliberately
kept **out** of `mirror-base.yml` here so there is no base block to
half-restate: the container matrix is downstream of a per-package libc
measurement and belongs beside it.

## Platforms

`caddy` publishes six platform entries: both Linux arches, both macOS arches
and both Windows arches — the complete set ocx can express. Both Linux
binaries were measured and are **statically linked** (`file` → "statically
linked", `readelf -l | grep -c INTERP` → 0, at v2.11.4 *and* at the oldest
in-range v2.9.0; `caddy build-info` reports `CGO_ENABLED=0`). They are not
UPX-packed — `strings -a caddy | grep -c '^UPX'` → 0 and section headers are
present — so `file`'s answer is the ELF's, not a packer stub's.

`os.features` states what an artifact requires *of the host*, and a static
binary requires nothing, so both Linux keys are **bare**. The `alpine:3.20`
container leg is what turns that from an assertion into evidence: `caddy
version` runs and exits 0 in `ubuntu:24.04`, `alpine:3.20` **and** `fedora:40`
from their stock images, with no `containers[].setup` line anywhere. The full
measurement is recorded above the `assets:` block in
[`caddy/mirror.yml`](caddy/mirror.yml).

Upstream publishes 147 assets per release for 129 of which we have no use:
five signature/SBOM sidecars per artifact (`.pem`, `.sig`, `.sbom`,
`.sbom.pem`, `.sbom.sig`), a `.deb` beside **every** linux `.tar.gz` for the
identical (os, arch) pair, plus release-wide `buildable-artifact.tar.gz`,
`src.tar.gz` and `checksums.txt`. Every asset pattern is therefore fully
anchored on both the platform slug and the archive extension — an unpinned
extension would resolve the `.deb` as a second candidate and fail with an
ambiguous-match error. Upstream's macOS slug is `mac`, not `darwin`.

Not declared, deliberately: `freebsd/*` (no such variant in ocx's
`OperatingSystem`), and the `armv5`/`armv6`/`armv7`/`ppc64le`/`riscv64`/`s390x`
assets (ocx's `Architecture` is amd64 + arm64 only). The Windows arm32 legs are
doubly excluded — upstream dropped them between v2.10.2 and v2.11.1.

## Editing

| File | Edit | Regenerate after |
|------|------|------------------|
| `mirror-base.yml`, `caddy/mirror.yml` | hand | yes — see below |
| `caddy/{metadata.json,CATALOG.md,logo.*}` | hand | — |
| `caddy/tests/smoke.star` | hand | — |
| `.github/workflows/*.yml` | **generated — never hand-edit** | re-run when a spec changes |

```bash
ocx-mirror package pipeline generate ci --spec caddy/mirror.yml
```

**Name every spec.** `--spec` *appends* rather than replaces, so a command
naming a subset silently stops rendering the rest while staying green — and the
drift guard reds on a generated workflow the current spec set no longer
produces.

`verify-generated.yml` exits 65 on drift. If a generated workflow is wrong, the
spec or the renderer template is wrong — fix it there and regenerate.

Run `direnv allow` once to put the pinned toolchain on `PATH`, and invoke
`ocx-mirror` directly — never `ocx run -- ocx-mirror`, which pins
`OCX_BINARY_PIN` to the bootstrap `ocx` and false-reds the nested push.

## The binaries claim

Upstream's archive is **flat**: `LICENSE`, `README.md` and `caddy`
(`caddy.exe` on Windows) all sit at depth 1 with no wrapper directory, on every
platform and at every in-range version. With `strip_components: 0` the
executable *is* at the content root and the bundle's only PATH entry is a bare
`${installPath}`. `bin_scan` only looks *below* an `${installPath}/<dir>` entry,
so `auto`/`verify` is rejected at spec load with exit 65. `mirror-base.yml`
therefore sets `bin_scan: off` and `caddy/metadata.json` hand-lists
`binaries: ["caddy"]`.

That hand list is load-bearing beyond documentation: `prepare` chmods only
**declared** binaries to 0755. And `strip_components: 1` on a flat archive
would not merely lose a wrapper — with every entry already at depth 1 there is
nothing to hoist, so it publishes an **empty** bundle on a fully green run.

## Smoke test

caddy is server-shaped, so `caddy run` and `caddy start` are off limits. The
smoke uses only offline verbs: a version *shape*, `build-info`'s embedded
`GOOS=`/`GOARCH=` compared against the platform the bundle was built for (the
one bug class the platform gate cannot see from inside), and `caddy adapt`
converting a hermetic Caddyfile to JSON with asserted handler *counts* — paired
with a malformed Caddyfile asserted non-zero, so a hypothetical passthrough
could not pass.

## Required secrets

| Secret | Use |
|--------|-----|
| `OCX_ANNOUNCE_TOKEN` | opens the index pull request from the `ocx-contrib/index` fork |
| `OCX_MIRROR_DISCORD_HOOK` | notify-stage Discord webhook URL |

(Inherited from the `ocx-contrib` org with visibility ALL. GHCR pushes use the
run's own `GITHUB_TOKEN` — no registry secret needed.)

## License

Apache-2.0 — see [`LICENSE`](LICENSE). Upstream assets are out of scope; the
package's redistribution license is recorded in [`NOTICE.md`](NOTICE.md).
