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
- the dashboard harness now authenticates over HTTP before loading the page in Chrome, so the measurement is not dependent on browser login behavior

## Results

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

## Interpretation

The developer-experience win is real.

- Rspack is dramatically faster for cold builds in both development and production.
- That is already a legitimate Shakapacker positioning point for Inertia apps.

This does **not** mean the React 19 or RSC hypothesis failed.

- This branch is still rendering the page through the same Inertia architecture.
- We would not expect the bundler swap alone to create a meaningful route-level win.
- The purpose of these route metrics is to establish the baseline that a follow-up React on Rails Pro plus RSC branch must beat.

The runtime win is still unproven.

- The dashboard route is not materially faster under the current branch.
- `responseEnd` improved slightly, but total load time and LCP were slightly worse.
- The client-side JS cost went up meaningfully, both in transferred bytes and number of JS requests.

That means the current evidence does **not** support any runtime-performance claim yet, but it does give us the baseline for judging the real `RSC` experiment.

## What This Means For Positioning

Today’s credible story is:

- `Shakapacker + Rspack` can deliver immediate build and dev-loop wins for a real Inertia app.
- `React 19 + Rspack` is technically viable here, but this branch is not the runtime-performance pitch.

Today’s non-credible story is:

- "Switching this dashboard path to the current branch makes the user experience clearly faster."

The next demo only helps if a separate `React on Rails Pro + RSC` implementation beats the current Inertia baseline on metrics that matter:

- lower JS transferred for the page
- equal or better LCP
- equal or better total navigation duration

If a React on Rails Pro or RSC demo cannot beat those numbers, then it should be positioned as a composition or product-shaping experiment, not a performance pitch.

## Recommended Next Step

Keep the branches and claims narrow:

1. Keep `jg-codex/react19-rspack` focused on bundler viability and build-speed wins.
2. Treat React 19 type cleanup as a separate stacked branch if needed.
3. Build a separate `React on Rails Pro + RSC` dashboard branch and measure it with the same harness.
4. Judge that branch against this Inertia baseline on JS transferred, LCP, and total navigation duration.
5. Do not file upstream issues or pitch upstream adoption on runtime-performance grounds until that branch wins on route-level metrics.
