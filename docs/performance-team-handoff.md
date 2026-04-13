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
- the RSC route reduces page-specific JS requests from `5` to `1`
- the raw RSC HTML transfer is now close to the Inertia control after the response-end pass

What is still true:

- the Inertia control still wins on `responseEnd`
- that remaining gap persisted even after most of the raw transfer-size gap was removed
- that suggests the remaining cost is more likely renderer or streaming overhead than simple HTML bloat

## Current matched result

Measured with:

- one explicit server warmup request
- local Docker-backed services
- local logged-in seller
- standalone React on Rails Pro Node renderer running

### Main local comparison

| Metric                 |   Inertia demo |       RSC demo |    Delta |
| ---------------------- | -------------: | -------------: | -------: |
| Navigation duration    |     `492.03ms` |     `429.90ms` | `-12.6%` |
| Response end           |     `344.90ms` |     `371.20ms` |  `+7.6%` |
| LCP                    |     `496.00ms` |     `452.00ms` |  `-8.9%` |
| HTML response transfer | `14,401` bytes | `15,444` bytes |  `+7.2%` |
| JS request count       |            `5` |            `1` | `-80.0%` |

### Raw response reduction achieved during this pass

The response-end pass reduced the RSC route from roughly:

- raw response: `36.9KB` -> `15.1KB`
- inline RSC script: `25.4KB` -> `8.9KB`

That means the remaining `responseEnd` penalty is not explained by raw response size alone.

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

It does **not** yet prove the full upside of RSC as an architecture.

## Highest-value next optimization targets

If the performance team wants the next round to be high signal, focus here:

1. Instrument the React on Rails Pro renderer and streaming path.
   We need to know where the remaining `responseEnd` cost lives.

2. Compare development-mode results against production-like runs.
   Current measurements are local-development runs.

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

The new demo surface is already covered in CI in two important ways:

- the asset build path runs `npm run build:rsc-demo` during image compilation in [`docker/web/compile_assets.sh`](../docker/web/compile_assets.sh)
- the standard test matrix covers the demo controller specs, so the new routes are not relying only on local verification

## Key artifacts

- [matched comparison JSON](../output/playwright/dashboard-perf/warmed-matched-inertia-vs-rsc-comparison.json)
- [Inertia metrics JSON](../output/playwright/dashboard-perf/inertia-demo-control-warm-trimmed-3-dashboard-inertia-demo-metrics.json)
- [RSC metrics JSON](../output/playwright/dashboard-perf/rsc-demo-warm-trimmed-3-dashboard-rsc-demo-metrics.json)

## Current sharing status

The repo is public, the stacked PRs are open, and the React on Rails issue is available as the team-facing discussion hub.

The JSON artifacts linked above are local benchmark outputs, so they are shareable through the repo checkout and branch work, but not through GitHub artifact hosting.
