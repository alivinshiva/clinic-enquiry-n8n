# Clinic Enquiry Automation with n8n

An always-on automation for a dental clinic's website enquiry form. When a patient
submits a message, the workflow validates it, stores it in Google Sheets, has an AI
classify it (category + urgency), then either **replies instantly with the clinic's
real information** (bookings/billing), or **routes it to a staff member** for manual
handling (medical questions, complaints), with **retries and a failure log** so no
enquiry is ever silently lost.

Built with **n8n** (self-hosted or Cloud) + **Google Sheets** + **Gmail (SMTP)** + **Groq (AI, model `qwen/qwen3.8-27b`)**.

---

## Features (assignment stages 1–4)

| Stage | Feature |
|---|---|
| 1 | Webhook intake, validation (10-digit Indian mobile), permanent log to Google Sheets |
| 2 | AI classification → `category` + `urgency` + one-line `summary`; malformed AI output handled gracefully |
| 3 | Routing by category **and** urgency: auto-reply (appointment/billing), staff email (medical/complaint), extra alert for high urgency, action logged |
| 4 | **Grounded replies** — the replying AI is restricted to a "Clinic Info" facts sheet and must refuse + offer a callback when something isn't covered; retry-once then **log failures to a separate "Failures" sheet** |

Stage 5 (10-minute duplicate blocking + 9 AM daily summary) is **not implemented** — see Honest limitations.

---

## How it works

```
Patient form (POST /webhook/enquiry)
        │
        ▼
┌─────────────────────────────────────────────────────────────┐
│ n8n workflow (workflow_stage4.json)                         │
│  Validate → log to "Sheet1" → AI classify → route           │
└─────────────────────────────────────────────────────────────┘
        │                          │
        ▼                          ▼
   Appointment/Billing        Medical/Complaint
        │                          │
        ▼                          ▼
 ┌──────────────┐          ┌──────────────────┐
 │ Read facts   │          │ Email staff for  │
 │ (Clinic Info)│          │ manual handling  │
 │      │       │          └──────────────────┘
 │      ▼       │
 │ AI reply +   │          High urgency?  →  extra URGENT alert email
 │ email patient│
 └──────────────┘
 Failure twice anywhere → logged to the "Failures" sheet
```

---

## Repository structure

```
├── workflow_stage4.json        ← CANONICAL workflow (import this)
├── workflow_stage3_final.json  ← earlier Stage 3 build (reference)
├── workflow_stage3.json / workflow_stage2_fixed.json / workflow_current.json / My workflow.json
│                               ← earlier exports (reference)
├── docker-compose.yml          ← self-hosted n8n via Docker (needs Dockerfile)
├── Dockerfile                  ← n8n + python image for the compose file
├── PROJECT_EXPLAINER.md        ← full plain-language project write-up
├── PRESENTATION_SCRIPT.md      ← 10-slide presentation script + Q&A
├── TEST_POST_REQUESTS.md       ← copy-paste curl tests with expected results
└── APJ_Technical_Assessment_n8n.pdf
```

---

## Prerequisites (get these ready first)

Before importing the workflow you need these **accounts and services**:

1. **An n8n instance**
   - **Option A — self-host (as built here):** Docker + `docker-compose up -d` in this repo. Make sure the Docker image is built first (`docker compose build n8n`), then n8n is at `http://localhost:5678`.
   - **Option B — n8n Cloud:** create an account at n8n.cloud and use your instance URL (e.g. `https://<subdomain>.app.n8n.cloud`).
2. **A Google account** (browser sign-in) and **Google Drive** — for the spreadsheet and the OAuth connection. The Google account used for the Sheets credential must have *Editor* access to the spreadsheet.
3. **Gmail with 2-Step Verification ON** — the address the clinic emails are sent **from**. You will create an **App Password** for it (Google account → Security → 2-Step Verification → App passwords).
4. **A Groq account** — sign up at console.groq.com, go to **API Keys**, create a key. (Free tier is enough.)

---

## Step 1 — Prepare the spreadsheet

1. Create a new Google Spreadsheet, e.g. **"Clinic Enquiries"** (copy its URL id once created).
2. Rename Sheet1 to **Sheet1** and add this header row in row 1:
   ```
   timestamp | name | phone | email | enquiry_text | valid | error_message | category | urgency | summary | action | action_timestamp
   ```
3. Add a second tab **Clinic Info** with two columns `key` and `value`, and these rows (edit freely — this is the ONLY information the replying AI may use):
   ```
   clinic_name        | CityCare Dental Clinic
   address            | 12 MG Road, Shivaji Nagar, Pune - 411005
   phone              | +91-9822-045678
   timings            | Mon-Sat 9:30-19:00, Sun 10:00-14:00
   consultation_fee   | INR 500
   cleaning_fee       | INR 1000
   whitening_fee      | INR 6000
   root_canal_fee     | from INR 4500
   xray_fee           | INR 300
   services           | Consultation, Dental cleaning and polishing, Teeth whitening, Root canal treatment, Crowns and bridges, Dental X-rays, Extractions
   booking_note       | Book through this form; we confirm by return email or call within one working day
   ```
4. Add a third tab **Failures** with header row:
   ```
   timestamp | node | message | retried | data
   ```

---

## Step 2 — Import the workflow

1. n8n → **Workflows** → **Import from File** → choose `workflow_stage4.json`.
2. Open the workflow and save it.

## Step 3 — Create the 3 credentials

1. **Groq** (type `Groq`) — paste the API key from console.groq.com.
2. **SMTP** (type `SMTP`) — for sending the emails:
   - Host: `smtp.gmail.com`
   - Port: `587` · SSL/TLS: **off** (STARTTLS is used automatically)
   - User: the full Gmail address (e.g. `you@gmail.com`)
   - Password: the **App Password** you generated for that Gmail (spaces are fine)
3. **Google Sheets OAuth2 API** (type `Google Sheets OAuth2 API`) — click **Sign in with Google**, choose the account with Editor access to the spreadsheet, approve.

## Step 4 — Attach credentials and point nodes at the spreadsheet

1. On every node whose credential dropdown is empty/red, select the credential you created:
   - **Google Sheets** nodes → the Sheets credential
   - **emailSend** nodes (5) → the SMTP credential
   - The **Groq Chat Model** node → the Groq credential
2. **Re-pick the tab on every Google Sheets node** (tab links reset on import): open each node and select `Sheet1` / `Clinic Info` / `Failures` from the dropdown.
3. After re-picking the append/log nodes, confirm **"Values to Send"** still has its fields (re-picking can clear them — re-add if empty).

## Step 5 — Make it your own (things you MUST update)

- **From Email** on all emailSend nodes → must be the **exact Gmail address of the SMTP account** (Gmail won't send as another address). Currently `k21089528@gmail.com`.
- **To Email** on the staff + alert nodes → the clinic inbox that should receive manual-handling notes (currently `driftershots@gmail.com`).
- If you created your own spreadsheet: set its **document ID** on all Google Sheets nodes.

## Step 6 — Run it

- **Test:** open the **Webhook** node → **Listen for test event**, then POST to the shown URL — during that window only. Use the requests in `TEST_POST_REQUESTS.md`.
- **Production:** set the Webhook node to **Production**, flip the workflow **Active**, and POST to `/webhook/enquiry` 24/7.

A quick smoke test:
```bash
curl -X POST 'http://localhost:5678/webhook-test/enquiry' \
  -H 'Content-Type: application/json' \
  -d '{"name":"Nisha Sharma","phone":"9822123456","email":"you@gmail.com","enquiry_text":"How much does teeth whitening cost and what are your opening hours on Sundays?"}'
```
Expect: `{"received":true,"message":"Enquiry recorded"}` + a patient email quoting **INR 6000** and **Sundays 10:00–14:00**, and a row in `Sheet1` with `action: auto-replied`.

---

## Troubleshooting

| Symptom | Fix |
|---|---|
| `404 "webhook not registered"` | You're calling while no **Listen for test event** is active, or the workflow isn't **Active** in Production mode. |
| Emails arrive with **empty body** | The email node body must use the `text` parameter (it's the field labelled **Message/Body** in the node); a stale export may carry a wrong field name. |
| `"Sheet with ID ... not found"` | Tab links use internal gids that reset on import — re-pick the tab on the node in the UI. |
| SMTP `535` / authentication failed | Enable 2-Step Verification on the Gmail and use a fresh **App password** (regular password won't work). |
| Wrong/missing reply fields | AI replies are read as `$json.text` (not `$json.output.text`); if you change models, check the LLM node output shape. |

---

## Docs

- **PROJECT_EXPLAINER.md** — how the whole thing works, plain language, incl. real test results and honest limitations.
- **PRESENTATION_SCRIPT.md** — slide-by-slide speaker script + likely Q&A (assessment presentation).
- **TEST_POST_REQUESTS.md** — copy-paste curl tests: happy path, not-covered (refusal), medical → staff, complaint, high urgency alert, invalid phone.

## Honest limitations (don't hide these)

- **Stage 5 is not implemented** (10-minute duplicate blocking, 9 AM daily summary).
- The classification model is fast but occasionally mis-tags a booking as a medical question — safety nets route failures to staff, but don't fix every *mis*tag; a stronger/fewer mis-tagging model would help.
- The **production webhook** must be activated in each n8n instance before a real website form can post to it.
- Early test emails suffered an **empty-body bug** (wrong email field name) — found, fixed, and re-verified.

## License

For educational/assessment use. All system names are fictional.