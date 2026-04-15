# Dashboard Performance Findings

## Scope

Date captured: `2026-04-12`

Compared implementations:

- baseline Inertia plus Webpack from the `gumroad-rsc-baseline` worktree
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

| Metric                           | Baseline Webpack |  Current Rspack |    Delta |
| -------------------------------- | ---------------: | --------------: | -------: |
| Cold production build            |         `25.19s` |        `11.25s` | `-55.3%` |
| Cold development build           |         `16.24s` |         `5.28s` | `-67.5%` |
| Built `inertia` entrypoint bytes |        `763,454` |       `803,865` |  `+5.3%` |
| Dashboard navigation duration    |       `475.33ms` |      `483.30ms` |  `+1.7%` |
| Dashboard response end           |       `358.23ms` |      `338.00ms` |  `-5.7%` |
| Dashboard LCP                    |       `497.33ms` |      `509.33ms` |  `+2.4%` |
| Dashboard packs transfer         |  `250,170` bytes | `349,054` bytes | `+39.5%` |
| Dashboard JS request count       |              `9` |            `11` | `+22.2%` |
| Largest dashboard JS chunk       |  `160,657` bytes | `263,358` bytes | `+63.9%` |

Artifacts:

- [baseline screenshot](../output/playwright/dashboard-perf/baseline-webpack-dashboard.png)
- [current screenshot](../output/playwright/dashboard-perf/current-rspack-dashboard.png)
- [baseline metrics JSON](../output/playwright/dashboard-perf/baseline-webpack-dashboard-metrics.json)
- [current metrics JSON](../output/playwright/dashboard-perf/current-rspack-dashboard-metrics.json)

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

| Metric              | Current Rspack Dashboard | First RSC Demo |    Delta |
| ------------------- | -----------------------: | -------------: | -------: |
| Navigation duration |               `483.30ms` |     `550.73ms` | `+14.0%` |
| Response end        |               `338.00ms` |     `486.43ms` | `+43.9%` |
| LCP                 |               `509.33ms` |     `573.33ms` | `+12.6%` |
| JS transfer         |          `349,054` bytes | `37,377` bytes | `-89.3%` |
| JS request count    |                     `11` |            `3` | `-72.7%` |

Artifacts:

- [isolated RSC metrics JSON](../output/playwright/dashboard-perf/rsc-isolated-3-dashboard-rsc-demo-metrics.json)
- [dashboard asset comparison JSON](../output/playwright/dashboard-perf/dashboard-vs-rsc-asset-comparison.json)

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

- [Inertia control metrics JSON](../output/playwright/dashboard-perf/inertia-demo-control-warm-trimmed-3-dashboard-inertia-demo-metrics.json)
- [RSC matched metrics JSON](../output/playwright/dashboard-perf/rsc-demo-warm-trimmed-3-dashboard-rsc-demo-metrics.json)
- [warmed matched comparison JSON](../output/playwright/dashboard-perf/warmed-matched-inertia-vs-rsc-comparison.json)

### Browser metrics

| Metric                 |   Inertia demo |       RSC demo |    Delta |
| ---------------------- | -------------: | -------------: | -------: |
| Navigation duration    |     `492.03ms` |     `429.90ms` | `-12.6%` |
| Response end           |     `344.90ms` |     `371.20ms` |  `+7.6%` |
| LCP                    |     `496.00ms` |     `452.00ms` |  `-8.9%` |
| HTML response transfer | `14,401` bytes | `15,444` bytes |  `+7.2%` |
| JS request count       |            `5` |            `1` | `-80.0%` |

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

## Server-Timing Follow-up

Date captured: `2026-04-14`

What changed in this pass:

- added route-scoped `Server-Timing` to both `/dashboard/inertia_demo` and `/dashboard/rsc_demo`
- updated the benchmark harness to record those timings in the JSON summaries
- re-ran the demo pair on a dedicated local renderer port after finding that port `3800` was occupied by an unrelated renderer process

Important caveat:

- the first 3-run Inertia batch was captured before the RSC batch
- rerunning the Inertia control after the RSC batch improved the control by about `9-10%`
- that means cache order matters enough that the stricter comparison is the **post-RSC Inertia rerun** against the RSC batch

Artifacts:

- [instrumented Inertia first-pass JSON](../output/playwright/dashboard-perf/inertia-demo-server-timing-3-dashboard-inertia-demo-metrics.json)
- [instrumented Inertia post-RSC JSON](../output/playwright/dashboard-perf/inertia-demo-server-timing-3-post-rsc-dashboard-inertia-demo-metrics.json)
- [instrumented RSC JSON](../output/playwright/dashboard-perf/rsc-demo-server-timing-3-dashboard-rsc-demo-metrics.json)

### Browser metrics against the warmer control

| Metric                 |   Inertia demo |       RSC demo |    Delta |
| ---------------------- | -------------: | -------------: | -------: |
| Navigation duration    |     `585.03ms` |     `461.97ms` | `-21.0%` |
| Response end           |     `433.43ms` |     `396.50ms` |  `-8.5%` |
| LCP                    |     `610.67ms` |     `484.00ms` | `-20.7%` |
| HTML response transfer | `14,244` bytes | `15,265` bytes |  `+7.2%` |
| JS request count       |            `6` |            `1` | `-83.3%` |

### Route-scoped server metrics against the warmer control

| Metric                       | Inertia demo |   RSC demo |    Delta |
| ---------------------------- | -----------: | ---------: | -------: |
| Controller `action_total`    |   `253.73ms` | `229.94ms` |  `-9.4%` |
| Presenter `compare_props`    |   `225.14ms` | `194.60ms` | `-13.6%` |
| Presenter `compare_creator_home` | `206.88ms` | `181.21ms` | `-12.4%` |
| `sql.active_record`          |    `99.53ms` |  `84.58ms` | `-15.0%` |
| `render_dispatch`            |    `24.84ms` |  `23.30ms` |  `-6.2%` |

## Interpretation Of The Server-Timing Follow-up

This was an important intermediate result, but it should not be treated as the headline benchmark anymore.

- The earlier matched result already showed a user-visible win on navigation duration and `LCP`.
- The new instrumented pass showed that, on that local setup, the `RSC` route could also stay ahead on `responseEnd` against a more-warmed Inertia rerun.
- The route-scoped timings suggested the RSC route might also be doing less app-side work in the controller/presenter path on this reduced surface.
- The first Inertia batch overstated the gap because measurement order changed cache warmth, which is exactly why this follow-up is more credible than the raw first-pass numbers.

The right conclusion is not "RSC is now proven faster everywhere."

The right conclusion is:

- the current local evidence was strong enough to justify a stricter benchmark method
- the next step was to validate the result under balanced route ordering
- broader migration claims still needed a more disciplined comparison

## Alternating Comparison Follow-up

Date captured: `2026-04-14`

What changed in this pass:

- added `scripts/perf/compare_dashboard_routes.rb`
- rotated route order by cycle instead of running grouped batches
- used `4` cycles so each route ran first twice and second twice

Artifacts:

- [balanced alternating comparison JSON](../output/playwright/dashboard-perf/dashboard-demo-alternating-4-comparison.json)
- [balanced alternating run directory](../output/playwright/dashboard-perf/dashboard-demo-alternating-4-runs)

### Browser metrics under balanced route ordering

| Metric                 |   Inertia demo |       RSC demo |    Delta |
| ---------------------- | -------------: | -------------: | -------: |
| Navigation duration    |     `568.47ms` |     `501.53ms` | `-11.8%` |
| Response end           |     `423.23ms` |     `441.65ms` |  `+4.4%` |
| LCP                    |     `602.00ms` |     `525.00ms` | `-12.8%` |
| HTML response transfer | `14,240.5` bytes | `15,265.0` bytes | `+7.2%` |
| JS request count       |            `6` |            `1` | `-83.3%` |

### Route-scoped server metrics under balanced route ordering

| Metric                       | Inertia demo |   RSC demo |    Delta |
| ---------------------------- | -----------: | ---------: | -------: |
| Controller `action_total`    |   `250.50ms` | `278.32ms` | `+11.1%` |
| Presenter `compare_props`    |   `226.41ms` | `236.16ms` |  `+4.3%` |
| Presenter `compare_creator_home` | `209.89ms` | `220.35ms` |  `+5.0%` |
| `sql.active_record`          |   `120.42ms` | `120.99ms` |  `+0.5%` |
| `render_dispatch`            |    `20.57ms` |  `23.61ms` | `+14.8%` |

### Position sensitivity

The alternating runner also makes route-order sensitivity explicit:

- Inertia when first: navigation `545.10ms`, response end `395.00ms`
- Inertia when second: navigation `591.85ms`, response end `451.45ms`
- RSC when first: navigation `502.90ms`, response end `443.25ms`
- RSC when second: navigation `500.15ms`, response end `440.05ms`

That means the Inertia control is more sensitive to whether it goes first or second in the cycle, while the RSC route is comparatively stable.
But the aggregate result is still the one that matters, and the aggregate result keeps the user-visible win while preserving a modest server-side tradeoff.

## Interpretation Of The Alternating Follow-up

This is the benchmark result that should be used for review and positioning.

- The `RSC` route still wins on total navigation duration.
- The `RSC` route still wins on `LCP`.
- The `RSC` route no longer wins on `responseEnd` once route order is balanced.
- The route-scoped timings also stop supporting the stronger claim that the RSC route is currently cheaper server-side.

That gives us a cleaner, more defensible story:

- the user-visible win is still real
- the client-JS reduction is still dramatic
- the current server-side tradeoff is still real
- the benchmark method is now strong enough that reviewers can focus on product value instead of measurement discipline

## What This Means For Positioning

Today’s credible story is:

- `Shakapacker + Rspack` can deliver immediate build and dev-loop wins for a real Inertia app.
- `React 19 + Rspack` is technically viable here.
- `React on Rails Pro + RSC` now has matched-surface evidence of a user-visible win on a stricter alternating benchmark.

Today’s non-credible story is:

- "The full Gumroad dashboard is already faster under the current RSC work."
- "The server is universally faster with RSC."

The next demo only helps if the matched `React on Rails Pro + RSC` implementation continues to beat the matched Inertia control on metrics that matter:

- equal or better LCP
- equal or better total navigation duration
- ideally equal or better response end once the implementation is tuned further
- fewer client-side requests or bytes for the page
- with server-response costs that are understandable and defensible

If the RSC demo cannot keep that balance, then it should be positioned as a composition or product-shaping experiment, not a migration pitch.

## Recommended Next Step

Keep the branches and claims narrow:

1. Keep `jg-codex/react19-rspack` focused on bundler viability and build-speed wins.
2. Treat React 19 type cleanup as a separate stacked branch if needed.
3. Keep the matched `/dashboard/inertia_demo` and `/dashboard/rsc_demo` pair as the primary performance comparison surface.
4. Keep using the alternating comparison runner instead of grouped batches for future local claims.
5. Re-run the same comparison after fixing the local Chrome and chromedriver mismatch so the numbers are less noisy.
6. Repeat the instrumented comparison in a production-like renderer mode before broadening the pitch.
7. Do not file upstream issues or pitch upstream adoption on runtime-performance grounds until the matched comparison stays favorable after that cleanup.
