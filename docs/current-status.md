# Current Status

## Short answer

No, the demo is not ready yet.

This repository has moved past pure planning and is now in baseline setup plus first implementation planning.

## What is already done

- Created the public experiment repo under `shakacode/gumroad-rsc`
- Seeded it from current `antiwork/gumroad`
- Preserved `upstream` so the experiment stays grounded in the real app
- Documented the comparison plan in [rsc-comparison-plan.md](./rsc-comparison-plan.md)
- Documented positioning, adjacent ideas, and IP guardrails in [positioning-notes.md](./positioning-notes.md)
- Selected `Dashboard` as the first comparison surface
- Documented the first implementation-facing brief in [dashboard-experiment-brief.md](./dashboard-experiment-brief.md)
- Installed Ruby gems locally
- Installed `node_modules` locally
- Brought up the Docker-backed local services
- Confirmed the targeted dashboard controller and presenter spec surface passes locally once required seed data exists

## What is not done yet

- no baseline metrics have been captured
- no React on Rails Pro integration has been added
- no React 19 upgrade branch has been implemented yet
- no RSC proof of concept has been implemented yet
- no Shakapacker 10 or Rspack migration branch has been implemented yet
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
- Docker-backed services are running
- `node_modules` is installed
- gems are installed
- Rails boots locally on port `3000`
- the Shakapacker dev server boots locally on port `3035`
- local nginx now boots once `helperai.dev` cert files exist

That means the repository is now ready for baseline capture and upgrade work on this machine.

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

## Recommended next step

The next real step is to start the first implementation branch for the selected `Dashboard` surface.

Recommended order:

1. Capture baseline notes, screenshots, and measurements for `Dashboard`.
2. Upgrade the existing Inertia stack to React 19 plus Shakapacker 10.
3. Switch Shakapacker from Webpack to Rspack while preserving the current Inertia behavior.
4. Add the smallest separate React on Rails Pro demo surface that reuses the same dashboard data shape.
5. Only then expand into deeper RSC-specific comparison work.

## Suggested branch sequence

- `jg-codex/baseline-dashboard`
- `jg-codex/react19-rspack`
- `jg-codex/react-on-rails-pro-demo`
- `jg-codex/rsc-dashboard-poc`

## Adjacent ideas to keep documented but out of scope for the first demo

- a clean-room Inertia extension that improves React 19 SSR behavior
- a React 19 compatibility guide for Inertia users
- a Shakapacker plus Rspack positioning story that works for both Inertia and React on Rails users

## Decision rule

If the first comparison cannot produce a narrow, credible, evidence-backed win, then the right output is better positioning insight, not a migration pitch.
