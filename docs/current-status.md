# Current Status

## Short answer

No, the demo is not ready yet.

This repository has moved past pure planning and through the first implementation branch for the current Inertia stack.

## What is already done

- Created the public experiment repo under `shakacode/gumroad-rsc`
- Seeded it from current `antiwork/gumroad`
- Preserved `upstream` so the experiment stays grounded in the real app
- Documented the comparison plan in [rsc-comparison-plan.md](./rsc-comparison-plan.md)
- Documented the runtime pass/fail rubric in [rsc-benchmark-plan.md](./rsc-benchmark-plan.md)
- Documented positioning, adjacent ideas, and IP guardrails in [positioning-notes.md](./positioning-notes.md)
- Selected `Dashboard` as the first comparison surface
- Documented the first implementation-facing brief in [dashboard-experiment-brief.md](./dashboard-experiment-brief.md)
- Documented measured results in [performance-findings.md](./performance-findings.md)
- Installed Ruby gems locally
- Installed `node_modules` locally
- Brought up the Docker-backed local services
- Confirmed the targeted dashboard controller and presenter spec surface passes locally once required seed data exists
- Upgraded `shakapacker` to `10.0.0`
- Upgraded React and React DOM to `19.2.5`
- Switched the local Shakapacker bundler path from Webpack to Rspack
- Added a real `config/rspack/` config tree instead of relying on the deprecated webpack-config fallback
- Confirmed `bin/shakapacker` builds successfully in both development and production with Rspack
- Confirmed `bin/shakapacker-dev-server` boots successfully on `https://gumroad.dev:3035/`
- Removed an obsolete `patch-package` patch for `react-dom@18.3.1` because React 19 already includes the needed `inert` support

## What is not done yet

- no React on Rails Pro integration has been added
- no React on Rails Pro demo branch has been implemented yet
- no RSC proof of concept has been implemented yet
- the React 19 type fallout has not been cleaned up yet across the app

## What "demo ready" means

The demo should not be considered ready until it can show all of the following:

- one clearly chosen page or flow
- the current Inertia implementation running as the baseline
- a bounded React on Rails Pro implementation of the same surface
- enough React 19 or RSC usage to make the comparison meaningful
- measurements or at least disciplined observations for bundle size, loading behavior, and developer tradeoffs
- a short written conclusion that says where Inertia wins and where React on Rails Pro wins

## Measured findings

The first dashboard measurements now exist.

Short version:

- Rspack is a strong developer-performance win here
- no route-level runtime win was expected from the bundler swap by itself
- the current dashboard JS transfer is materially larger
- the real runtime question is still open until a separate React on Rails Pro plus RSC branch exists

That means the demo is still not ready.

The missing piece is no longer "can this compile?" The missing piece is "can a follow-up React on Rails Pro plus RSC surface beat the current Inertia baseline on real route metrics?"

The benchmark rubric for that decision now lives in [rsc-benchmark-plan.md](./rsc-benchmark-plan.md).

## Environment readiness

Current local state:

- Docker is available
- Docker-backed services are running
- `node_modules` is installed
- gems are installed
- Rails boots locally on port `3000`
- the Rspack-backed Shakapacker dev server boots locally on port `3035`
- local nginx now boots once `helperai.dev` cert files exist

That means the repository is now ready for comparison work on this machine.

## Setup findings that matter

- `RAILS_ENV=test bin/rails db:prepare` was not enough for the dashboard spec surface because the test database had no `MerchantAccount` rows.
- Loading the three merchant-account seed files in `RAILS_ENV=test` fixed that hidden prerequisite and made the targeted dashboard suite pass.
- `make local` initially left nginx down because `docker/local-nginx/helperai_dev.crt` and `.key` were missing.
- The repository already includes `bin/generate_ssl_certificates` for this, but on macOS it may fail at `mkcert -install` if local sudo access is not available.
- For local-only boot, generating the `helperai.dev` cert files without installing the CA is sufficient to get nginx running, though browsers may still warn about trust.

## Verified baseline state

- Targeted command: `bundle exec rspec spec/controllers/dashboard_controller_spec.rb spec/presenters/creator_home_presenter_spec.rb`
- Result after seeding merchant accounts in test: `44 examples, 0 failures`
- This gives the experiment a bounded baseline surface before any React 19, Rspack, or React on Rails work lands.

## Verified current implementation state

- Development build: `RAILS_ENV=development NODE_ENV=development bin/shakapacker --mode development`
- Result: successful Rspack build for both the main app bundles and widget bundles
- Production build: `RAILS_ENV=production NODE_ENV=production bin/shakapacker`
- Result: successful Rspack build with asset-size warnings but no compilation failures
- Dev server: `RAILS_ENV=development NODE_ENV=development bin/shakapacker-dev-server`
- Result: boots successfully on `https://gumroad.dev:3035/`
- `npm run build`
- Result: now succeeds after removing webpack-only CLI flags from the npm scripts

## Current blocker for calling the branch "review ready"

The build path is working, but React 19 adoption still exposes broad TypeScript cleanup work across the app.

Current `npx tsc --noEmit` results show app-wide errors in categories like:

- stricter React 19 `ref` typing
- callback refs that return values instead of `void`
- implicit `any` in callbacks that previously slipped through
- at least one `isolatedModules`-related type-only import fix

That means the branch has crossed the important threshold of "Rspack migration is viable here", but it has not yet crossed the threshold of "React 19 upgrade is low-noise enough for easy upstream review."

## Recommended next step

The next real step is to keep the claims and branches narrow.

Recommended order:

1. Preserve this branch as the "Shakapacker 10 plus Rspack viability" branch.
2. Decide whether React 19 type cleanup belongs in the same branch or in a follow-up stacked branch.
3. Treat the current dashboard measurements as the Inertia baseline to beat, not as a runtime conclusion.
4. Add the smallest separate React on Rails Pro dashboard surface that keeps the same data and UI intent.
5. Use RSC on the read-heavy dashboard sections to target lower client JS cost and equal or better page metrics.
6. Only then decide whether a deeper migration story is warranted.

## Suggested branch sequence

- `jg-codex/baseline-dashboard`
- `jg-codex/react19-rspack`
- `jg-codex/react19-type-cleanup` if the type fallout is too noisy for the bundler branch
- `jg-codex/react-on-rails-pro-demo`
- `jg-codex/rsc-dashboard-poc`

## Adjacent ideas to keep documented but out of scope for the first demo

- a clean-room Inertia extension that improves React 19 SSR behavior
- a React 19 compatibility guide for Inertia users
- a Shakapacker plus Rspack positioning story that works for both Inertia and React on Rails users

## Decision rule

If the first React on Rails Pro plus RSC comparison cannot produce a narrow, credible, evidence-backed runtime or composition win, then the right output is better positioning insight, not a migration pitch.
