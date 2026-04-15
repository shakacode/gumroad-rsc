# Dashboard Experiment Brief

## Why `Dashboard` is the first target

`Dashboard` is the best first comparison surface for this repository because it is a better test of React 19 and RSC value than a client-heavy editing page.

It has three useful properties:

- one clean Inertia entrypoint
- one large React page component
- a presenter-driven data shape that is already a natural candidate for server/client decomposition

That makes it easier to ask whether React on Rails Pro plus React 19 can improve composition, streaming, payload boundaries, or maintainability without claiming that the whole app should move off Inertia.

## Current architecture

### Rails controller

- Route: `/dashboard`
- Controller: [app/controllers/dashboard_controller.rb](../app/controllers/dashboard_controller.rb)
- Rendering path: `render inertia: "Dashboard/Index", props: { creator_home: presenter.creator_home_props }`

### Presenter

- Presenter: [app/presenters/creator_home_presenter.rb](../app/presenters/creator_home_presenter.rb)
- Main responsibility: build the `creator_home` payload for the page

The presenter currently assembles:

- getting started checklist state
- best-selling products data
- balance summaries
- activity feed items
- tax form/download state
- stripe verification message

### Inertia page wrapper

- Entry: [app/javascript/pages/Dashboard/Index.tsx](../app/javascript/pages/Dashboard/Index.tsx)

This wrapper is intentionally thin. It simply reads `creator_home` from Inertia props and passes it into the page component.

### Main React page

- Component: [app/javascript/components/DashboardPage.tsx](../app/javascript/components/DashboardPage.tsx)

The page currently renders:

- page header
- tax form and verification alerts
- getting started checklist
- empty-state greeter
- best-selling products table
- four stats cards
- activity feed

## Why this is promising for an RSC comparison

The current implementation already has a strong server/data boundary:

- Rails presenter builds a large page payload
- Inertia sends the payload once
- React renders a mostly read-heavy page around that payload

That means the likely React 19/RSC comparison seam is not "replace everything." The seam is:

- keep some interactive client pieces as client components
- move read-heavy or data-assembly-heavy sections toward server-rendered React boundaries
- compare whether that split is clearer or lighter than the current presenter-plus-Inertia-props model

## Most likely comparison seams

### High-confidence seams

- best-selling products table
- activity feed
- tax forms/download section
- getting started checklist shell

### Lower-confidence seams

- stats cards

These are already simple and may not benefit enough to matter.

## Current behavior worth preserving

- sellers with no activity still get a useful dashboard state
- suspended sellers are redirected away from the page
- the getting started checklist has dismiss/minimize state
- existing controller and presenter specs already cover important state transitions

## Current test surface

Relevant existing files:

- [spec/controllers/dashboard_controller_spec.rb](../spec/controllers/dashboard_controller_spec.rb)
- [spec/presenters/creator_home_presenter_spec.rb](../spec/presenters/creator_home_presenter_spec.rb)

This is useful because the experiment can preserve and extend a bounded spec surface instead of inventing new coverage from scratch.

## Baseline capture checklist

Before changing implementation, capture:

- screenshot of dashboard with no activity
- screenshot of dashboard with meaningful activity
- `data-page` payload size for the `creator_home` prop
- loaded JS and CSS assets for the dashboard route
- basic notes on navigation/load behavior
- notes on how much logic currently lives in the presenter vs React

## Environment status for baseline work

Current verified state:

- Docker-backed local services boot
- Rails boots locally on `:3000`
- the Shakapacker dev server boots locally on `:3035`
- nginx boots locally once `helperai.dev` cert files exist
- the current dashboard spec surface is green locally after test merchant-account seeds are loaded

That means the next engineering step is no longer setup. The next engineering step is baseline capture plus the first upgrade branch.

## Hidden prerequisites discovered during setup

- The dashboard spec surface depends on seeded `MerchantAccount` records in `RAILS_ENV=test`.
- `db:prepare` alone did not create those rows in test on this machine.
- Loading these seed files fixed the issue:
  - `db/seeds/010_stripe_merchant_account_seeds.rb`
  - `db/seeds/020_braintree_merchant_account_seeds.rb`
  - `db/seeds/030_paypal_merchant_account_seeds.rb`
- The local nginx proxy also expects `helperai.dev` certificates, not just the checked-in `gumroad.dev` certificates.
- The repository already provides `bin/generate_ssl_certificates` for this, but CA installation may still require a manual sudo step on macOS if browser trust matters.

## First implementation slice

The first real code branch should be:

- upgrade React to 19
- upgrade Shakapacker to `10.0.0`
- switch the current Inertia app from Webpack to Rspack

This should happen before adding the separate React on Rails Pro surface, because it answers an important positioning question directly:

- can Shakapacker plus Rspack improve this app today without asking Gumroad to leave Inertia?

If that branch stays low-risk, it becomes a much easier review story than opening with a React on Rails migration pitch.

## Success condition for this target

The `Dashboard` experiment is a success only if it can show a narrow, credible win such as:

- clearer section boundaries between server-rendered and client-rendered concerns
- smaller or more deferrable client payload for the page
- better perceived loading behavior
- a meaningfully better development model for evolving the page

If it cannot do that, the right conclusion is that `Dashboard` should stay on the current Inertia shape and the positioning lesson should be captured honestly.
