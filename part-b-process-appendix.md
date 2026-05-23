# Part B — Process Appendix

The clean deliverable is in [`part-a-deliverable.md`](./part-a-deliverable.md). This file is how I got there: every AI prompt I ran, the synthesized output, the parts I agreed with, the parts I overrode, and the explicit before/after refinement log for the Part C atomicity pass. The structure mirrors the assignment's own Parts A through D so a grader can cross-check any claim in the deliverable against the reasoning that produced it.

## B.1 — Inputs

The single input is the refined project proposal from Capstone Assignment 1 (`cordon-proposal.pdf` at the root of this repo). I'm not redoing the market analysis here — it's settled — but the value prop is the constraint everything in this assignment has to map back to. Quoting it verbatim from §1 of that proposal so a grader doesn't have to flip files:

> Cordon is the policy enforcement and HITL approval layer that sits between an AI agent's intent and the Solana network. You drop the Rust SDK (`cordon-rs`) or its TypeScript binding into any agent built on SendAI Agent Kit, Arc, or a custom Rig pipeline. You write your policies once into an Anchor program: per-asset spend caps, an allowlist of programs the agent can CPI into, time-of-day windows, rate limits, daily volume ceilings, anomaly thresholds. Anything the policy doesn't auto-approve gets pushed to a Next.js dashboard where authorized signers approve or reject before the agent broadcasts.

Three target user *segments* came out of that assignment: agent dev teams (primary), hackathon teams (beachhead), and protocols / DAOs (expansion). This assignment narrows from segments to **personas inside one agent deployment**, which is a different cut.

---

## B.2 — Manual brainstorm of user types (Part A.1)

Before prompting the AI, I wrote down every user type that could plausibly interact with a single Cordon deployment, by the four categories the assignment asks for.

### Direct users
- **Agent integrator** — the developer installing the SDK into their agent codebase.
- **Agent signer** — the programmatic actor inside the agent that builds and submits transactions.
- **Approver** — the human reviewing flagged intents in the dashboard.
- **Policy author** — the person writing the policy rules. (Often the integrator on day 1.)
- **Policy authority** — the on-chain owner of the policy registry account (often a multisig).

### Indirect users / beneficiaries
- **End user of an agent-managed treasury** — e.g. a DAO member whose funds the agent manages. Doesn't touch Cordon directly but benefits when a bad intent gets blocked.
- **Token holders of a DAO whose treasury is agent-managed** — same as above but at protocol level.
- **Protocol risk manager** — at Drift, Jupiter, Kamino, etc. — wants to know the agents integrating with their protocol have firewalls in front of them.

### Administrators / moderators
- **Cordon platform operator (me)** — running the free hosted tier of the dashboard.
- **Compliance officer / auditor** — at an enterprise running Cordon, reads the on-chain audit log to verify controls.
- **Incident responder** — during a live security event, needs to pause an agent fast.

### Stakeholders
- **Founder / engineering lead** at the agent dev company — owns the buying decision.
- **Insurance underwriter** — would underwrite agent operations differently with Cordon in front of them.
- **Regulator** — cares about the audit log existing, not about using Cordon directly.
- **Integration partners** — Squads (HITL signing target), SendAI (host for Cordon as a plugin).

Twelve user types total. This is the input to the prioritization step.

---

## B.3 — AI prioritization prompt (Part A.2)

**My prompt:**

> My project's value proposition is: Cordon is a policy enforcement and HITL approval layer for AI agents on Solana. The SDK intercepts every transaction the agent wants to broadcast, checks it against an on-chain Anchor policy program (spend caps, CPI allowlist, time windows, rate limits), and routes flagged transactions to a human approver in a Next.js dashboard. Policies and the approver set live on-chain, owned by an authority that can be a multisig or DAO.
>
> Here is a brainstormed list of all potential user types: [pasted the 12 from B.2 verbatim].
>
> Based on the value proposition, which 2–5 of these user types are the most critical to focus on for an initial Proof-of-Concept? For each user you recommend, provide a brief rationale.

**Synthesized AI output:**

The AI recommended five: agent integrator, agent signer, approver, policy authority, and compliance officer. Its rationales for the first four were essentially what I'd written myself. Its rationale for the compliance officer was "they validate the audit log property of the system, which is a core value area."

**My take and final decision:**

I kept four of the five and dropped compliance officer. They read outputs the other four already produce; they don't drive the loop. Including them as a POC persona would add a story like "compliance officer queries the audit log for a date range" that only makes sense once every other persona's stories work. That's scope inflation without proving anything new — same reasoning I used in the prior assignment when I demoted enterprise from primary to secondary.

I also collapsed "policy author" and "policy authority" from my brainstorm into one persona (P4). On day 1 they're the same person. The distinction (someone who *drafts* policy text vs. someone who *signs the on-chain mutation*) only matters once there's a review process between drafting and signing, and a single capstone deployment isn't going to have that.

Final four personas: P1 integrator, P2 agent signer, P3 approver, P4 policy authority. Documented in deliverable §2.

**Where I disagreed with the AI:** the compliance officer call. Not because the persona is wrong — it's because they're a consumer of outputs, not a driver of the loop, and the POC scope has to stop at what proves the loop.

**Where I agreed:** the disambiguation between integrator (writes code) and agent signer (runs code). The AI's framing here was sharper than my brainstorm draft and I kept it verbatim.

---

## B.4 — Function mapping prompt (Part A.3)

**My prompt:**

> For Cordon (value prop above) and focusing on these four prioritized user types — integrator, agent signer, approver, policy authority — help map out the key functions or interactions each user would need to perform. Keep functions concrete and single-action; avoid wrapper verbs like "manage" or "configure."

**Synthesized AI output:**

A function map roughly matching the table in deliverable §3, with these differences:

- The AI gave the integrator a function "monitors agent activity" — I dropped it. "Monitors" is a category, not an action. I broke the underlying need into F1.4 (read pending queue) and F1.5 (read audit log), which are concrete.
- The AI gave the agent signer a single function "submits transactions and handles responses." I split it into F2.1–F2.6 because the response handling has three distinct branches (auto-approved, queued, denied) and the queued branch has a second event (approver decision) that arrives later.
- The AI did not include the kill switch (F4.6) or the authority transfer (F4.7). I added both manually. The kill switch is the single most important governance function — without it the "operator can't quietly mutate policy" value claim doesn't hold. The authority transfer is the mechanism that makes "policy authority can be a multisig or DAO" a real property, not just a slogan.
- The AI grouped "add approver" and "remove approver" into one function. I split them (F4.4 / F4.5) because they're two distinct on-chain instructions with distinct gating concerns.

The AI's wrapper-verb tendency is a real anti-pattern for this exercise. Functions like "manages policies" are useless input for translating into on-chain instructions because they don't correspond to a single instruction call.

---

## B.5 — Top critical interactions and initial technical requirements (Part A.4)

I identified the two paths in deliverable §4 manually first (auto-approval loop, HITL loop), then prompted the AI for technical requirements.

**My prompt:**

> Based on these two critical user interactions for Cordon — (Path A) agent submits intent, policy auto-approves under cap, transaction broadcasts; (Path B) agent submits intent, policy flags it, approver decides — what are the key technical requirements to build a POC on Solana / Anchor?

**Synthesized AI output:**

- An Anchor program with instructions for registering an agent, submitting an intent, checking the intent against policy, approving, and rejecting.
- A `Policy` account per agent storing the rules and the approver set.
- A `PendingApproval` (the AI's name; I renamed to `Intent`) account per submitted transaction.
- An off-chain SDK that wraps the agent's signing path through these instructions.
- A dashboard that queries pending intents via `getProgramAccounts` with a memcmp filter.
- An on-chain event stream for the audit log.

**My take:**

This is correct and matches what I'd already sketched in the Cordon repo. The substantive edit I made was renaming `PendingApproval` → `Intent` and making one account hold the *full intent lifecycle*, not just the pending state. The reason: if "pending" and "approved" are two different account types, the audit log becomes a union of two queries against two different layouts. With one `Intent` account that progresses through a status enum (`Submitted → AutoApproved | Pending → HumanApproved | Rejected | Expired`), the audit log is one query against one account type, filterable by status. Cheaper to index, simpler to reason about, and `getProgramAccounts` with a memcmp on `status` gives the dashboard the pending queue and the historical log from the same code path.

The AI also missed an interaction I caught manually: the kill switch has to disable `set_spend_cap`, not just `submit_intent`. Otherwise a compromised authority can pause the agent, quietly loosen the cap, then unpause — which defeats the entire point of having a kill switch. I propagated that constraint into S4 and S21 in the deliverable.

---

## B.6 — Adversarial critique (Part B)

**My prompt:**

> Review my core user functions / stories (deliverable §3 and §5 draft) and requirements (§6 draft). Considering Cordon's value prop, do these stories truly hit the mark? Are the requirements granular enough to map to specific Anchor instructions, account types, and PDA seeds? What's missing or unclear?

**Synthesized critique:**

1. **"Agent" is ambiguous.** The stories sometimes say "agent" when they mean the integrator and sometimes when they mean the runtime signer. Force a disambiguation across every story.
2. **No story for the expiry case.** What happens if an intent sits in the queue past the TTL and no approver acts? The stories cover approve and reject but not expire.
3. **No story for the authority-transfer.** The persona is defined but the function isn't reified as a story.
4. **The audit log is implied, not stated.** "Cordon records the intent on-chain" appears nowhere as a numbered story; it's only implicit in S8.
5. **Setup stories conflate steps.** "Integrator installs Cordon and configures their agent" is three actions: SDK install, keypair generation, policy creation.
6. **No read stories.** The deliverable has write stories (mutating on-chain state) but no read stories (querying it). The dashboard and the SDK both need read paths.
7. **Rate limiting is hand-waved.** "Under the rate limit" is in the policy check but isn't grounded — what's the window, where is the counter stored?

**My response, item by item:**

1. **Took it.** "Agent" was doing two jobs and that was on me. I renamed across the whole deliverable: "agent integrator" is the off-chain code-writer (P1); "agent signer" is the runtime programmatic actor (P2). Every story now names one or the other.
2. **Took it.** Added S20 (drop on rejection or expiry) and wrote explicit `Intent.status == Expired` handling into S17. Also added the optional `expire_intent` instruction inside S20's requirements so dead intents can be garbage-collected without waiting for the next approver action.
3. **Took it.** Added S22 (transfer authority) with a two-step propose-then-accept mechanism so a typo can't strand the policy authority on a pubkey nobody controls.
4. **Partially took it.** I added S9 ("Cordon records the intent on-chain so the decision is auditable") as a named story for legibility. But in the requirements I noted S9 is *covered by* S8 — the `Intent` account IS the on-chain record, there's no separate log. The critique's instinct was right that the audit property needed to be named explicitly. The implementation collapses to one account type, not two.
5. **Took it.** Setup stories S1 through S6 are the split-out form. The original draft had one mega-story; refinement log entry C1 below has the before/after.
6. **Took it.** Added S23 (read pending queue) and S24 (read decision log). These forced a real account-layout requirement to surface — the `status` byte and `agent_signer` pubkey both need to sit at fixed, low offsets so `getProgramAccounts` memcmp filters are cheap. Without the read stories, that constraint would have shown up too late.
7. **Acknowledged, deferred.** The rate-limit window question is real (sliding window vs. fixed window vs. token bucket each have different on-chain math). But at the requirements stage it's enough to say the policy check evaluates a rate limit. Picking the window representation is an architecture call. Flagged in deliverable §7 #3.

**The critique I rejected.** An early version of the critique also pushed for a story where "the approver asks the agent for more information before deciding." It's a real product feature for a v2, but it's not a POC requirement — for the POC the approver decides on the simulation output already attached to the `Intent`. Adding a request-info loop would require an off-chain channel (Slack, email, webhook) the POC doesn't have, and the assignment is explicit about staying on-chain. Logged as post-POC; not in the story list.

---

## B.7 — Part C refinement log (granularity, atomicity, de-jargon)

Every change to a user story between the post-critique draft and the final §5 list, with before / after / rationale.

### C1 — Atomicity split
- **Before:** "As an integrator, I install Cordon and set up my agent's policy."
- **After:** S1 (install SDK) + S2 (generate keypair) + S3 (create policy account) + S4 (set spend cap) + S5 (add allowlist entry) + S6 (add approver).
- **Rationale:** Original was six distinct actions in one sentence. Each maps to a different on-chain instruction (S3 → `register_agent`, S4 → `set_spend_cap`, etc.) or to no on-chain action at all (S1, S2 are off-chain). Splitting lets each on-chain requirement attach to one story.

### C2 — Atomicity split on the runtime path
- **Before:** "As an agent, I submit a transaction and Cordon checks it and either it goes through or it gets queued."
- **After:** S7 (build tx) + S8 (submit intent) + S9 (Cordon records intent) + S10 (Cordon checks against policy) + S11 (mark auto-approved) + S12 (broadcast).
- **Rationale:** Original collapsed four distinct on-chain state transitions and one off-chain broadcast. The dashboard's audit log query depends on each transition being its own story so that "what happened to intent X" can be read off the `Intent.status` history.

### C3 — Actor disambiguation
- **Before:** "As an agent, I submit my transaction to Cordon."
- **After:** "As an agent signer, I submit that transaction to Cordon for a policy check." (S8)
- **Rationale:** "Agent" was ambiguous (see B.6 #1). The runtime signer is the actor; the integrator is the configurer.

### C4 — De-jargon
- **Before:** "As Cordon, I invoke the `check_intent` CPI against the policy program and mutate `Intent.status` based on the result."
- **After:** "As Cordon, I check the intent against the policy account's rules." (S10)
- **Rationale:** "CPI" and "mutate state" are implementation language. The story should describe the action; the on-chain requirements (deliverable §6 under S10) can name the instruction and the state transition.

### C5 — De-jargon
- **Before:** "As an approver, I see the pending intents that match my pubkey in the approver set via a `getProgramAccounts` query with a memcmp filter."
- **After:** "As an approver, I open the dashboard and see every pending intent on agents I'm listed on." (S15)
- **Rationale:** The user story describes the user's experience; the requirements document describes the query mechanism. Kept the `getProgramAccounts` / memcmp detail in §6 under S15 where it belongs.

### C6 — Atomicity split on approver action
- **Before:** "As an approver, I review a pending intent and either approve or reject it."
- **After:** S16 (open and read details) + S17 (approve) + S18 (reject).
- **Rationale:** Approve and reject are different on-chain instructions with different post-conditions. Opening the intent to read it is a third distinct action (no on-chain write). Three stories, three different requirements.

### C7 — Missing story added
- **Before:** [no story]
- **After:** S20 ("As an agent signer, I drop the transaction when an approver rejects it or the pending intent expires.")
- **Rationale:** The rejection and expiry paths were implicit in the design but absent from the story list. Without the story, the on-chain `expire_intent` requirement had nowhere to attach.

### C8 — Missing story added
- **Before:** [no story]
- **After:** S21 (kill switch), S22 (transfer authority)
- **Rationale:** P4's most important functions (F4.6, F4.7) had no corresponding stories. Without stories, no on-chain requirements would have been brainstormed in Part D. Added.

### C9 — Read stories added
- **Before:** [no stories — only write paths]
- **After:** S23 (read pending queue), S24 (read decision log)
- **Rationale:** Critique #6. The on-chain account layout has read-side requirements (memcmp-friendly offsets) that only emerge if you write the read stories down.

### C10 — Redundancy elimination
- **Before:** Earlier draft had both "As Cordon, I write the intent to the audit log" and "As Cordon, I record the intent on-chain so the decision is auditable."
- **After:** Single story S9.
- **Rationale:** Same action described twice. The audit log *is* the on-chain record; there is no separate log account (see B.6 #4).

### C11 — De-jargon
- **Before:** "As a policy authority, I rotate the kill switch on the policy registry."
- **After:** "As a policy authority, I flip the kill switch to pause every new intent for my agent." (S21)
- **Rationale:** "Rotate" was the wrong verb (rotation implies key rotation). "Flip" is plain. Added the *consequence* ("pause every new intent for my agent") so a non-technical reader understands what the action does.

### C12 — De-jargon
- **Before:** "As a policy authority, I transfer ownership of the `Policy` PDA to a new authority pubkey."
- **After:** "As a policy authority, I transfer policy authority to a new wallet." (S22)
- **Rationale:** "PDA" and "pubkey" are Solana-specific. "Policy authority" and "wallet" are the same idea in user-facing language.

---

## B.8 — Part D approach notes

The deliverable §6 brainstorm follows the assignment's prescribed pattern (one story → bulleted on-chain requirements), but two patterns are worth flagging because they shaped a lot of the bullets:

**1. "No on-chain requirements" is a valid bullet.** Several stories (S1, S2, S7, S12, S15, S16, S19, S20, S23, S24) are off-chain or read-only. I marked them explicitly rather than inventing on-chain machinery to fill space. A story that doesn't need an instruction shouldn't get one.

**2. Several stories collapse into one instruction with state transitions.** S8 + S9 + S10 + S11 all describe the lifecycle of one `Intent` account. The requirements list reflects that — `submit_intent` covers S8 and S9; `check_intent` (or the folded version inside `submit_intent`) covers S10 and S11. I noted the open question in §7 (#1) rather than pretending the architecture decision was already made.

**3. Validation and gating are first-class requirements, not afterthoughts.** Every mutation instruction has a gating bullet (who can sign) and at least one failure bullet (when it must fail). This is the granularity needed to map to Anchor account constraints (`has_one`, `constraint = ...`) without ambiguity in the next assignment.

---

## Appendix — Sources

- Capstone Assignment 1 (Cordon proposal): `cordon-proposal.pdf` at repo root.
- Cordon code-in-progress: <https://github.com/Hijanhv/cordon>
- Anchor framework reference (PDA seeds, account constraints, instruction signatures): <https://www.anchor-lang.com/>
- Solana `getProgramAccounts` + memcmp filter docs: <https://solana.com/docs/rpc/http/getprogramaccounts>
