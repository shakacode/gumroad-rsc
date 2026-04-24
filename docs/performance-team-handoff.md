# RSC Performance Handoff

## What this is

This repo contains a constrained comparison between:

- `Inertia` control route: `/dashboard/inertia_demo`
- `React on Rails Pro + RSC` route: `/dashboard/rsc_demo`

Both routes use the same reduced creator-home presenter surface and the same outer `inertia` layout.

The goal is not to prove that "RSC is always faster."
The goal is to measure whether a bounded RSC surface can produce a meaningful user-visible win that justifies the added complexity.

## Shareable references

- repo: [shakacode/react-on-rails-demo-gumroad-rsc](https://github.com/shakacode/react-on-rails-demo-gumroad-rsc)
- consolidated demo PR: [react-on-rails-demo-gumroad-rsc#11](https://github.com/shakacode/react-on-rails-demo-gumroad-rsc/pull/11)
- follow-up PR: [react-on-rails-demo-gumroad-rsc#10](https://github.com/shakacode/react-on-rails-demo-gumroad-rsc/pull/10)
- React on Rails hub issue: [react_on_rails#3128](https://github.com/shakacode/react_on_rails/issues/3128)
- benchmark and positioning issue: [react_on_rails#3144](https://github.com/shakacode/react_on_rails/issues/3144)

## Current conclusion

The current RSC implementation is **promising but not fully optimized**.

What is already true:

- the RSC route wins on total navigation duration
- the RSC route wins on `LCP`
- the corrected clean-port alternating local benchmark still has the RSC route ahead on total navigation duration and `LCP`
- the RSC route reduces page-specific JS requests from `6` to `1` in the latest balanced pass
- the demo JS and CSS are route-scoped, so unrelated pages are not paying for the experiment
- the raw RSC HTML transfer is now close to the Inertia control after the response-end pass

What is not yet proven:

- the strongest result is still a local-development measurement
- one earlier headline run used a mismatched local Chrome and chromedriver pair, and the later matched-driver repeat exposed a development-asset outlier on one RSC run
- measurement order affects cache state enough that grouped batches can overstate the gap
- the corrected alternating run still shows a modest server-side tradeoff for the RSC route

## Latest balanced alternating local result

Measured with:

- one explicit server warmup request
- local Docker-backed services
- local logged-in seller
- standalone React on Rails Pro Node renderer running on a dedicated port for this pass
- Rails and `bin/shakapacker-dev-server` both restarted with `SHAKAPACKER_DEV_SERVER_PORT=3036` after discovering another repo had reclaimed the default `3035` port
- manual browser verification of both demo routes after the clean-port restart
- matching `Chrome 147` and `ChromeDriver 147`

### Browser metrics

This is the stricter comparison to use from this pass:

- `scripts/perf/compare_dashboard_routes.rb`
- `8` cycles with route order rotated each cycle: `AB`, `BA`, `AB`, `BA`, `AB`, `BA`, `AB`, `BA`
- one explicit warmup request per measured run

| Metric                 |      Inertia demo |         RSC demo |    Delta |
| ---------------------- | ----------------: | ---------------: | -------: |
| Navigation duration    |        `457.16ms` |       `402.29ms` | `-12.0%` |
| Response end           |        `320.70ms` |       `335.96ms` |  `+4.8%` |
| LCP                    |        `501.00ms` |       `421.00ms` | `-16.0%` |
| HTML response transfer | `14,332.38` bytes | `15,265.0` bytes |  `+6.5%` |
| JS request count       |               `6` |              `1` | `-83.3%` |

### Route-scoped server timings

| Metric                           | Inertia demo |   RSC demo |    Delta |
| -------------------------------- | -----------: | ---------: | -------: |
| Controller `action_total`        |   `163.10ms` | `169.74ms` |  `+4.1%` |
| Presenter `compare_props`        |   `144.80ms` | `145.49ms` |  `+0.5%` |
| Presenter `compare_creator_home` |   `134.52ms` | `136.14ms` |  `+1.2%` |
| `sql.active_record`              |    `76.67ms` |  `77.10ms` |  `+0.6%` |
| `render_dispatch`                |    `15.76ms` |  `18.63ms` | `+18.2%` |

### Position sensitivity

The alternating run also captures how much each route changes based on whether it runs first or second in the cycle:

- Inertia when first: navigation `486.62ms`
- Inertia when second: navigation `427.70ms`
- RSC when first: navigation `420.25ms`
- RSC when second: navigation `384.33ms`

That makes two things clearer:

- route order mattered enough to invalidate grouped-batch claims as the headline benchmark method
- the route split is still sensitive to execution order, but the balanced aggregate now leaves only a modest server-side gap in Inertia's favor while keeping a strong user-visible RSC win

### Corrected local setup note

This headline run is stronger than the earlier local headline because it fixed a real environment problem first.

- another local repo had reclaimed port `3035` with a plain-HTTP webpack dev server
- Rails was proxying `https://app.gumroad.dev/packs/...` requests to that wrong process, which broke browser verification
- after adding JS-side `SHAKAPACKER_DEV_SERVER_*` override support, restarting both Rails and the dev server on `3036`, and manually rechecking both pages, the balanced comparison still favored the RSC route on user-visible metrics

### Raw response reduction achieved earlier in the pass

The response-end pass reduced the RSC route from roughly:

- raw response: `36.9KB` -> `15.1KB`
- inline RSC script: `25.4KB` -> `8.9KB`

That means the current user-visible advantage is not coming from a smaller HTML transfer alone.
It also means the current server-side tradeoff is not explained by response size alone, because the HTML transfer is already close while `responseEnd` and `action_total` remain slightly worse under the balanced method.

## Matched-driver repeat

A later `8`-cycle repeat used a matching `Chrome 147` and `ChromeDriver 147` pair and recovered the final comparison JSON from the completed per-run files.

The useful part of that rerun:

- median navigation duration still favored RSC: `544.80ms` vs `396.65ms`
- median `responseEnd` slightly favored RSC: `385.55ms` vs `375.75ms`
- median `LCP` still favored RSC: `568.00ms` vs `426.00ms`

The reason it is not the headline benchmark:

- one RSC run reported a cached `dashboard_rsc_demo_styles.css` duration of about `19.3s` with `0` transfer bytes
- that left `responseEnd` normal but poisoned mean `navigation` and `LCP`
- the dev-asset outlier makes the repeat useful as a diagnostic and discipline check, not as the clean headline result
- it predates the corrected clean-port local rerun above, so it is better treated as an outlier-detection artifact than as the current summary benchmark

## How optimized is the current RSC implementation?

Short answer:

- it is **moderately optimized for a fair comparison**
- it is **not fully optimized for maximum RSC advantage**

What is already optimized:

- comparison surface is reduced to read-heavy creator-home content
- same presenter-backed data shape is used for both routes
- the RSC route was stripped of wrapper-heavy UI components and icon-heavy server output
- empty demo props are omitted
- the dedicated RSC/server bundles are built separately from the main Inertia pack
- CSP and nonce handling are wired correctly for streamed inline payloads

What is not yet heavily leveraged:

- nested async server-component trees
- aggressive Suspense segmentation for meaningful partial streaming
- deeper per-section server data fetching co-located with server components
- production-mode renderer tuning and production-like profiling
- targeted renderer instrumentation inside the React on Rails Pro streaming path

## Are we heavily leveraging RSC?

No, not yet.

This is a **conservative RSC proof-of-value pass**, not a maximal RSC architecture.

Today the implementation mostly proves:

- you can move a read-heavy slice out of a large client-rendered Inertia payload
- you can reduce page-specific client JS materially
- you can win on user-visible metrics on a bounded surface
- you can now inspect route-scoped server work and position sensitivity instead of arguing only from grouped browser batches

It does **not** yet prove the full upside of RSC as an architecture.

## Highest-value next optimization targets

If the performance team wants the next round to be high signal, focus here:

1. Re-run the comparison in a production-like mode with a dedicated renderer and a fixed Chrome/chromedriver pair.
   The latest result is strong, but it is still local-development and sensitive to dev-asset timing noise.

2. Instrument the React on Rails Pro renderer and streaming path.
   We now have route-scoped Rails timing, but not renderer-internal timing.

3. Test whether finer-grained Suspense boundaries improve time-to-first-meaningful HTML without regressing final paint.

4. Move more section-level composition into server components instead of one relatively coarse route-level tree.

5. Measure Node renderer overhead separately from React render time and Rails template/render overhead.

## Documentation entry points

Start here:

- [current-status.md](./current-status.md)
- [performance-findings.md](./performance-findings.md)
- [rsc-benchmark-plan.md](./rsc-benchmark-plan.md)
- [rsc-comparison-plan.md](./rsc-comparison-plan.md)
- [dashboard-experiment-brief.md](./dashboard-experiment-brief.md)
- [positioning-notes.md](./positioning-notes.md)

## CI validation status

This repo now has a GitHub-hosted demo validation path aimed specifically at the public experiment workflow.

That validation covers:

- the `Rspack`-backed Shakapacker development build
- the standalone `npm run build:rsc-demo` bundle path
- the targeted dashboard demo controller specs
- a headless browser smoke spec that visits both `/dashboard/inertia_demo` and `/dashboard/rsc_demo`
- the React on Rails Pro Node renderer boot path needed for the RSC route

The heavier internal Gumroad matrix still exists for the original codebase shape, but this public repo now has a reviewable CI path that does not depend on the private `ubicloud` runner pool.

## Key artifacts

- matched comparison JSON: `output/playwright/dashboard-perf/warmed-matched-inertia-vs-rsc-comparison.json`
- Inertia metrics JSON: `output/playwright/dashboard-perf/inertia-demo-control-warm-trimmed-3-dashboard-inertia-demo-metrics.json`
- RSC metrics JSON: `output/playwright/dashboard-perf/rsc-demo-warm-trimmed-3-dashboard-rsc-demo-metrics.json`
- balanced alternating comparison JSON: `output/playwright/dashboard-perf/dashboard-demo-alternating-4-comparison.json`
- corrected clean-port alternating comparison JSON: `output/playwright/dashboard-perf/dashboard-demo-alternating-4-clean-driver-port-3036-matched-driver-comparison.json`
- corrected clean-port `8`-cycle comparison JSON: `output/playwright/dashboard-perf/dashboard-demo-alternating-8-clean-driver-port-3036-matched-driver-comparison.json`
- instrumented Inertia rerun JSON: `output/playwright/dashboard-perf/inertia-demo-server-timing-3-post-rsc-dashboard-inertia-demo-metrics.json`
- instrumented RSC JSON: `output/playwright/dashboard-perf/rsc-demo-server-timing-3-dashboard-rsc-demo-metrics.json`
- clean-driver repeat comparison JSON: `output/playwright/dashboard-perf/dashboard-demo-alternating-8-clean-driver-comparison.json`

## Current sharing status

The repo is public, the consolidated demo PR is open, and the React on Rails issues are available as team-facing discussion hubs.

The earlier stacked PRs were closed unmerged after consolidation into [#11](https://github.com/shakacode/react-on-rails-demo-gumroad-rsc/pull/11). Treat [#11](https://github.com/shakacode/react-on-rails-demo-gumroad-rsc/pull/11) as the parent review branch and [#10](https://github.com/shakacode/react-on-rails-demo-gumroad-rsc/pull/10) as its current child follow-up.

The artifact paths listed above are local benchmark outputs, so they are shareable through a repo checkout and branch work, but not through GitHub artifact hosting.
The measurement script also now records browser/version provenance and percentile-style summary stats in those JSON outputs so the performance-team handoff is less dependent on ad hoc environment notes.
The alternating comparison JSON now also includes average, median, and `p95` primary-metric deltas plus per-path slowest pack resources, so outliers like the `19.3s` cached CSS load are visible without opening every per-run file.
The earlier 3-run grouped batches are still useful diagnostic artifacts, but the alternating comparison above is the benchmark result that should be circulated because it explicitly balances route order.
