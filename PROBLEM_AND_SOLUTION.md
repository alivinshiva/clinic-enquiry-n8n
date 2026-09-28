# The Problem and The Solution — Patient Enquiries at CityCare Dental Clinic

A short, plain-language case study. Read this one first if you want the
*why* before the *how*; the technical setup lives in `README.md`.

---

## The Problem

CityCare Dental Clinic (Pune) gets patient enquiries through its website form:

> *"How much does teeth whitening cost?"*
> *"I want to book a cleaning for Saturday."*
> *"I've had tooth sensitivity to hot and cold drinks for two weeks — should I come in?"*

Every message has to be **read, understood, and answered by a staff member**.
That sounds fine, until you look at what it actually costs the clinic:

1. **It's slow.** A simple price question can sit unanswered for a full
   working day. Nobody reads the form at night or on Sundays.
2. **It's inconsistent.** Two staff members can answer the same question with
   different prices and different words. Patients notice; trust erodes.
3. **Sensitive cases get generic treatment.** A patient describing two weeks
   of tooth pain deserves a careful human follow-up — not a rushed copy-paste
   reply. But when every message is handled the same way, that's what happens.
4. **There's no single record.** Enquiries live in someone's inbox. "Did we
   ever respond to this patient?" is genuinely hard to answer.

**In short:** the clinic needed a way to answer routine questions instantly and
consistently, flag sensitive ones for a human, never lose an enquiry, and never
invent a fact it isn't sure of.

---

## The Solution

An **always-on automation built in n8n** that sits in front of the enquiry form
and does five things:

| # | Step | What it does |
|---|---|---|
| 1 | **Validate** | Keeps bad submissions out — e.g. a phone number that can't be real is rejected politely with a clear message. |
| 2 | **Log** | Every valid enquiry is written to a **Google Sheet** with a timestamp — the single record the clinic was missing. |
| 3 | **Classify** | An **AI reads the message** and tags it: category (booking / billing / health / complaint / other) + urgency (high / medium / low). |
| 4 | **Route** | Routine categories get an **instant, personalised reply email**; health questions and complaints are **emailed to the staff** for manual handling; anything urgent triggers an **immediate alert** on top. |
| 5 | **Protect** | The replying AI is only allowed to answer from the clinic's **real facts** (prices, hours, address — kept in a second sheet), says *"I don't have that information, please call"* when something isn't covered, and if anything fails twice it is **logged to a Failures sheet**, not lost. |

### How one enquiry travels through the system

```
Patient form  (POST /webhook/enquiry)
      │
      ▼
  Validate ── bad? ──▶ 400 "invalid phone number", nothing logged
      │ valid
      ▼
  Log row to Sheet1 (timestamp, name, phone, email, question)
      │
      ▼
  AI classify → category + urgency
      │
      ├── appointment / billing ──────────▶ read Clinic Info facts
      │        │                            │
      │        ▼                            ▼
      │        AI writes reply (facts only) → email patient → log "auto-replied"
      │
      ├── medical / complaint ────────────▶ email staff summary → log "manual handling"
      │
      └── (any) high urgency ─────────────▶ extra "URGENT ALERT" email
```

### Why it's safe (not just fast)

- **Grounded answers.** The reply AI can *only* use the clinic's facts sheet.
  Asked about a service the clinic doesn't list, it says so and offers a
  callback — it never guesses a price. We verified this live: asked about
  dental implants (not a listed service), it replied: *"I do not have
  information regarding dental implants... please call the clinic or request a
  callback."*
- **Handles the machine misbehaving.** If the AI call returns nothing, the
  enquiry is safely routed to staff. If a reply or email fails, it tries once
  more, then writes the problem to the **Failures** tab. No silent drops.
- **Validation at the door.** Bad phone numbers get a clean rejection and
  never enter the log.

---

## What changed

| Before | After |
|---|---|
| Patient waits a working day for an answer | Routine questions answered **in seconds**, 24/7 |
| Same question, different answers | Every reply grounded in one facts sheet |
| Health questions answered like spam | Sensitive cases **always go to a human** |
| No record of enquiries | Every enquiry + action in one spreadsheet |
| Failures happen silently | Retry once, then logged to a Failures sheet |

---

## Real verification

The flow was tested end-to-end and the results are reproducible with the
`curl` requests in `TEST_POST_REQUESTS.md`:

- Billing question → patient email quoting **INR 6000** and **Sundays
  10:00–14:00** (both figures from the clinic facts, not the model).
- Implants (not offered) → refusal + callback offer, **no invented price**.
- Pain/sensitivity → **no** auto-reply; staff email + `manual handling` log.
- Complaint → staff email + `manual handling` log.
- High-urgency enquiry → extra `URGENT ALERT` email.
- Invalid phone → HTTP 400, nothing logged.

---

## Roadmap — what's next

1. **Make the auto-branch faster with TypeSafe Jev.** Classification doesn't
   need to *write* anything — it needs a decision. Jev
   (`typesafe-ai/jev`, `POST https://api.typesafe.ai/v1/systemone`) is a typed
   decision model that returns `category` and `urgency` with probabilities in
   **~70–500 ms**, with no JSON parsing or cleanup step. That would remove the
   classification call's latency and its fallback branch entirely; the
   generative model stays only to write the grounded patient reply.
2. **Answer the webhook immediately**, then email + log in the background, so
   the caller never waits on the AI.
3. **Stage 5:** block exact duplicates within 10 minutes and email a 9 AM
   daily summary by category.
4. **Sharper classification:** cut the occasional mis-tag by routing decisions
   through a typed model (or a stronger model) and sending low-confidence
   results to staff.
5. **Production activation:** turn on the production webhook and run on an
   always-on instance when the real clinic form goes live.

The implementation details, spreadsheet setup, credentials, and test requests
are all in this repository — start with `README.md`.