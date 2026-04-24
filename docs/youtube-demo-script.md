# YouTube Demo Script

## Goal

Show one honest claim:

- a bounded `React on Rails Pro + RSC` surface can beat a matched `Inertia` control on user-visible metrics

Do not claim:

- a universal RSC win
- that the full dashboard is already faster
- that `Rspack` is responsible for the route-level runtime gain

## Suggested video length

- short version: `90` to `120` seconds
- full version: `4` to `6` minutes

## Recording setup

- keep both demo routes logged in before recording
- have [docs/performance-findings.md](./performance-findings.md) open in another tab
- keep the repo README open in another tab
- optionally keep the two screenshots visible as a fallback

## Short version script

### Opening

```text
This is a Gumroad rendering experiment from ShakaCode.
The question is simple: can a bounded React on Rails Pro plus React Server Components surface beat a matched Inertia control enough to justify the extra complexity?
```

### Show the control

```text
This route is the control: `/dashboard/inertia_demo`.
It uses the same reduced seller-data surface as the experiment route.
```

### Show the RSC route

```text
This route is the experiment: `/dashboard/rsc_demo`.
Same basic surface, different rendering model.
```

### State the measured result

```text
On this matched local comparison, the RSC route is faster on total navigation duration and faster on LCP.
The Inertia control still wins on server response end.
So this is not a universal win, but it is a real user-visible win on a bounded surface.
```

### Close

```text
That makes this interesting for product positioning and maybe for a narrow upstream discussion, but not yet for a broad migration pitch.
```

## Full version script

### 1. Frame the problem

```text
We are not trying to prove that every Inertia page should be replaced.
We are trying to identify whether some read-heavy Rails surfaces cross the line where a richer React rendering model becomes worth it.
```

### 2. Show the repo

```text
This repo tracks Gumroad and keeps the work stacked:
baseline docs first, React 19 plus Rspack second, and the React on Rails Pro plus RSC demo third.
That keeps the review surface understandable.
```

### 3. Show the two routes

```text
Here is the Inertia control route.
Here is the RSC experiment route.
Both use the same reduced creator-home slice and the same seller-data surface.
```

### 4. Explain the actual result

```text
The matched RSC route wins on total navigation duration and on LCP.
The matched Inertia route still wins on response end.
That means the current story is mixed but promising.
The upside is user-visible.
The remaining cost is still on the server side.
```

### 5. Separate the two stories

```text
Rspack is the build-speed and dev-loop story.
RSC is the route-level runtime story.
If we blur those together, we weaken both claims.
```

### 6. Show the docs

```text
The repo includes the current status, the detailed performance findings, the performance-team handoff, and the positioning notes.
So this is not just a demo branch.
It is meant to help decide what should be positioned, what should be optimized next, and what should never be over-claimed.
```

### 7. Close with the honest ask

```text
If the next optimization pass keeps the LCP and navigation win while shrinking the response-end gap, this becomes much more compelling.
If not, it is still valuable because it tells us where the tradeoff actually lives.
```

## Shot list

1. README top section with the two screenshots
2. `/dashboard/inertia_demo`
3. `/dashboard/rsc_demo`
4. `docs/performance-findings.md` metrics table
5. `docs/current-status.md` short answer and current result
6. optional PR stack view on GitHub

## Good phrases to use

- `bounded comparison surface`
- `matched Inertia control`
- `user-visible win on LCP`
- `still slower on responseEnd`
- `promising, not universal`

## Phrases to avoid

- `RSC is obviously better`
- `Inertia is obsolete`
- `this proves Gumroad should migrate`
- `Rspack made the page faster`
