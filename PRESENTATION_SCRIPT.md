# n8n Clinic Enquiry Automation — Presentation Script (8–10 min)

Use this as your speaker script for the assessment presentation. Each slide below has:
**On screen** (what to put on the slide) and **Say this** (your spoken words, written to be read aloud naturally).
Total speaking time is around 8–9 minutes; rehearse once with a timer. Keep it conversational — you do not need technical detail.

---

## Slide 1 — Title: Clinic Enquiry Automation

**On screen:**
- Title: "Automating Patient Enquiries with n8n"
- Subtitle: "How a dental clinic stopped answering the same questions by hand"
- Your name

**Say this (≈30 sec):**
> "Hello. Today I'm going to show you a project that automates patient enquiries for a dental clinic. Instead of someone reading and replying to every website message by hand, a small automation service now does it instantly — and only hands the tricky, sensitive cases to the staff. We used a tool called n8n for this, which lets you build automations visually without writing code. Let me start with who this is for."

---

## Slide 2 — The Client

**On screen:**
- "CityCare Dental Clinic, Pune"
- A clinic with a website enquiry form
- Picture: a patient submitting a question on a website form

**Say this (≈45 sec):**
> "The client is a small dental clinic in Pune — I'll call it CityCare. Patients visit their website and submit an enquiry form. The questions are everyday ones: 'how much is a cleaning?', 'are you open on Sundays?', 'I have tooth pain for two weeks, should I come in?'. Every single message had to be read, understood, and answered by a staff member. That causes three problems, which are the three things this project fixes."

---

## Slide 3 — The Problem

**On screen:** three bullets
- Slow → patients wait hours; nobody's around on Sunday nights
- Inconsistent → different staff give different prices and answers
- Sensitive → health questions need care, not a rushed copy-paste

**Say this (≈45 sec):**
> "First: it's slow. A simple price question can sit unanswered for a whole working day. Second: it's inconsistent — if two staff answer the same question, you might get two different prices, and that erodes trust. And third: some enquiries are sensitive. When someone says 'I've had tooth pain for two weeks', you don't want a tired, rushed reply — you want a careful human to follow up. So the goal became: automate the routine, humanise the sensitive, and never lose or misroute a single enquiry."

---

## Slide 4 — The Solution / Architecture

**On screen:** a simple picture (no code):
```
Patient form  →  Check & store (Google Sheet)  →  AI classifies it  →  Route
                                                                    ├─ Routine → AI reply (from the clinic's real facts)
                                                                    └─ Sensitive / medical / complaint → a staff member
```
Label the parts: n8n, Google Sheets, Gmail, AI (Groq).

**Say this (≈60 sec):**
> "Here's the design, and it follows one of the client's own forms from left to right. When a patient submits a message, the first thing we do is check it — is there a name, is the phone number valid? Bad submissions get politely rejected. Good ones are stored permanently in a Google Sheet — the clinic's log of every enquiry, with a timestamp. Then an AI reads the message and classifies it: is it a booking question, a billing question, a health question, or a complaint — and how urgent is it? Then the workflow routes it. Routine questions get an instant answer written by AI — but that answer is restricted to the clinic's real facts, prices and opening hours, which come from a second sheet. Sensitive questions like health problems or complaints go straight to a staff member's email for a human to handle. Nothing is guessed, nothing is lost."

---

## Slide 5 — Live Example: one enquiry, end to end

**On screen:** the actual patient email body:
> *"Dear Kavita, teeth whitening at CityCare Dental Clinic is priced at INR 6000, and we are open on Sundays from 10:00 to 14:00…"*

**Say this (≈60 sec):**
> "Let me show you a real one. A patient asked: 'how much does teeth whitening cost, and are you open on Sundays?' Within seconds the patient got an email that quotes the exact price — six thousand rupees — and the exact Sunday hours. Two things matter here. Nothing was typed by a staff member, and nothing was made up: both figures came from the clinic's own information sheet. This is what we call grounding — the AI can only answer from what the clinic has told us. That's the difference between an automation that helps and one that embarrasses you with wrong information."

---

## Slide 6 — What We Built: the four stages

**On screen:** four pills, one per stage, each ticked
1. Capture & validate → logged to a Google Sheet
2. AI classification (category + urgency)
3. Routing by category AND urgency (auto-reply / staff / alert)
4. Grounded replies + retries + failure log

**Say this (≈60 sec):**
> "We delivered this in four stages. Stage one — capture and validation: the form, the checks, and the permanent log. Stage two — AI classification: the machine reads the message and tags it with a category and an urgency, and we made sure messy machine outputs can't crash the workflow. Stage three — routing: bookings and billing get instant answers; health questions and complaints go to staff; anything urgent triggers an extra alert. Stage four is the important one — grounding and reliability. The AI answers only from the clinic's real facts, and if something does fail, the workflow tries once more and then writes the problem to a separate sheet, instead of silently doing nothing. It's built to fail gracefully, not silently."

---

## Slide 7 — Challenges + What We Learned About n8n

**On screen:** 3 short bullets
- Emails went out with empty bodies (a subtle setting) → found & fixed
- AI occasionally tags a billing question as a health question → safety nets
- Sheet tabs break when a workflow is moved → re-link once on import

**Say this (≈60 sec):**
> "Honest engineering always has surprises, and this had a few. One was subtle: our early emails looked perfect logically, but arrived with empty bodies — a tiny configuration mismatch in the email step. We caught it, fixed it, and re-verified. Another is that the AI — fast and clever as it is — is not perfect: very occasionally it tags a billing question as a health question. That doesn't lose the enquiry, because our safety nets catch failures and route them to a human, but it's why we don't let AI make the final decision on health matters. And a practical one: when a workflow is moved to another workspace, the spreadsheet links reset, and you have to re-link them once. Learning these quirks was genuinely the most valuable part."

---

## Slide 8 — Honest Status: what's done, what's not

**On screen:** two columns
- Done ✅ Stages 1–4, live end-to-end on n8n Cloud
- Not done ❌ Stage 5 (10-minute duplicate blocking + 9 AM daily summary); classification model could be more consistent; production webhook not yet activated in the shared workspace

**Say this (≈60 sec):**
> "I want to be completely honest about where this stands, because I'd rather be transparent than overclaim. Everything through Stage four works and is verified on the cloud. What is not done: Stage five — duplicate-message blocking and the daily summary email — we prioritised making Stages one to four rock solid first, and that cost us the bonus stage. Also, the classification model is fast and cheap for a reason; a stronger model would reduce the occasional mis-tag. And in the shared cloud workspace the production webhook isn't activated yet — the test environment works, but a real website would need that switch. I'm not going to pretend the video shows something the system can't do; it does what we'll demo, no more."

---

## Slide 9 — What We'd Do Differently / What's Next

**On screen:** bullets
- Validate AI output with clearer prompts / try a stronger model
- Build the safety/alert paths and the failure sheet BEFORE the happy path (they're what protect the client)
- Next (1–2 weeks): Stage 5 (dedupe + daily summary), human-approval queue, connect the real form

**Say this (≈45 sec):**
> "If I started again I'd do two things differently. First, I'd invest more early in the output-checking guards — the safety nets are what protect the client when the AI misbehaves, and they deserve as much attention as the happy path. Second, I'd prototype the email step on real mail earlier, so the empty-body bug would have been caught in the first hour, not late in testing. Given a week or two more, the natural next step is Stage five — blocking exact duplicates within ten minutes, and a nine o'clock morning email summarising yesterday's enquiries by category — then wiring the clinic's real website form to the automation."

---

## Slide 10 — Live Demo + Where Everything Lives

**On screen:**
- "Live demo:" (post 3 enquiries)
- "Everything lives in:" `n8n_flow/` → `workflow_stage4.json`, this script, test requests

**Say this (≈60–90 sec):**
> "Now the honest bit — let me prove it live. I'll send three test enquiries. The first is a billing question — you'll see an instant reply quoting the exact price and hours. The second is a health question — you'll see it NOT get an automatic answer, but instead a note for the staff with a summary of the patient's problem. And the third is a deliberate invalid phone number — you'll see it rejected cleanly with no row written. You can try any of these on the public test URL using the requests in our test file. The whole thing lives in a project folder: the final workflow file, this script, and a copy-paste list of test requests — so it's fully handover-able, not just a demo."

---

## Timing check

| Slide | Topic | Time |
|---|---|---|
| 1 | Title | 0:00–0:30 |
| 2 | Client | 0:30–1:15 |
| 3 | Problem | 1:15–2:00 |
| 4 | Architecture | 2:00–3:00 |
| 5 | Live example | 3:00–4:00 |
| 6 | Four stages | 4:00–5:00 |
| 7 | Challenges | 5:00–6:00 |
| 8 | Honest status | 6:00–7:00 |
| 9 | Next steps | 7:00–7:45 |
| 10 | Live demo | 7:45–9:00 |

## Likely questions — and short answers

- **"What tool did you use?"** — n8n, a visual automation platform; the logic is drawn as a flow, not written as code.
- **"Does the AI ever give a wrong price?"** — It can't invent prices, because it's only allowed to answer from the clinic's own facts sheet; if something isn't in it, it says so and offers a callback.
- **"What happens when the AI is down?"** — The workflow falls back: the enquiry goes to staff for manual handling and the problem is logged — nothing is silently lost.
- **"Can this send email as the clinic?"** — Yes, through Gmail; staff recipients and alerts go to a fixed clinic inbox, patient replies go to the patient's own address.
- **"What did you NOT do?"** — Stage 5 (dedupe + daily summary) and activating the production webhook in the shared workspace — see slide 8. I'd rather say that plainly than overclaim.
- **"What would you improve first?"** — Block exact duplicates within 10 minutes, add the daily summary, and try a stronger (steeper) model for fewer mis-tags.