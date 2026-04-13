# Dashboard Performance Findings

## Scope

Date captured: `2026-04-12`

Compared implementations:

- baseline Inertia plus Webpack from `/Users/justin/codex/gumroad-rsc-baseline`
- current Inertia plus Rspack plus React 19 from this repo on `jg-codex/react19-rspack`

Important framing:

- this comparison isolates the tooling branch, not the final runtime hypothesis
- `Rspack` was expected to improve build and dev-loop performance
- `React Server Components` are the part that may justify extra page-level complexity on runtime performance

Measured surface:

- route: `/dashboard`
- base URL: `https://gumroad.dev`
- user: `seller@gumroad.com`

Local setup notes:

- both measurements used the same Docker-backed local services and the same local database
- route-level dashboard measurements required local Elasticsearch indices for `product_page_views`, `purchases`, and `confirmed_follower_events`
- the dashboard harness authenticates over HTTP before loading the page in Chrome, so the measurement is not dependent on browser login behavior

## Bundler Baseline

| Metric | Baseline Webpack | Current Rspack | Delta |
| --- | ---: | ---: | ---: |
| Cold production build | `25.19s` | `11.25s` | `-55.3%` |
| Cold development build | `16.24s` | `5.28s` | `-67.5%` |
| Built `inertia` entrypoint bytes | `763,454` | `803,865` | `+5.3%` |
| Dashboard navigation duration | `475.33ms` | `483.30ms` | `+1.7%` |
| Dashboard response end | `358.23ms` | `338.00ms` | `-5.7%` |
| Dashboard LCP | `497.33ms` | `509.33ms` | `+2.4%` |
| Dashboard packs transfer | `250,170` bytes | `349,054` bytes | `+39.5%` |
| Dashboard JS request count | `9` | `11` | `+22.2%` |
| Largest dashboard JS chunk | `160,657` bytes | `263,358` bytes | `+63.9%` |

Artifacts:

- [baseline screenshot](/Users/justin/codex/gumroad-rsc/output/playwright/dashboard-perf/baseline-webpack-dashboard.png)
- [current screenshot](/Users/justin/codex/gumroad-rsc/output/playwright/dashboard-perf/current-rspack-dashboard.png)
- [baseline metrics JSON](/Users/justin/codex/gumroad-rsc/output/playwright/dashboard-perf/baseline-webpack-dashboard-metrics.json)
- [current metrics JSON](/Users/justin/codex/gumroad-rsc/output/playwright/dashboard-perf/current-rspack-dashboard-metrics.json)

## Interpretation Of The Bundler Branch

The developer-experience win is real.

- Rspack is dramatically faster for cold builds in both development and production.
- That is already a legitimate Shakapacker positioning point for Inertia apps.

The runtime win remained unproven on the full dashboard.

- The dashboard route was not materially faster under the Rspack branch.
- That was expected, because the architecture was still the same Inertia page.

## First Isolated RSC Pass

Date captured: `2026-04-12`

Compared implementations:

- current Inertia plus Rspack dashboard baseline from this repo
- first isolated React on Rails Pro plus RSC demo at `/dashboard/rsc_demo`

Important caveats:

- the `RSC` demo numbers below are from an earlier isolated 3-run average
- the current `/dashboard` route became too noisy in the same browser harness after the demo landed
- this comparison proved technical feasibility, but it was not the cleanest control surface

### Browser metrics

| Metric | Current Rspack Dashboard | First RSC Demo | Delta |
| --- | ---: | ---: | ---: |
| Navigation duration | `483.30ms` | `550.73ms` | `+14.0%` |
| Response end | `338.00ms` | `486.43ms` | `+43.9%` |
| LCP | `509.33ms` | `573.33ms` | `+12.6%` |
| JS transfer | `349,054` bytes | `37,377` bytes | `-89.3%` |
| JS request count | `11` | `3` | `-72.7%` |

Artifacts:

- [isolated RSC metrics JSON](/Users/justin/codex/gumroad-rsc/output/playwright/dashboard-perf/rsc-isolated-3-dashboard-rsc-demo-metrics.json)
- [dashboard asset comparison JSON](/Users/justin/codex/gumroad-rsc/output/playwright/dashboard-perf/dashboard-vs-rsc-asset-comparison.json)

## Interpretation Of The First RSC Pass

That first pass proved something important, but not yet the thing we needed most.

- It proved that we can build a bounded React on Rails Pro plus RSC surface against real Gumroad data.
- It proved that the isolated route can cut shipped client-side JavaScript very aggressively.
- It did not prove a page-performance win.

The next step had to be a cleaner control surface.

## Matched Inertia Vs RSC Demo

Date captured: `2026-04-12`

Compared implementations:

- warmed matched Inertia control at `/dashboard/inertia_demo`
- warmed matched React on Rails Pro plus RSC demo at `/dashboard/rsc_demo`

Why this comparison matters more:

- both routes render the same reduced creator-home slice
- both routes use the same presenter-backed seller data
- both routes now share the same outer `inertia` layout
- this isolates architecture more cleanly than comparing the RSC demo against the full dashboard

Artifacts:

- [Inertia control metrics JSON](/Users/justin/codex/gumroad-rsc/output/playwright/dashboard-perf/inertia-demo-control-warm-trimmed-3-dashboard-inertia-demo-metrics.json)
- [RSC matched metrics JSON](/Users/justin/codex/gumroad-rsc/output/playwright/dashboard-perf/rsc-demo-warm-trimmed-3-dashboard-rsc-demo-metrics.json)
- [warmed matched comparison JSON](/Users/justin/codex/gumroad-rsc/output/playwright/dashboard-perf/warmed-matched-inertia-vs-rsc-comparison.json)

### Browser metrics

| Metric | Inertia demo | RSC demo | Delta |
| --- | ---: | ---: | ---: |
| Navigation duration | `492.03ms` | `429.90ms` | `-12.6%` |
| Response end | `344.90ms` | `371.20ms` | `+7.6%` |
| LCP | `496.00ms` | `452.00ms` | `-8.9%` |
| HTML response transfer | `14,401` bytes | `15,444` bytes | `+7.2%` |
| JS request count | `5` | `1` | `-80.0%` |

Additional context:

- the Inertia control still ships a `data-page` blob of about `5,789` bytes
- the RSC demo removes that Inertia payload entirely on this route
- these warmed runs were captured with one explicit server warmup request and the standalone Node Renderer process running via `bin/dev`
- the final RSC sample also uses the same outer `inertia` layout as the control route, so the remaining delta is less likely to be a layout artifact
- the response-end pass reduced the raw RSC response from about `36.9KB` to about `15.1KB` and the inline RSC script from about `25.4KB` to about `8.9KB`
- the browser-side `htmlBytes` snapshot is dramatically smaller for the RSC route after load, but that number reflects post-render DOM state rather than raw network response size, so it is useful context rather than the primary claim

## Interpretation Of The Matched Demo

This is the first evidence that supports a real performance positioning story.

- The `RSC` route is still slower to finish the initial HTML response.
- Even with that server-response cost, the warmed matched `RSC` demo is faster on total navigation duration.
- More importantly, the warmed matched `RSC` demo is also faster on `LCP`, which is the most relevant user-visible win we have measured so far.
- The remaining response-end gap stayed roughly the same even after most of the raw transfer gap disappeared, which points to renderer or streaming overhead rather than just HTML size.

That means the story is now more precise:

- `Rspack` is the build and dev-loop win.
- A carefully bounded `React on Rails Pro + RSC` surface can also produce a user-visible page-load win.
- The tradeoff is not free, because the server response is still modestly slower than the Inertia control even after the response payload was almost fully normalized.

This is promising, but it is still not enough for an upstream migration pitch by itself.

- The win exists on a reduced comparison surface, not on the full dashboard.
- The measurements are still local-development measurements, not production-like traces.
- The browser harness is currently using a mismatched local Chrome and chromedriver pair, which adds noise even though the matched 3-run averages were stable enough to use.

## What This Means For Positioning

Today’s credible story is:

- `Shakapacker + Rspack` can deliver immediate build and dev-loop wins for a real Inertia app.
- `React 19 + Rspack` is technically viable here.
- `React on Rails Pro + RSC` now has early matched-surface evidence of a user-visible win on `LCP` and total navigation time.

Today’s non-credible story is:

- "The full Gumroad dashboard is already faster under the current RSC work."
- "The server is universally faster with RSC."

The next demo only helps if the matched `React on Rails Pro + RSC` implementation continues to beat the matched Inertia control on metrics that matter:

- equal or better LCP
- equal or better total navigation duration
- fewer client-side requests or bytes for the page
- with server-response costs that are understandable and defensible

If the RSC demo cannot keep that balance, then it should be positioned as a composition or product-shaping experiment, not a migration pitch.

## Recommended Next Step

Keep the branches and claims narrow:

1. Keep `jg-codex/react19-rspack` focused on bundler viability and build-speed wins.
2. Treat React 19 type cleanup as a separate stacked branch if needed.
3. Keep the matched `/dashboard/inertia_demo` and `/dashboard/rsc_demo` pair as the primary performance comparison surface.
4. Optimize the RSC route specifically on server response cost and renderer overhead without giving back the LCP win.
5. Re-run the same comparison after fixing the local Chrome and chromedriver mismatch so the numbers are less noisy.
6. Do not file upstream issues or pitch upstream adoption on runtime-performance grounds until the matched comparison stays favorable after that cleanup.
