# CityCare Clinic — Enquiry Automation (n8n)

> Everything you need to read, understand and EXPLAIN this project to anyone —
> including people who have never seen n8n or Google Sheets.
> Written in plain language. A "TL;DR" first; the deeper details come after.

---

## 1. TL;DR — what is this project?

A dental clinic (fictional, used as a case study) receives enquiries from patients
through its website form — things like *"how much does teeth whitening cost?"*,
*"I want to book for Saturday"*, or *"my tooth hurts, should I come in?"*.

Today a human has to read every message, decide what it's about, and reply.
That is slow and easy to get wrong.

**This project automates that:** when a patient submits an enquiry, a small
automation service (n8n) instantly:

1. **Checks the message** is valid (has a name, a proper phone number, etc.)
2. **Records** it in a Google Sheet (a "log" of every enquiry)
3. **Asks an AI** to classify it — is it a booking? a billing question? a
   health question? a complaint? — and how urgent it is
4. **Replies automatically** when it's safe to do so (bookings & billing),
   using ONLY the clinic's real information
5. **Sends a note to the staff** for anything sensitive (health questions,
   complaints) so a human handles it
6. **Raises an alert** for anything urgent
7. **Never makes things up** — if the AI doesn't know, it says so and offers a
   call-back
8. **Never dies silently** — if a part fails, it tries once more and then logs
   the problem to a separate sheet

---

## 2. The problem (in client-friendly language)

The clinic gets enquiries through its website form. Every single one has to be
read, understood, and answered by hand. That means:

- Patients **wait** for an answer (sometimes for hours or a day).
- Simple questions (prices, opening hours, bookings) eat up staff time.
- Answers can be **inconsistent** (different staff give different prices).
- Nobody is around at night or on weekends.

The clinic wanted: **fast, consistent, always-on replies for routine questions,
and human review for anything sensitive.**

---

## 3. The solution (what we built)

We built a **workflow** (a visual automation) in **n8n** — a tool that connects
apps together without writing a program. The workflow is triggered by the
clinic's web form, and does the whole capture → classify → route → reply
journey automatically.

The three "systems" it connects:

| System | What it does here |
|---|---|
| **n8n** (self-hosted in Docker) | The automation brain — glue between everything |
| **Google Sheets** | Stores every enquiry + the clinic's facts + problems |
| **Gmail (SMTP)** | Sends the automated reply emails + alerts |
| **Groq (AI model)** | Classifies the message and writes the reply |

---

## 4. How it works — an enquiry's journey, step by step

Follow what happens when a patient submits the form:

```
Patient submits form
   │
   ▼
[1] Webhook  ──── receives the message
   │
   ▼
[2] Validate  ──── is name + a valid 10-digit Indian phone present?
   │ YES                    │ NO
   ▼                        ▼
[3] Save to sheet    Reject politely with the reason (400)
   │
   ▼
[4] AI classify  ──── category (appointment / billing / medical_query /
   │                 complaint / other) + urgency (high / medium / low)
   │
   ▼
[5] Route
   │
   ├── BOOKING or BILLING  ──►  read Clinic Info sheet
   │                              │
   │                              ▼
   │                         AI writes a personalised reply
   │                         (only from real clinic facts)
   │                              │
   │                              ▼
   │                         Email the patient
   │                              │
   │                              ▼
   │                         Log "auto-replied" in the sheet
   │
   ├── MEDICAL QUESTION or COMPLAINT  ──►  email a summary to staff
   │                                       for manual handling
   │                                       │
   │                                       ▼
   │                                       Log "manual handling"
   │
   └── URGENT (any type)  ──►  ALSO fire an immediate alert email to staff
```

### The grounding rule (the important safety bit)
The AI that writes patient replies is shown the clinic's **real facts**
(timings, fees, address, services — stored in the "Clinic Info" sheet).
It is told: *answer only from these facts; if the question is not covered, say
so and offer a call-back.* It must **never invent** a price or a service.

Real example: when asked about *dental implants* (not on the clinic's list),
the AI replied: *"I do not have information regarding whether we offer dental
implants... please feel free to call the clinic or request a callback."* — no
made-up answer.

### The safety nets (error handling)
- If the **AI call fails**, the enquiry is still handled — it is quietly
  routed to the staff for manual handling (safest option), and the problem is
  logged.
- If the **reply generation** fails, the workflow **tries once more**, and if
  it still fails it logs the failure and returns a clean "we're on it" answer.
- If an **email fails to send**, it retries once, then logs to the
  "Failures" sheet instead of crashing silently.

---

## 5. The stages of the build — status

The clinic brief defined 5 increasing-difficulty stages. We used those as
our checklist.

| Stage | What it asks | Status |
|---|---|---|
| **1 — Capture & store** | Webhook that takes name/phone/email/enquiry; validate (reject bad data with a clear error); append every valid enquiry to a Google Sheet with a timestamp | ✅ Done |
| **2 — AI classification** | AI returns JSON with category / urgency / one-line summary; parse it; write each to its own column; don't crash on messy AI output | ✅ Done |
| **3 — Conditional routing** | Route by category AND urgency (not one rule): medical/complaint → staff email; appointment/billing → personalised reply email; high urgency → additional alert; log the action taken | ✅ Done |
| **4 — Grounding & errors** | Replying AI uses only real clinic info (read from a second sheet); refuses + offers callback when not covered; retry once on AI/email failure, then log failures to a separate sheet | ✅ Done |
| **5 — Stretch (optional)** | Block duplicate submissions within 10 minutes; send a daily 9 AM summary of yesterday's enquiries by category | 🔜 Roadmap |

---

## 6. The spreadsheet — three tabs

The whole thing is driven by **one Google Spreadsheet** ("Clinic Enquiries")
with three tabs:

**Tab 1: Sheet1 — the enquiry log.** One row per enquiry.
Columns: timestamp, name, phone, email, enquiry_text, valid, error_message,
category, urgency, summary, action, action_timestamp.

**Tab 2: Clinic Info — the facts the AI is allowed to use.**
Two columns: `key` | `value`. Rows like:

| key | value |
|---|---|
| clinic_name | CityCare Dental Clinic |
| address | 12 MG Road, Shivaji Nagar, Pune - 411005 |
| phone | +91-9822-045678 |
| timings | Mon-Sat 9:30-19:00, Sun 10:00-14:00 |
| consultation_fee | INR 500 |
| cleaning_fee | INR 1000 |
| whitening_fee | INR 6000 |
| root_canal_fee | from INR 4500 |
| xray_fee | INR 300 |
| services | Consultation, Dental cleaning and polishing, Teeth whitening, Root canal treatment, Crowns and bridges, Dental X-rays, Extractions |
| booking_note | Book through this form; we confirm by return email or call within one working day |

**Tab 3: Failures — the problem log.** Filled automatically when something
fails twice.
Columns: timestamp, node, message, retried, data.

---

## 7. The tooling / tech stack

| Layer | Choice | Why |
|---|---|---|
| Automation platform | **n8n** (self-hosted, Docker on the user's machine / OrbStack) | Free, visual, runs the workflow directly from the machine |
| AI provider | **Groq** (model `qwen/qwen3.8-27b`, very fast) | Fast, cheap, good structured-JSON output |
| Web form intake | **n8n Webhook** (POST endpoint `/webhook-test/enquiry` in test mode) | Stands in for the clinic's website form |
| Data store | **Google Sheets** (via Google account OAuth) | The client already uses Google Workspace |
| Email | **Gmail SMTP** using a Gmail App Password | Sends from `driftershots@gmail.com` |

Credentials (Google, Groq, SMTP) are stored **inside n8n** — they are NOT
visible in the workflow or in these notes.

---

## 8. Tests we actually ran (real results)

These are the exact cases we used to prove the workflow works end-to-end.
They are also the demo script for the screen recording.

### Test A — Booking/billing question → auto-reply
Payload:
```
POST /webhook-test/enquiry
{
  "name": "Kavita Menon",
  "phone": "9765432109",
  "email": "driftershots@gmail.com",
  "enquiry_text": "How much does teeth whitening cost and what are your opening hours on Sundays?"
}
```
Result: response `{"received":true,"message":"Enquiry recorded"}`; the patient
email body (real) was:

> *"Dear Kavita Menon, teeth whitening at CityCare Dental Clinic is priced at
> INR 6000, and we are open on Sundays from 10:00 to 14:00…"*

Both figures come from the **Clinic Info sheet** — that's grounding working.
Sheet row logged: `category: billing`, `action: auto-replied`.

### Test B — Question NOT covered → refuse + call-back
Payload:
```
{ "name": "Faisal Khan", "phone": "9012345678", "email": "driftershots@gmail.com",
  "enquiry_text": "Do you offer dental implants and how much per tooth?" }
```
Result (real): the AI replied it has **no information** on implants, invited
the patient to **call or request a callback**. No invented price. ✅

### Test C — Health question → staff handles it
Payload:
```
{ "name": "Vikram Rao", "phone": "9955123467", "email": "driftershots@gmail.com",
  "enquiry_text": "I have tooth sensitivity to hot and cold drinks for two weeks. Should I come for a check-up?" }
```
Result: response `"Handled"`; a staff-notification email was sent with the
summary; sheet row logged `category: medical_query`, `action: manual handling`.

### Test D — Invalid data → clean rejection
Payload (phone `555-0102` is not a valid Indian mobile):
```
{ "name": "Jane Smith", "phone": "555-0102", "email": "jane@test.com",
  "enquiry_text": "Book a cleaning" }
```
Result: HTTP **400** with `{"error": "Phone number must be a valid 10-digit
Indian mobile number."}` — rejected, not persisted.

---

## 9. Live demo cookbook (for the screen recording)

A clean 5–8 minute demo:

1. **Show the spreadsheet** — three tabs (log, clinic facts, failures).
2. **Show the n8n workflow canvas** — point at the flow: *form → check →
   sheet → AI → route → reply/log*.
3. Click **Listen for test event**, run **Test A** (booking) → show the
   patient email arrive with the correct price/hours, and the sheet row
   (`auto-replied`).
4. Run **Test B** (implants) → show the "we don't have that / call us" reply.
5. Run **Test C** (pain/sensitivity) → show the **manual-handling** case:
   staff email + `manual handling` row. *(Include a manual-handling case — it proves the routing works.)*
6. Run **Test D** (bad phone) → show the clean 400 rejection.
7. Optionally: show a row landing in the **Failures** tab (explain "if
   something fails twice, it lands here instead of dying silently").

---

## 10. Roadmap — what's next

The project is complete for its scope; these are the natural next steps,
in priority order:

1. **Sharper, faster classification** — replace the generative classification
   call with a typed decision model (TypeSafe Jev, `typesafe-ai/jev`,
   `POST https://api.typesafe.ai/v1/systemone`) that returns `category` +
   `urgency` with probabilities in ~70–500 ms, and send anything below a
   confidence threshold to staff.
2. **Stage 5 — duplicates + daily summary** — block duplicate submissions within
   10 minutes and email a 9 AM summary of the previous day's enquiries by category.
3. **Production activation** — switch the webhook to Production mode and run on
   an always-on instance when the real clinic form goes live (the repo runs
   against the test listener so it is safe to share).
4. **Before the walkthrough video**, record the failure path once on film — the
   retry-then-log safety nets are built in and exercised live, but a dedicated
   clip makes the reliability story tangible.

---

## 11. Things that tripped us up (useful if you get asked)

- n8n's **email node body parameter is `text`**, not `message` — using the
  wrong name sends emails with empty bodies.
- Google Sheets nodes reference sheets by **ID (gid)**, not by tab name — a
  freshly imported workflow loses the tab link and must be re-picked once.
- In n8n, a code node can only safely read the output of a node **directly
  upstream of it** — referencing a distant node in expressions throws
  "node not executed" errors; we fixed by reading from a nearby parent node.
- The AI's **reply text sits in `$json.text`**, not `$json.output.text` — we
  had to make our checks accept several possible shapes so they don't break
  with model changes.

---

## 12. Suggested presentation outline (7 slides, 8–10 min)

A suggested structure; each bullet is a talking point in one plain sentence:

1. **The problem** — a clinic reads/replies to every form enquiry by hand:
   slow, inconsistent, no after-hours coverage.
2. **Our solution** — an always-on automation: it captures, classifies, and
   replies to routine enquiries instantly, and hands sensitive ones to staff.
3. **How it works** — (show a screenshot/diagram) form → validation → log →
   AI classification → routing → reply with real clinic facts.
4. **A live example** — follow one enquiry: booking question → reply quoting
   the correct fee and hours within seconds.
5. **What it saves** — e.g. ~10 min per enquiry of staff time; instant replies
   ​​at any hour; consistent answers; fewer missed/urgent cases. (Estimate
   honestly: e.g., "around 4–5 minutes per simple enquiry" → state basis.)
6. **What is not finished** — Stage 5 (duplicates + daily summary); occasional
   classification inconsistency.
7. **What we'd build next** — duplicate detection, daily summary email,
   a human-approval queue, integration with the real website form; roughly
   "1–2 weeks".

> Present to a NON-technical person: avoid words like 'webhook' and 'JSON'
> unless explained. Talk about **what the clinic and its patients gain**.
> When you don't know an answer: say "I'd have to verify that, but I can find
> out" — never bluff.

---

## 13. Where everything lives (for the technical handover)

- **Workflow files** (in `n8n_flow/`):
  - `workflow_stage4.json` — final working version (Stages 1–4)
  - `workflow_stage3_final.json` — previous Stage 3 build (reference)
- **Running system**: n8n at `http://localhost:5678` (Docker container `n8n`),
  test endpoint `POST http://localhost:5678/webhook-test/enquiry`
- **Spreadsheet**: "Clinic Enquiries" (Google account + OAuth credential in n8n)
- **Email**: Gmail `driftershots@gmail.com` (SMTP app password stored in n8n
  credentials — never paste it in emails/screenshots)
- **AI**: Groq credential in n8n (model `qwen/qwen3.8-27b`)

To re-import the workflow: n8n → Workflows → Import from File →
`workflow_stage4.json`. Credentials and sheet links carry over by ID.