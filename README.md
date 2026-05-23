# Cordon — User Stories & On-Chain Requirements

Capstone Assignment 2 for the Turbin3 Builders Cohort. This repo holds the deliverable, the process appendix, and the script that builds them into the single PDF the assignment asks for.

The project this assignment is about — **Cordon**, a transaction firewall for Solana AI agents — was defined in Capstone Assignment 1. The full prior proposal is at the root of this repo as `cordon-proposal.pdf`; a one-line recap is at the top of the deliverable.

## What's in here

| File | What it is |
|---|---|
| [`part-a-deliverable.md`](./part-a-deliverable.md) | **Part A** — the clean, final deliverable. Personas, function map, user stories, and on-chain requirements per story. This is what the assignment is graded on. |
| [`part-b-process-appendix.md`](./part-b-process-appendix.md) | **Part B** — the process log. Every prompt, the synthesized AI output, what I agreed with, what I overrode, and the explicit before/after refinement log for Part C. |
| [`cordon-proposal.pdf`](./cordon-proposal.pdf) | The previous capstone assignment, included so this deliverable is self-contained. |
| [`build.sh`](./build.sh) | Pandoc invocation that produces `dist/cordon-user-stories.pdf` from the two markdown files. |
| [`dist/cordon-user-stories.pdf`](./dist/cordon-user-stories.pdf) | The submission PDF — Part A and Part B concatenated. |

## How to read this

If you only want the deliverable, read `part-a-deliverable.md`. It is structured as:

1. One-line value-prop recap.
2. The four POC personas, with why-these-four.
3. Function map — one concrete, single-action function per row, per persona.
4. The two critical interaction paths the POC has to prove (auto-approval, HITL).
5. The 24 final user stories — atomic, de-jargoned, with stable numbering.
6. The on-chain requirements brainstorm — each story followed by its bulleted requirements list, organized around the `Policy` and `Intent` Anchor accounts.
7. Open questions handed forward to the smart-contract architecture assignment.

If you want to see the work behind the deliverable — which AI outputs I rejected, which I kept, why every story got split or merged — read `part-b-process-appendix.md`. It is structured to mirror the assignment's own Parts A through D so a grader can cross-check any claim in the deliverable against the prompt and reasoning that produced it.

## How to (re)build the PDF

```bash
./build.sh
```

Requires `pandoc` and a LaTeX engine (`xelatex` is the default). On macOS:

```bash
brew install pandoc
brew install --cask basictex   # or use the full mactex if you already have it
```

The script concatenates the two markdown files with a page break between them and writes the result to `dist/cordon-user-stories.pdf`. There is no other build state — `build.sh` is idempotent, the PDF is regenerable, and the two markdown files are the source of truth.

## How this was scoped

The assignment asks for personas, functions, stories, and on-chain requirements derived from the value prop in the previous assignment. I scoped everything to a single, named loop: an agent submits a transaction intent, the on-chain policy checks it, and either it auto-broadcasts or a human approver decides. Every persona in §2 of the deliverable, every function in §3, and every story in §5 either drives that loop or governs the rules behind it. Personas that consume the *outputs* of the loop (compliance officer, end user, regulator) are noted in the process appendix and deliberately excluded from the POC scope. The justification for each exclusion is in `part-b-process-appendix.md` §B.3.
