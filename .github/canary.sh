#!/usr/bin/env bash
# Checks the live site: pages, key content, images and Whop checkout links. Exits 1 on any failure.
set -u
SITE=https://smoovemarketmastery.com
fail=0
bad(){ echo "FAIL: $1"; fail=1; }
# prints the HTTP status, or 000 when curl itself fails (DNS, timeout, TLS)
code(){ local c; c=$(curl -sL -o /dev/null -w '%{http_code}' -A 'Mozilla/5.0 smoove-canary' --max-time 20 "$1") || c=000; echo "${c: -3}"; }
ok(){ [ "$1" != 000 ] && [ "$1" -lt 400 ]; }

html=$(curl -sL --max-time 20 "$SITE/") || bad "home page did not load"
for s in 'MARKET MASTERY' 'id="pricing"' 'whop.com' '<footer'; do
  grep -q "$s" <<<"$html" || bad "home page is missing: $s"
done
for p in terms privacy cookies disclaimer earnings cftc affiliate accessibility; do
  c=$(code "$SITE/$p.html"); [ "$c" = 200 ] || bad "$p.html returned $c"
done
for u in $(grep -oE '(src|href)="images/[^"]+"' <<<"$html" | cut -d'"' -f2 | sort -u) images/social-preview.jpg; do
  c=$(code "$SITE/$u"); [ "$c" = 200 ] || bad "$u returned $c"
done
links=$(grep -oE "https://whop\.com/[^\"' )]+" <<<"$html" | sort -u)
[ -n "$links" ] || bad "no Whop checkout links found on the home page"
for u in $links; do
  c=$(code "$u"); ok "$c" || bad "checkout link $u returned $c"
done
[ $fail = 0 ] && echo "All checks passed ($(wc -w <<<"$links") checkout links)."
exit $fail
