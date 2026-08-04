# NOTICE

This repository packages and redistributes upstream software published by the
[caddyserver](https://github.com/caddyserver) organisation. The Apache-2.0
license in [`LICENSE`](LICENSE) covers the OCX pipeline files authored here. It
does **not** cover any upstream-derived asset — each package's redistributed
bytes carry their own license, recorded below.

Each package's logo is reproduced for catalog identification only, under
nominative fair use. The marks remain the property of their respective owners
and no endorsement is implied.

| Package | GHCR path | Upstream SPDX |
|---|---|---|
| `caddy` | `ghcr.io/ocx-contrib/caddyserver/caddy` | `Apache-2.0` |

---

## `caddy`

Upstream: <https://github.com/caddyserver/caddy>
Published to `ghcr.io/ocx-contrib/caddyserver/caddy`.

| Component | SPDX | Holder |
|---|---|---|
| Caddy (`caddy`) | **Apache-2.0** | Copyright 2015 Matthew Holt and The Caddy Authors |

Permissive. Apache-2.0 §4 grants redistribution of the object form provided
recipients receive a copy of the license and any NOTICE that travels with the
work. The terms are those of
<https://github.com/caddyserver/caddy/blob/master/LICENSE>, verified via
`gh api repos/caddyserver/caddy/license` → `Apache-2.0`.

Upstream's release archive for every platform contains the full `LICENSE` text
alongside the `caddy` executable, and `strip_components: 0` keeps it in the
published bundle — so the Apache-2.0 copy required by §4(a) reaches every
consumer with the bytes it covers, and this file is the record rather than the
sole delivery mechanism.

The `caddy` binary statically links a large set of third-party Go modules
(including CertMagic, ACMEz, quic-go and the Go standard library) under
permissive licenses — MIT, Apache-2.0, BSD-3-Clause; the full set is enumerated
in upstream's `go.mod`/`go.sum` and in the per-asset SBOM upstream publishes
beside each release archive. Caddy's own `LICENSE` covers the combined work as
distributed by upstream.

"Caddy" and the Caddy logo are trademarks of Stack Holdings GmbH, used here for
catalog identification under nominative fair use. `caddy/logo.png` is
upstream's own 512px square mark, taken byte-for-byte from
`src/resources/images/icon-transparent.png` in
<https://github.com/caddyserver/website>; `caddy/logo.svg` wraps that same PNG
so a vector-only consumer still resolves it. Neither the Caddy project nor
Stack Holdings GmbH endorses this mirror.

This mirror carries only the per-platform `caddy_<version>_<os>_<arch>` release
archives. The sibling `.deb` packages, the release-wide
`buildable-artifact.tar.gz` and `src.tar.gz`, and the `.pem`/`.sig`/`.sbom`
signature and SBOM sidecars are not redistributed here.

No modifications are made to any upstream artifact in this repository; they are
republished byte-for-byte inside an OCX bundle.
