# caddy/tests/smoke.star — asserts the contract, never prose. Stable across
# upstream caddy releases: a version SHAPE, the platform the artifact was
# actually built for, and a real config transformation with a negative control.
# No help text, no banner, nothing upstream may reword.
#
# ⚠️ caddy is SERVER-SHAPED. `caddy run` blocks indefinitely and `caddy start`
# forks a daemon and binds ports — neither belongs in a smoke test. Every verb
# below was picked off `caddy help`'s command list as fully offline: `version`,
# `build-info` and `adapt` (Caddyfile → JSON) touch no socket, no admin
# endpoint and no certificate authority. Verified identical at BOTH ends of the
# declared range, v2.9.0 and v2.11.4.

CADDY = "caddy.exe" if ocx.target_platform.os == ocx.os.Windows else "caddy"

# HOME pinned to the sandbox. MEASURED, not assumed: with HOME unset in a bare
# `ubuntu:24.04`, caddy still exits 0 but logs
#   "unable to determine directory for user configuration; falling back to
#    current directory … neither $XDG_CONFIG_HOME nor $HOME are defined"
# — so the dependence is real but soft. Pinning it keeps the test off the
# runner's real home and silences that path entirely; HOME alone is enough
# (the message names XDG_CONFIG_HOME as the *alternative*, not an addition).
# USERPROFILE is the Windows spelling, kept here so one dict serves all six
# platforms.
#
# NO_COLOR is deliberately NOT set: `strings -a caddy | grep -x NO_COLOR`
# returns nothing at any in-range version, and the only surface asserted below
# is `adapt`'s stdout, which is raw JSON with zero ESC bytes (`od -c | grep 033`
# → 0). Setting it would be cargo cult.
ENV = {
    "HOME": ocx.scratch_root,
    "USERPROFILE": ocx.scratch_root,
}

# Tier 1 + 2: liveness on the composed PATH + version SHAPE. `caddy version`
# prints `v2.11.4 h1:XKxk…=` — the digits are asserted, the Go module hash and
# the wordmark are not.
r_version = ocx.run(CADDY, "version", env = ENV)
expect.ok(r_version)
expect.matches(r_version.stdout, r"^v\d+\.\d+\.\d+")

# Platform identity — the one bug class the pipeline's platform gate cannot see
# from inside. A wrong asset regex ships, say, the mac_amd64 tarball into the
# linux/amd64 bundle and every other assertion here would still pass on the
# host that can run it. caddy is Go, so `build-info` prints the compiler's own
# `GOOS=`/`GOARCH=` build settings, and Go's spellings are the OCI ones
# (linux/darwin/windows, amd64/arm64) — so this compares the artifact's
# embedded identity against the platform ocx built the bundle FOR.
r_build = ocx.run(CADDY, "build-info", env = ENV)
expect.ok(r_build)
expect.contains(r_build.stdout, "GOOS=" + str(ocx.target_platform.os))
expect.contains(r_build.stdout, "GOARCH=" + str(ocx.target_platform.arch))

# Tier 3: a real, hermetic transformation. `caddy adapt` runs the Caddyfile
# parser and the JSON encoder end to end — it is not a passthrough: the input
# is Caddyfile syntax and every token asserted below exists only in the JSON
# output. `admin off` + `auto_https off` keep it from touching the admin socket
# or an ACME directory even in principle. Byte-identical output measured at
# v2.9.0 and v2.11.4 (443 bytes both).
ocx.write_file("Caddyfile", "\n".join([
    "{",
    "  admin off",
    "  auto_https off",
    "}",
    "",
    "http://localhost:8080 {",
    "  respond /ocxsmoke \"OCXSMOKE-OK\" 200",
    "  respond \"fallback\" 404",
    "}",
    "",
]))

r_adapt = ocx.run(CADDY, "adapt", "--config", "Caddyfile", "--adapter", "caddyfile", env = ENV)
expect.ok(r_adapt)
# Counts, not mere presence: two `respond` directives must become exactly two
# static_response handlers, and the body must survive verbatim exactly once.
expect.eq(r_adapt.stdout.count("OCXSMOKE-OK"), 1)
expect.eq(r_adapt.stdout.count("\"handler\":\"static_response\""), 2)
# Structure the adapter computed, which appears nowhere in the input text.
expect.contains(r_adapt.stdout, "\"admin\":{\"disabled\":true}")
expect.contains(r_adapt.stdout, "\"listen\":[\":8080\"]")

# Negative control for the above. A tool that merely echoed its input would
# pass a naive "did it produce output" check; this proves the parser actually
# rejects. Measured exit 1 with empty stdout at both range ends. The code is
# POSITIVE, so it needs no unix-vs-Windows branch (a negative exit would be 255
# on unix and -1 on Windows).
ocx.write_file("bad.Caddyfile", "http://localhost:8080 {\n  respond /x \"unterminated\n")
r_bad = ocx.run(CADDY, "adapt", "--config", "bad.Caddyfile", "--adapter", "caddyfile", env = ENV)
expect.eq(r_bad.exit_code, 1)
expect.eq(r_bad.stdout.count("\"handler\":\"static_response\""), 0)
