# Part A — User Stories & On-Chain Requirements

**Project:** Cordon — transaction firewall for Solana AI agents
**Author:** Janhavi Chavada · Turbin3 Builders Cohort
**Input document:** [`cordon-proposal.pdf`](https://github.com/Hijanhv/cordon) (Capstone Assignment 1)

This document is the clean, final deliverable. The process — prompts, AI outputs, my critiques, refinement log — lives in [`part-b-process-appendix.md`](./part-b-process-appendix.md).

---

## 1. Refined value proposition (one-line recap)

Cordon sits between an AI agent's signing path and the Solana network. Every transaction the agent wants to broadcast first gets simulated, then policy-checked against an on-chain Anchor program, then (when flagged) queued for a human approver before it ever hits the network. Policies, the approver set, and the kill switch live on-chain so a single operator can't quietly raise a cap or remove a control.

The POC has to prove **one loop end-to-end**: an agent's intent is intercepted, checked against on-chain policy, and either auto-broadcast or routed to a human approver who decides. Everything in this document is scoped to that loop.

---

## 2. Core user personas (final, 4)

The brainstorm produced ~12 candidate user types (see appendix B.2). Four made it through prioritization. The rest are either downstream consumers of POC outputs (compliance reader, end user of an agent-managed treasury, protocol risk manager) or post-POC stakeholders (insurance underwriter, regulator). They are not in the critical path for proving the loop works.

### P1 — Agent integrator
The developer who drops `cordon-rs` (or its TypeScript binding) into an agent codebase. Writes the initial policy, wires the agent's signing path through the SDK, points the dashboard at the right program ID. Primary buyer.

### P2 — Agent signer
The programmatic actor running inside the integrator's agent — the runtime entity that builds and submits transaction intents through the SDK. **Not** the same as the integrator: the integrator writes the agent's code; the agent signer is the running process whose intents Cordon intercepts. Drawing this line matters because the integrator has policy-mutation rights and the agent signer does not.

### P3 — Approver
A human (or, in production, a Squads multisig) listed in the policy's approver set. Watches the Next.js dashboard. Approves or rejects flagged intents.

### P4 — Policy authority
The on-chain owner of the policy registry account for a given agent. Mutates spend caps, allowlists, time windows, the approver set, and the kill switch. Day-1 default is the integrator's wallet; production target is a multisig or DAO. Distinct from the approver: the policy authority changes the rules; the approver applies them on a single pending transaction.

### Why these four and not more
The minimal cast that fully exercises the loop is: someone who configured it (P1 + P4), the actor whose intents get checked (P2), the human who decides on flagged ones (P3). Add a fifth and you're adding someone who reads outputs, not someone who drives the critical path. The cohort timeline doesn't have room for personas that don't shift the POC scope.

---

## 3. Function map

One concrete, single-action function per row. No "manages" or "configures" — those are categories, not actions.

### P1 — Agent integrator
| # | Function |
|---|---|
| F1.1 | Installs the Cordon SDK in their agent project |
| F1.2 | Generates the agent signer keypair the SDK will wrap |
| F1.3 | Calls `register_agent` on-chain to create the policy account |
| F1.4 | Reads the agent's pending-approval queue from the dashboard |
| F1.5 | Reads the on-chain audit log for their agent |

### P2 — Agent signer
| # | Function |
|---|---|
| F2.1 | Builds an intended Solana transaction |
| F2.2 | Submits the intent to Cordon for a policy check |
| F2.3 | Receives an auto-approval and broadcasts the original transaction |
| F2.4 | Receives a "queued for HITL" response and pauses |
| F2.5 | Receives a "policy denied" response and aborts |
| F2.6 | Receives an approver's decision on a previously queued intent |

### P3 — Approver
| # | Function |
|---|---|
| F3.1 | Connects their wallet to the dashboard |
| F3.2 | Views the pending-approval queue for an agent they're listed on |
| F3.3 | Opens a pending intent and reads the simulation output plus the policy reason it was flagged |
| F3.4 | Approves a pending intent |
| F3.5 | Rejects a pending intent |
| F3.6 | Views past decisions (their own and other approvers') |

### P4 — Policy authority
| # | Function |
|---|---|
| F4.1 | Sets the per-asset spend cap on the policy account |
| F4.2 | Adds a program ID to the CPI allowlist |
| F4.3 | Removes a program ID from the CPI allowlist |
| F4.4 | Adds an approver public key to the approver set |
| F4.5 | Removes an approver public key from the approver set |
| F4.6 | Flips the kill switch (pauses all of the agent's intents) |
| F4.7 | Transfers policy authority to a new wallet (e.g., a Squads multisig) |

---

## 4. Top critical user interactions for the POC

Two interaction paths. They share most of the on-chain machinery, so building one gets you most of the other.

### Path A — Auto-approval loop
The agent submits an intent. The on-chain policy check passes (under the spend cap, target program is on the allowlist, inside the time window, under the rate limit). The SDK broadcasts the original transaction. The decision is written to the on-chain log.

### Path B — HITL loop
The agent submits an intent. The on-chain policy check fails one or more rules. A `PendingApproval` account is created. The agent's submit call returns "queued." The approver sees the queued intent in the dashboard, opens it, and either approves or rejects. On approval, the SDK broadcasts. On rejection or expiry, the intent is dropped. Either way, the decision is written to the on-chain log.

These two paths cover every persona, every Cordon-side instruction the POC needs, and every account type. If both work end-to-end on devnet, the POC is done.

---

## 5. Final user stories (atomic, de-jargoned)

Output of Part C (full refinement log in appendix B.7). Each story is a single action, in plain language, with a clear actor and outcome. Numbering is stable so the on-chain requirements in §6 can reference back.

### Setup stories
- **S1.** As an integrator, I install the Cordon SDK in my agent's project.
- **S2.** As an integrator, I generate the keypair my agent will sign with.
- **S3.** As an integrator, I create my agent's on-chain policy account.
- **S4.** As a policy authority, I set the per-asset spend cap on the policy account.
- **S5.** As a policy authority, I add a target program to the allowlist.
- **S6.** As a policy authority, I add an approver's public key to the approver set.

### Runtime stories — auto-approval path
- **S7.** As an agent signer, I build a transaction I want to broadcast.
- **S8.** As an agent signer, I submit that transaction to Cordon for a policy check.
- **S9.** As Cordon, I record the intent on-chain so the decision is auditable.
- **S10.** As Cordon, I check the intent against the policy account's rules.
- **S11.** As Cordon, I mark the intent approved when every rule passes.
- **S12.** As an agent signer, I broadcast the original transaction once Cordon marks the intent approved.

### Runtime stories — HITL path
- **S13.** As Cordon, I mark the intent as pending when one or more rules fail.
- **S14.** As Cordon, I record the specific rule that triggered the pending state.
- **S15.** As an approver, I open the dashboard and see every pending intent on agents I'm listed on.
- **S16.** As an approver, I open a single pending intent and read its simulation output and the rule it tripped.
- **S17.** As an approver, I approve a pending intent.
- **S18.** As an approver, I reject a pending intent.
- **S19.** As an agent signer, I broadcast the original transaction once an approver marks the pending intent approved.
- **S20.** As an agent signer, I drop the transaction when an approver rejects it or the pending intent expires.

### Governance stories
- **S21.** As a policy authority, I flip the kill switch to pause every new intent for my agent.
- **S22.** As a policy authority, I transfer policy authority to a new wallet.

### Read stories
- **S23.** As an integrator, I read my agent's pending-approval queue.
- **S24.** As an integrator, I read my agent's on-chain decision log for a date range.

---

## 6. Potential on-chain requirements per story

Brainstorm output (Part D). Each story is followed by a bulleted list of on-chain needs. These are deliberately at the requirement level — not the implementation level — so the next assignment (smart-contract architecture) can decide between competing designs. "PDA" and "instruction" are used because Cordon is Anchor; that's not jargon at the requirements stage, it's the substrate.

Anchor program working name: `cordon_policy`. Two account types carry most of the state: `Policy` (one per agent, owns the rules and the approver set) and `Intent` (one per submitted transaction, owns its lifecycle).

### Setup

**S1 — Integrator installs the SDK**
- No on-chain requirements. Off-chain only (Cargo / npm).

**S2 — Integrator generates the agent signer keypair**
- No on-chain requirements at this step. The keypair only matters once it signs.

**S3 — Integrator creates the agent's policy account**
- Need a `register_agent` instruction.
- It creates a `Policy` PDA with seeds `[b"policy", agent_signer_pubkey]`.
- The `Policy` stores the policy authority's pubkey, the agent signer's pubkey, a `paused` flag (default `false`), a `bump`.
- The `Policy` initializes empty containers for the allowlist, approver set, and rule fields.
- The instruction fails if a `Policy` already exists for that agent signer.
- The instruction emits a `PolicyCreated` event for the audit log.

**S4 — Policy authority sets the spend cap**
- Need a `set_spend_cap` instruction.
- It mutates `Policy.spend_cap_lamports` (per-asset cap — for the POC, just SOL; extend per-mint later).
- It is gated on the signer matching `Policy.authority`.
- It emits a `PolicyChanged` event with the old and new cap.
- It fails if the `Policy` is paused (kill-switch state) so that paused policies can't be silently re-tuned.

**S5 — Policy authority adds a program to the allowlist**
- Need an `allowlist_add` instruction.
- It pushes a program ID onto `Policy.allowed_programs` (bounded vec, e.g. max 32 entries; size pre-allocated to avoid reallocation cost).
- It is gated on `Policy.authority`.
- It fails if the program ID is already on the list (idempotency / duplicate prevention).
- It emits a `PolicyChanged` event.

**S6 — Policy authority adds an approver**
- Need an `approver_add` instruction.
- It pushes a pubkey onto `Policy.approvers` (bounded vec, e.g. max 8).
- It is gated on `Policy.authority`.
- It fails if the pubkey is already in the set.
- It emits a `PolicyChanged` event.

### Auto-approval runtime path

**S7 — Agent signer builds a transaction**
- No on-chain requirements. The agent assembles the tx off-chain via the SDK.

**S8 — Agent signer submits the intent to Cordon**
- Need a `submit_intent` instruction.
- It creates an `Intent` PDA with seeds `[b"intent", agent_signer_pubkey, policy.nonce.to_le_bytes()]`, where `policy.nonce` is a monotonic counter on `Policy` (incremented atomically inside this instruction).
- The `Intent` stores a hash of the original transaction message (not the full tx — keeps account size bounded), the target program IDs the tx CPIs into, the lamports moved, the timestamp, the submitter, and a `status` enum (`Submitted`, `AutoApproved`, `Pending`, `HumanApproved`, `Rejected`, `Expired`).
- The signer must match `Policy.agent_signer`.
- The instruction fails if `Policy.paused` is `true` (kill switch honored at submission, not just at check).
- It emits an `IntentSubmitted` event.

**S9 — Cordon records the intent on-chain**
- Covered by S8 — the `Intent` account *is* the on-chain record. The append-only audit trail is the set of `Intent` accounts plus the event stream; no separate "log" account needed.

**S10 — Cordon checks the intent against the policy**
- Need a `check_intent` instruction (could be folded into `submit_intent` for the POC; kept separate here in case off-chain simulation needs to run between the two).
- It reads the `Intent` and the matching `Policy`.
- It evaluates: `lamports <= spend_cap`, every CPI target ∈ `allowed_programs`, current slot/clock is inside the time window, and the per-rate-limit-period count is under the cap (rate-limit counter is stored on `Policy` with a sliding window or a simple "count + window start").
- It writes `Intent.status` based on the result (`AutoApproved` or `Pending`).
- It writes `Intent.failure_reason` (a small enum: `OverCap`, `ProgramNotAllowed`, `OutsideTimeWindow`, `RateLimited`) when transitioning to `Pending`, so the dashboard can show *why* without recomputing.

**S11 — Cordon marks the intent approved when every rule passes**
- Covered by S10's state transition to `AutoApproved`.
- It emits an `IntentAutoApproved` event.

**S12 — Agent signer broadcasts the approved transaction**
- No additional on-chain requirements for the broadcast itself (broadcast is just sending the tx to RPC).
- Requires that the SDK can prove approval to itself before broadcasting; reading `Intent.status == AutoApproved` is sufficient.
- Optional hardening for later: a separate `release` instruction that burns the `Intent` account and returns rent to the integrator, called after broadcast confirms.

### HITL runtime path

**S13 — Cordon marks intent as pending when a rule fails**
- Covered by S10's state transition to `Pending`.
- It emits an `IntentPending` event with the rule that tripped it (the same data written to `Intent.failure_reason`).

**S14 — Cordon records which rule was tripped**
- Covered by S10 via `Intent.failure_reason`.

**S15 — Approver sees pending intents for agents they're on**
- No new on-chain instruction. The dashboard reads pending intents via `getProgramAccounts` with a memcmp filter on `Intent.status == Pending` plus a filter on `Intent.agent_signer ∈ {agents where this approver is in Policy.approvers}`.
- Requires `Intent` account layout to be memcmp-friendly: the `status` byte at a fixed, low offset; `agent_signer` at a fixed offset.

**S16 — Approver opens a single pending intent**
- No on-chain instruction. Read-only fetch of one `Intent` account, plus the matching `Policy` for context.
- Requires `Intent.failure_reason` and the cached lamports / CPI target list to be on the account (so the dashboard doesn't need to recompute or re-fetch the original tx to explain the flag).

**S17 — Approver approves a pending intent**
- Need an `approve_pending` instruction.
- It is gated on the signer being in `Policy.approvers`.
- It is gated on `Intent.status == Pending`.
- It transitions `Intent.status` to `HumanApproved`.
- It writes `Intent.approver` and `Intent.decided_at_slot`.
- It fails if the intent has expired (`current_slot > Intent.submitted_at_slot + Policy.pending_ttl_slots`); in that case the instruction transitions `Intent.status` to `Expired` instead.
- It emits an `IntentHumanApproved` event.
- (For the POC, single-signature approval is enough. Multi-signature approval — m-of-n on `Policy.approvers` — is a clean extension: store an approval bitmap on `Intent`, count signatures, transition state when the threshold is met.)

**S18 — Approver rejects a pending intent**
- Need a `reject_pending` instruction.
- Same gating as S17 (signer in `Policy.approvers`, status `Pending`).
- Transitions `Intent.status` to `Rejected`.
- Writes `Intent.approver`, `Intent.decided_at_slot`, and optionally a small `Intent.reject_reason` enum.
- Emits an `IntentRejected` event.

**S19 — Agent signer broadcasts after human approval**
- Same as S12. SDK reads `Intent.status == HumanApproved` before broadcasting.

**S20 — Agent signer drops the transaction on rejection or expiry**
- No on-chain instruction required. The SDK reads `Intent.status ∈ {Rejected, Expired}` and aborts.
- Requires the expiry semantics from S17 to be enforced *on-chain* at the next `approve_pending` / `reject_pending` call, OR an explicit `expire_intent` instruction that anyone can call. The latter is cleaner because it doesn't require waiting for the next approver action to garbage-collect.

### Governance

**S21 — Policy authority flips the kill switch**
- Need a `set_paused` instruction.
- It mutates `Policy.paused`.
- It is gated on `Policy.authority`.
- It emits a `PolicyChanged` event.
- It affects `submit_intent` (S8 fails when paused) and `set_spend_cap` (S4 fails when paused, so a compromised authority can't pause-then-loosen).
- Open question for the next assignment: should `approve_pending` also fail when paused? Argument for: kill switch is total. Argument against: an approver may want to reject queued intents while paused. Default to "approve fails, reject still works" — the kill switch should never block a *safer* action.

**S22 — Policy authority transfers authority**
- Need a `transfer_authority` instruction.
- It mutates `Policy.authority` to a new pubkey.
- It is gated on the current `Policy.authority`.
- Should be a two-step transfer (propose → accept) to avoid transferring authority to a pubkey nobody controls. Adds a `Policy.pending_authority` field.
- Emits a `PolicyChanged` event.

### Read stories

**S23 — Integrator reads the pending queue**
- No on-chain instruction. `getProgramAccounts` with a memcmp filter on `status == Pending` and `agent_signer == <theirs>`.
- Requires the account-layout property already noted in S15.

**S24 — Integrator reads the decision log for a date range**
- No on-chain instruction. The decision log is the set of `Intent` accounts with a terminal status (`AutoApproved`, `HumanApproved`, `Rejected`, `Expired`).
- Date-range filtering: `Intent.submitted_at_slot` is on the account; the SDK converts slot ranges to wall-clock via `getBlockTime`.
- For the POC this is acceptable; for production, the volume of `Intent` accounts will require either (a) a `release` instruction that closes terminal intents after archiving them off-chain to an indexer, or (b) a compression scheme. Out of scope for this assignment, flagged for architecture.

---

## 7. Open questions handed to the next assignment

These are the things I deliberately didn't decide here, because they belong in the architecture assignment (smart contract design and diagramming), not in requirements.

1. **Should `check_intent` be a separate instruction or folded into `submit_intent`?** Trade-off: separating it lets off-chain simulation happen between the two, but doubles the round trips. Likely fold them together for the POC and split if simulation needs the gap.
2. **Account size for the bounded vecs (allowlist, approvers).** Picked illustrative maxes (32 programs, 8 approvers); the architecture assignment should pick real ones based on rent cost and realistic fleet shapes.
3. **Rate-limit window representation.** Sliding window vs. fixed window vs. token bucket — each has different on-chain math. Picking one is an architecture call.
4. **Intent garbage collection.** Either a `release` instruction or some kind of compression. Required before mainnet, not required for the devnet POC.
5. **Squads integration for the approver path.** The persona definition assumes an approver could be a Squads multisig, but how Cordon verifies a Squads approval signature inside `approve_pending` is an architecture question, not a requirements one.
