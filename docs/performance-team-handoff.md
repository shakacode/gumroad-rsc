# RSC Performance Handoff

## What this is

This repo contains a constrained comparison between:

- `Inertia` control route: `/dashboard/inertia_demo`
- `React on Rails Pro + RSC` route: `/dashboard/rsc_demo`

Both routes use the same reduced creator-home presenter surface and the same outer `inertia` layout.

The goal is not to prove that "RSC is always faster."
The goal is to measure whether a bounded RSC surface can produce a meaningful user-visible win that justifies the added complexity.

## Shareable references

- repo: [shakacode/gumroad-rsc](https://github.com/shakacode/gumroad-rsc)
- stacked PR 1: [baseline dashboard docs](https://github.com/shakacode/gumroad-rsc/pull/1)
- stacked PR 2: [React 19 + Shakapacker 10 + Rspack](https://github.com/shakacode/gumroad-rsc/pull/2)
- stacked PR 3: [React on Rails Pro + RSC demo](https://github.com/shakacode/gumroad-rsc/pull/3)
- React on Rails issue: [react_on_rails#3128](https://github.com/shakacode/react_on_rails/issues/3128)

## Current conclusion

The current RSC implementation is **promising but not fully optimized**.

What is already true:

- the RSC route wins on total navigation duration
- the RSC route wins on `LCP`
- the latest instrumented local pass also has the RSC route ahead on `responseEnd`
- the RSC route reduces page-specific JS requests from `6` to `1` in the latest instrumented local pass
- the demo JS and CSS are route-scoped, so unrelated pages are not paying for the experiment
- the raw RSC HTML transfer is now close to the Inertia control after the response-end pass
- route-scoped `Server-Timing` now shows the RSC route doing less controller, presenter, and SQL work on this reduced surface

What is not yet proven:

- the strongest result is still a local-development measurement
- the benchmark harness is still using a mismatched local Chrome and chromedriver pair
- measurement order affects cache state, so single batch results can overstate the gap

## Latest instrumented local result

Measured with:

- one explicit server warmup request
- local Docker-backed services
- local logged-in seller
- standalone React on Rails Pro Node renderer running on a dedicated port for this pass

### Browser metrics

This is the stricter comparison to use from this pass:

- RSC 3-run batch
- compared against an Inertia rerun captured **after** the RSC batch, so the control had the benefit of the warmer cache state

| Metric                 |   Inertia demo |       RSC demo |    Delta |
| ---------------------- | -------------: | -------------: | -------: |
| Navigation duration    |     `585.03ms` |     `461.97ms` | `-21.0%` |
| Response end           |     `433.43ms` |     `396.50ms` |  `-8.5%` |
| LCP                    |     `610.67ms` |     `484.00ms` | `-20.7%` |
| HTML response transfer | `14,244` bytes | `15,265` bytes |  `+7.2%` |
| JS request count       |            `6` |            `1` | `-83.3%` |

### Route-scoped server timings

| Metric                  | Inertia demo |   RSC demo |    Delta |
| ----------------------- | -----------: | ---------: | -------: |
| Controller `action_total` |   `253.73ms` | `229.94ms` |  `-9.4%` |
| Presenter `compare_props` |   `225.14ms` | `194.60ms` | `-13.6%` |
| Presenter `compare_creator_home` | `206.88ms` | `181.21ms` | `-12.4%` |
| `sql.active_record`     |    `99.53ms` |  `84.58ms` | `-15.0%` |
| `render_dispatch`       |    `24.84ms` |  `23.30ms` |  `-6.2%` |

### Raw response reduction achieved earlier in the pass

The response-end pass reduced the RSC route from roughly:

- raw response: `36.9KB` -> `15.1KB`
- inline RSC script: `25.4KB` -> `8.9KB`

That means the current local advantage is not coming from a smaller HTML transfer alone.
The new `Server-Timing` data points to lower controller and presenter work on the RSC route as well.

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
- you can now inspect route-scoped server work instead of arguing only from browser timings

It does **not** yet prove the full upside of RSC as an architecture.

## Highest-value next optimization targets

If the performance team wants the next round to be high signal, focus here:

1. Re-run the comparison in a production-like mode with a dedicated renderer and a fixed Chrome/chromedriver pair.
   The latest result is strong, but it is still local-development and cache-order sensitive.

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

- [matched comparison JSON](../output/playwright/dashboard-perf/warmed-matched-inertia-vs-rsc-comparison.json)
- [Inertia metrics JSON](../output/playwright/dashboard-perf/inertia-demo-control-warm-trimmed-3-dashboard-inertia-demo-metrics.json)
- [RSC metrics JSON](../output/playwright/dashboard-perf/rsc-demo-warm-trimmed-3-dashboard-rsc-demo-metrics.json)
- [Instrumented Inertia rerun JSON](../output/playwright/dashboard-perf/inertia-demo-server-timing-3-post-rsc-dashboard-inertia-demo-metrics.json)
- [Instrumented RSC JSON](../output/playwright/dashboard-perf/rsc-demo-server-timing-3-dashboard-rsc-demo-metrics.json)

## Current sharing status

The repo is public, the stacked PRs are open, and the React on Rails issue is available as the team-facing discussion hub.

The JSON artifacts linked above are local benchmark outputs, so they are shareable through the repo checkout and branch work, but not through GitHub artifact hosting.
The measurement script also now records browser/version provenance and percentile-style summary stats in those JSON outputs so the performance-team handoff is less dependent on ad hoc environment notes.
A first instrumented Inertia batch captured before the RSC batch was about `9-10%` slower than the Inertia rerun listed above, which is why the stricter comparison in this doc uses the later control run.
