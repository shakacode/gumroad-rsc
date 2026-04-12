# Dashboard RSC Benchmark Plan

## Goal

Decide whether a `React on Rails Pro + React 19 + RSC` dashboard is worth the extra complexity compared with the current `Inertia` dashboard.

The question is not whether `Rspack` is faster to build with. That is already established.

The question is whether `RSC` can make the page itself better enough to matter.

## Apples-to-apples rule

Compare the same route:

- baseline: current `Inertia` dashboard
- candidate: `React on Rails Pro + RSC` dashboard

Keep these constant where possible:

- same local database
- same logged-in seller
- same Docker-backed services
- same nginx and browser setup
- same measurement harness

## What should change in the candidate

The candidate should be narrow.

Target changes:

- keep the dashboard page intent and UI broadly the same
- replace the Inertia route with a React on Rails Pro route for this page only
- use `RSC` for read-heavy sections
- keep only truly interactive pieces as client components

## First candidate sections

Bias toward sections that are mostly display and data shaping:

- best-selling products table
- activity feed
- tax form and verification messages
- checklist container, with client-only controls if needed

Avoid spending the first pass on sections that are already cheap:

- simple stats cards

## Primary metrics

These are the metrics that matter for the first decision:

- total dashboard JS transferred
- largest dashboard JS chunk
- dashboard LCP
- total dashboard navigation duration

## Secondary metrics

These help explain the result:

- HTML document size
- count of JS requests
- serialized page-prop payload size
- server response end

## Suggested success bar

The first `RSC` demo should be considered a meaningful performance win only if it can show something like:

- at least `20%` less dashboard JS transferred
- at least `10%` smaller largest client chunk
- equal or better `LCP`
- no meaningful regression in total navigation duration

If the page gets only marginally better while becoming much more complex, that is not a win.

## Qualitative checks

The performance result is not enough by itself. Also record:

- whether the server/client boundary is easier to reason about
- whether the page stops depending on one large `creator_home` client payload
- whether the implementation isolates client interactivity more cleanly
- whether the review story looks believable for a bounded upstream discussion

## Decision outcomes

If the candidate wins:

- use it as the core case study for React on Rails Pro plus RSC positioning
- keep the upstream story narrow and evidence-backed

If the candidate does not win:

- keep the repo as a positioning and product-learning experiment
- do not pitch a migration story
- still use the repo to support `Shakapacker + Rspack` messaging for Inertia users
