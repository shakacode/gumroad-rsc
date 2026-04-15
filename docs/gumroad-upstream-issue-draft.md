# Gumroad Upstream Issue Draft

## Goal

The right upstream goal is narrow:

- show one bounded, measurable comparison surface
- avoid proposing a broad migration
- ask whether Gumroad would review a focused experiment branch or PR if the performance case becomes stronger

The current best candidate is the reduced dashboard comparison:

- `Inertia` control: `/dashboard/inertia_demo`
- `React on Rails Pro + RSC` demo: `/dashboard/rsc_demo`

## Paste-ready issue draft

```md
## Proposal

I put together a public experiment repo that tracks Gumroad and compares a matched Inertia control against a bounded React on Rails Pro + React 19 + RSC implementation on one reduced dashboard surface:

- Repo: https://github.com/shakacode/gumroad-rsc
- Comparison docs: https://github.com/shakacode/gumroad-rsc/blob/jg-codex/react-on-rails-pro-demo/docs/performance-findings.md

The goal is not to argue for a broad rewrite.
The goal is to determine whether there are specific read-heavy surfaces where a server-component-oriented approach can produce enough user-visible benefit to justify the extra complexity.

## What the current experiment shows

On the matched `/dashboard/inertia_demo` versus `/dashboard/rsc_demo` comparison:

- Inertia navigation duration: `492.03ms`
- RSC navigation duration: `429.90ms`
- Inertia LCP: `496.00ms`
- RSC LCP: `452.00ms`
- Inertia responseEnd: `344.90ms`
- RSC responseEnd: `371.20ms`

So the current result is:

- the bounded RSC route is faster on total navigation duration
- the bounded RSC route is faster on LCP
- the Inertia control is still faster on server responseEnd

That means this is not yet a universal performance win.
It is a narrow, measurable tradeoff with an early user-visible upside.

## Why this may be worth reviewing

- the comparison uses the same reduced seller-data surface on both routes
- the RSC route removes the Inertia `data-page` payload for this surface
- the demo is now real enough to discuss architecture tradeoffs with code and measurements, not just theory
- the repo also demonstrates that `Shakapacker + Rspack` is viable here and materially faster for local builds

## What I am not claiming

- that the full Gumroad dashboard is already faster under RSC
- that RSC is a better fit for every Inertia page
- that the current result is production-like enough to justify adoption by itself

## What I want feedback on

1. Is this narrow comparison surface interesting enough to discuss further?
2. If yes, would Gumroad prefer that follow-up stay in the public experiment repo, or would a small upstream draft PR for the demo route be more useful?
3. If a follow-up is worth it, what would be the minimum proof needed to make this more than a curiosity?

## Links

- Current status: https://github.com/shakacode/gumroad-rsc/blob/jg-codex/react-on-rails-pro-demo/docs/current-status.md
- Performance findings: https://github.com/shakacode/gumroad-rsc/blob/jg-codex/react-on-rails-pro-demo/docs/performance-findings.md
- Positioning notes: https://github.com/shakacode/gumroad-rsc/blob/jg-codex/react-on-rails-pro-demo/docs/positioning-notes.md
```

## If converted into an upstream PR

The PR should stay even narrower than the issue.

Recommended framing:

- add one comparison surface only
- keep the current Inertia control route in the same PR
- keep the RSC route clearly labeled as an experiment
- do not mix in broad React 19 type cleanup
- do not pitch a migration in the PR body

Recommended PR title:

- `Add a bounded dashboard rendering experiment`

Recommended PR summary:

- add a matched control route and experiment route
- keep the scope to one reduced creator-home slice
- include measurement docs and explicit caveats

## What would make the upstream case stronger

- production-like measurements instead of local-development measurements
- a smaller or eliminated `responseEnd` penalty on the RSC route
- a cleaner explanation of where the remaining server cost comes from
- one short screen recording showing the side-by-side difference
- a clear statement of where Inertia still wins

## What would weaken the upstream case

- treating `Rspack` as if it explains the page-level runtime win
- treating the full dashboard as already solved
- making architecture claims that outrun the actual measurements
- proposing multiple migrations at once instead of one comparison surface
