# Gumroad RSC Comparison Plan

## Goal

Build a credible comparison between:

- Gumroad as it exists today on Inertia
- A targeted React on Rails Pro + React 19 + RSC implementation

The comparison should answer one question clearly:

Would React on Rails Pro be meaningfully better for a specific class of Gumroad pages?

## Non-goals

- Do not try to prove that Inertia should be removed from the whole app.
- Do not file upstream issues or open upstream PRs until the experiment is working and measured.
- Do not start by porting large parts of the application blindly.

## Working Hypothesis

React on Rails Pro is most likely to be competitive on pages that are:

- data-heavy
- highly interactive
- already naturally componentized in React
- good candidates for React 19 features and server/client composition

It is less likely to be competitive on simple CRUD-style Rails pages where Inertia already fits well.

## Success Criteria

The experiment is successful only if it produces evidence in at least one of these areas:

- better perceived loading behavior
- smaller client-side JavaScript for the chosen page
- clearer server/client composition
- easier reuse of React code between server and client concerns
- materially better developer ergonomics for complex UI work

The experiment fails if the React on Rails Pro path mostly adds complexity without a measurable payoff.

## Proposed Execution Order

1. Establish an Inertia baseline on current upstream Gumroad.
2. Pick one comparison surface.
3. Upgrade the bundling/tooling path needed for the experiment.
4. Add React on Rails Pro and React 19 only where required.
5. Add an RSC proof of concept for the selected surface.
6. Measure and document the tradeoffs honestly.

## Candidate Comparison Surfaces

### Best initial candidates

- `Products/Edit`
- `Dashboard`
- `Checkout/Show`
- `Settings/Payments/Show`

### Selection criteria

- the page is important enough to matter
- the UI is complex enough to justify React specialization
- the page has meaningful server/client boundaries
- the comparison can be isolated without rewriting half the app

## Recommended First Target

Start by evaluating `Products/Edit` versus a more data-heavy read surface such as `Dashboard`, then choose one.

Reasoning:

- `Products/Edit` is the strongest test of complex client-side React workflows.
- `Dashboard` is the stronger test for streaming, server/client composition, and RSC-style data boundaries.

If we want to prove React 19 and RSC specifically, `Dashboard` may produce a cleaner argument. If we want to prove React-heavy UI ergonomics, `Products/Edit` is the better test.

## Branch Strategy

- `main`: upstream tracking plus experiment documentation
- `jg-codex/baseline-metrics`: capture baseline behavior and measurements
- `jg-codex/shakapacker-upgrade`: upgrade the asset pipeline as needed
- `jg-codex/rspack-migration`: migrate off webpack if justified
- `jg-codex/react-on-rails-pro-poc`: add React on Rails Pro for the selected surface
- `jg-codex/rsc-poc`: add the final RSC experiment

## Decision Rule Before Going Upstream

Do not take this upstream unless the experiment can show:

- a clearly bounded use case
- a realistic adoption path
- objective wins or a very strong qualitative improvement
- acceptable maintenance overhead

Without that, this should remain a ShakaCode experiment repo rather than an upstream proposal.
