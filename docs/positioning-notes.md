# Positioning Notes

## Why this repo exists

This experiment is not just about building a demo. It is also about improving how ShakaCode positions:

- `shakapacker`
- `react_on_rails`
- `react_on_rails_pro`
- React 19 and RSC support in Rails applications

The goal is to leave this repo with clearer answers to:

- where Inertia is genuinely strong
- where React on Rails Pro is stronger
- how to explain that difference credibly
- what product opportunities exist adjacent to Inertia rather than directly against it

## Positioning Questions

### Inertia strengths to respect

- Rails-native controller flow is simple and productive.
- Inertia keeps the backend as the source of truth.
- Partial reloads and deferred props are strong for many app pages.
- Teams can get SPA navigation without committing to a full frontend architecture rewrite.

If we ignore these strengths, any comparison will sound ideological instead of practical.

### React on Rails Pro strengths to test

- Stronger fit for large React codebases inside Rails.
- Better story for advanced React architecture, not just SPA navigation.
- A more natural home for React 19 features and RSC-style composition.
- Better reuse of React code across server and client boundaries.
- Better fit for pages that are effectively React applications, not just server-driven pages with some interactivity.

## Messaging Hypothesis

The likely winning message is not:

- "React on Rails should replace Inertia."

The better message is closer to:

- "Inertia is excellent for many Rails pages, but some product surfaces cross the line into full React application territory. That is where React on Rails Pro can justify itself."

## What this experiment should produce

- one or two honest comparison case studies
- before/after architecture notes
- measurements for payload, SSR behavior, and perceived responsiveness
- a sharper decision framework: when to choose Inertia vs React on Rails Pro
- concrete examples for docs, talks, and sales conversations

## Adjacent Product Ideas

### 1. React 19 compatibility knowledge for Inertia users

Question:

Can work done for React on Rails support for React 19 help Inertia users?

Working answer:

Yes, but only partially.

Reusable areas likely include:

- React 19 upgrade checklists
- deprecated API migration guidance
- hydration and SSR compatibility fixes
- package ecosystem compatibility notes
- bundler and JSX-transform requirements

Less reusable areas:

- React on Rails component registration model
- Rails context integration
- proprietary server rendering and Pro-specific RSC features

So the opportunity is probably not "Inertia should use React on Rails internally." The opportunity is more likely:

- publish compatibility knowledge
- provide migration guides
- offer integration patterns where appropriate

### 2. Inertia extension that uses a Node rendering server

This is worth exploring.

Inertia already documents SSR via a Node-based server process, including for Rails. That means there is conceptual space for an extension that improves the React side of that rendering story without replacing the Inertia protocol itself.

Potential directions:

- a React 19-focused Inertia SSR adapter
- a streaming-oriented SSR extension for Inertia Rails
- an "advanced React mode" for Inertia pages with better SSR ergonomics
- a hybrid model where Inertia remains the transport/protocol layer while React rendering gets upgraded

The key is that this would need to be positioned as complementary to Inertia, not as a stealth fork of it.

### 3. Shakapacker and Rspack positioning

This repo should also help answer whether Shakapacker plus Rspack can be positioned as:

- a better Rails-native asset pipeline for modern React apps
- a credible alternative for teams that want more control than Vite defaults
- a bundling story that works for both Inertia and React on Rails users

But the message has to stay disciplined:

- `Rspack` is a build-speed and iteration-speed story
- `RSC` is the story that might justify added runtime complexity on the page
- mixing those two claims weakens both

### 4. Commercial bridge for existing Inertia Rails apps

This may be a real product path.

The strongest version is not:

- "replace Inertia with React on Rails"

The stronger version is:

- "keep Inertia, but upgrade the rendering and React-runtime story for Rails apps that have already committed to Inertia"

Possible shape:

- a commercial Rails gem plus JS package
- designed for apps already using `inertia_rails` and React
- optional Node-renderer-backed SSR for Inertia pages
- React 19 compatibility guidance and defaults
- CSP, process boot, observability, and failure-fallback support around SSR

What makes this attractive:

- it meets teams where they already are
- it lowers the adoption barrier compared with a full architecture switch
- it creates a friendlier entry product than full React on Rails Pro
- it may create an upsell path into broader ShakaCode tooling later

What the first version should probably not try to do:

- full RSC semantics inside the Inertia protocol
- a broad rewrite of Inertia internals
- official-sounding branding that implies endorsement from the Inertia team

The key technical caution is that Inertia's page-props protocol maps naturally to SSR, but much less naturally to RSC-style server/client boundaries.

So the safer product ladder is likely:

- first: SSR and React 19 support for Inertia Rails
- second: streaming-oriented improvements if they fit the protocol cleanly
- third: only explore deeper RSC-style integration if the value is clear and the abstraction stays honest

Possible positioning:

- "ShakaCode SSR for Inertia Rails"
- "React 19 support for Inertia Rails"
- "advanced rendering for Inertia Rails"

Possible licensing posture:

- commercial but friendlier than full React on Rails Pro
- priced and named as an add-on for existing Inertia apps
- source-available or private commercial distribution if it depends on proprietary renderer code

This only makes sense if the product stays clearly complementary to Inertia and clearly separate from any proprietary implementation details that should remain inside ShakaCode products.

## IP and Product Guardrails

### Public vs proprietary

The Gumroad codebase in this repo is MIT-licensed, so code from this repository is broadly reusable under that license.

That does **not** mean proprietary React on Rails Pro code is automatically reusable in a public Inertia-oriented project.

### Important distinction

There is a major difference between:

- building a clean-room integration that uses public APIs and public documentation
- copying or deriving implementation details from closed-source Pro code

Only the first is a safe default engineering posture.

### Practical guardrail

If ShakaCode wants to explore an Inertia-facing extension in public, it should be built with:

- public React APIs
- public Inertia APIs
- public React on Rails OSS code only
- no copying from private Pro implementation

If proprietary code is involved, the work should stay private unless legal and product review says otherwise.

## Notes on enforcement

General principle, not legal advice:

- if someone publishes a repo that copies or derives from proprietary non-open-source code without permission, that can create a copyright and licensing problem
- GitHub’s policies prohibit content that infringes proprietary rights, and GitHub provides DMCA takedown procedures for copyright claims

Before taking action on a real case, involve counsel and preserve evidence of what was copied and from where.

## Sources to keep in mind

- Inertia official docs and Rails SSR docs
- React 19 upgrade guidance
- ShakaCode docs for React on Rails Pro and RSC
- GitHub IP and DMCA policies

## Current tactical implication

For now, the best path is:

- build the comparison honestly
- document where Inertia wins
- document where React on Rails Pro wins
- treat the current Inertia plus Rspack branch as enabling infrastructure, not the runtime pitch
- use the matched `/dashboard/inertia_demo` versus `/dashboard/rsc_demo` pair as the primary comparison surface
- treat the current balanced alternating result as promising but mixed:
- the matched RSC route wins on `LCP` and total navigation duration
- the matched RSC route also cuts page-specific JS requests from `6` to `1`
- the matched Inertia route still wins on server `responseEnd` and controller `action_total`
- note that the response-end pass cut the raw RSC response to near-parity on transfer size, but the server-side penalty still remained under the balanced method
- require the next React on Rails Pro plus RSC pass to keep the user-visible win while narrowing the renderer or streaming overhead
- only then decide whether the next move is docs, a public integration, a private product feature, or an upstream proposal
