# Current Status

## Short answer

No, the demo is not ready yet.

This repository is currently in the planning and framing stage, not the implementation stage.

## What is already done

- Created the public experiment repo under `shakacode/gumroad-rsc`
- Seeded it from current `antiwork/gumroad`
- Preserved `upstream` so the experiment stays grounded in the real app
- Documented the comparison plan in [rsc-comparison-plan.md](./rsc-comparison-plan.md)
- Documented positioning, adjacent ideas, and IP guardrails in [positioning-notes.md](./positioning-notes.md)
- Selected `Dashboard` as the first comparison surface
- Documented the first implementation-facing brief in [dashboard-experiment-brief.md](./dashboard-experiment-brief.md)

## What is not done yet

- no baseline metrics have been captured
- no React on Rails Pro integration has been added
- no React 19 upgrade work has been done
- no RSC proof of concept has been implemented
- no Shakapacker or Rspack migration work has started
- no side-by-side screenshots, videos, or performance measurements exist yet

## What "demo ready" means

The demo should not be considered ready until it can show all of the following:

- one clearly chosen page or flow
- the current Inertia implementation running as the baseline
- a bounded React on Rails Pro implementation of the same surface
- enough React 19 or RSC usage to make the comparison meaningful
- measurements or at least disciplined observations for bundle size, loading behavior, and developer tradeoffs
- a short written conclusion that says where Inertia wins and where React on Rails Pro wins

## Environment readiness

Current local state:

- Docker is available
- `node_modules` is not installed
- `bundle check` currently fails because gems are not installed

That means the repository is ready for setup work, but not yet ready for baseline capture on this machine.

## Recommended next step

The next real step is to establish the baseline for the selected `Dashboard` surface.

Recommended order:

1. Install dependencies and get the app running locally.
2. Capture baseline notes, screenshots, and measurements for `Dashboard`.
3. Decide the smallest implementation slice that can demonstrate React on Rails Pro value on `Dashboard`.
4. Only then start code changes for React 19, Pro, RSC, or bundler work.

## Suggested branch sequence

- `jg-codex/baseline-metrics`
- `jg-codex/shakapacker-upgrade`
- `jg-codex/rspack-migration`
- `jg-codex/react-on-rails-pro-poc`
- `jg-codex/rsc-poc`

## Adjacent ideas to keep documented but out of scope for the first demo

- a clean-room Inertia extension that improves React 19 SSR behavior
- a React 19 compatibility guide for Inertia users
- a Shakapacker plus Rspack positioning story that works for both Inertia and React on Rails users

## Decision rule

If the first comparison cannot produce a narrow, credible, evidence-backed win, then the right output is better positioning insight, not a migration pitch.
