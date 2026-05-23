# Cordon — User Stories & On-Chain Requirements

Capstone Assignment 2 for the Turbin3 Builders Cohort. This repo holds my submission — the deliverable, the process appendix, and the script that builds them into the single PDF the assignment asks for.

> **Submission PDF →** [`dist/cordon-user-stories.pdf`](./dist/cordon-user-stories.pdf)
> Direct download: <https://github.com/Hijanhv/capstone-user-stories-onchain/raw/main/dist/cordon-user-stories.pdf>
> Single file, Part A and Part B concatenated with a table of contents. This is the file to upload to the assignment portal.

The project this assignment is about is **Cordon**, a transaction firewall for Solana AI agents. I defined it in Capstone Assignment 1; the refined value proposition from that work is the constraint everything in this submission maps back to. The full prior proposal is checked in at the root of this repo as [`cordon-proposal.pdf`](./cordon-proposal.pdf), and a one-line recap is at the top of the deliverable.

## What's in here

| File | What it is |
|---|---|
| [`part-a-deliverable.md`](./part-a-deliverable.md) | **Part A** — the clean, final deliverable. Personas, function map, the two critical user interactions, the 24 atomic user stories, and the on-chain requirements brainstormed per story. This is what the assignment is graded on. |
| [`part-b-process-appendix.md`](./part-b-process-appendix.md) | **Part B** — the process log. Every AI prompt, the synthesized output, what I agreed with, what I overrode and why, and the explicit before/after refinement log (C1–C12) from the Part C atomicity pass. Structured to mirror the assignment's own Parts A through D. |
| [`cordon-proposal.pdf`](./cordon-proposal.pdf) | The previous capstone assignment, checked in so this submission is self-contained. |
| [`build.sh`](./build.sh) | Pandoc → HTML → headless Chrome → PDF. No LaTeX dependency, so it just works. |
| [`dist/cordon-user-stories.pdf`](./dist/cordon-user-stories.pdf) | The submission PDF — Part A and Part B concatenated, with a TOC. |

## Reading order

If you only want the deliverable, read [`part-a-deliverable.md`](./part-a-deliverable.md). It goes:

1. One-line value-prop recap.
2. The four POC personas I picked, with why-these-four.
3. Function map — one concrete, single-action function per row, per persona.
4. The two critical interaction paths the POC has to prove (auto-approval, HITL).
5. The 24 final user stories — atomic, de-jargoned, stable numbering so the requirements in §6 can cite back.
6. The on-chain requirements brainstorm — each story followed by its bulleted requirements list, organized around the `Policy` and `Intent` Anchor accounts.
7. Open questions I'm explicitly handing forward to the smart-contract architecture assignment.

If you want the work behind it — which AI suggestions I took, which I overrode, why every story got split or merged — read [`part-b-process-appendix.md`](./part-b-process-appendix.md). It's structured so any claim in the deliverable can be traced back to the prompt and the reasoning that produced it.

## How I scoped it

Everything in this submission is scoped to a single, named loop: an agent submits a transaction intent, the on-chain policy checks it, and either the transaction auto-broadcasts or a human approver decides. Every persona in §2 either drives that loop or governs the rules behind it. Every function in §3 maps to one step of it. Every story in §5 is one atomic action inside it. Personas that only consume the loop's outputs — compliance officer, end user of an agent-managed treasury, protocol risk manager, regulator — are named in the appendix (B.2) with explicit reasons for being out of scope (B.3).

My capstone window is six weeks. I'm scoping personas the same way I'm scoping instructions.

## Rebuilding the PDF

```bash
./build.sh
```

Requires `pandoc` and Google Chrome (or any Chromium-family browser). On macOS:

```bash
brew install pandoc
# Chrome is already installed on the build machine
```

The script renders the two markdown files into a single standalone HTML, then prints to PDF via headless Chrome. Idempotent. The markdown files are the source of truth; `dist/cordon-user-stories.pdf` is regenerable from them at any time.
