# Test POST Requests — Clinic Enquiry Workflow

Run each test by POSTing the request below. Which URL depends on where the workflow is running:

| Environment | URL to use | Requirements |
|---|---|---|
| Local n8n (this machine) | `http://localhost:5678/webhook-test/enquiry` | Click **Listen for test event** on the Webhook node first |
| n8n Cloud (kavyarathod1511) | `https://kavyarathod1511.app.n8n.cloud/webhook-test/enquiry` | Click **Listen for test event** first |
| n8n Cloud — production | `https://kavyarathod1511.app.n8n.cloud/webhook/enquiry` | Workflow must be **Active** (currently not registering — see Notes) |

> **Rule of thumb:** `webhook-test` URLs need a fresh "Listen for test event" click before each test,
> otherwise you get the `404 The requested webhook "POST enquiry" is not registered` error.
> Production URL (`/webhook/enquiry`) answers 24/7 with no set-up — use it once activated.

**Payload rules:** `phone` must be a valid 10-digit Indian mobile (starts 6–9).
`email` is where the patient reply email goes — for demos use `k21089528@gmail.com`;
staff/alert mails always go to `driftershots@gmail.com`.

---

## Test 1 — Basic / billing question → auto-reply (the main happy path)

```bash
curl -X POST '<URL>/enquiry' \
  -H 'Content-Type: application/json' \
  -d '{"name":"Nisha Sharma","phone":"9822123456","email":"k21089528@gmail.com","enquiry_text":"How much does teeth whitening cost and what are your opening hours on Sundays?"}'
```

- **HTTP:** 200 JSON `{"received":true,"message":"Enquiry recorded"}`
- **Email to patient:** arrives from `k21089528@gmail.com`, subject `Regarding your enquiry, Nisha Sharma`, body quotes **INR 6000** + **Sundays 10:00–14:00** (grounded from Clinic Info sheet).
- **Sheet (Sheet1):** row logged with `category: billing`, `action: auto-replied`.

## Test 2 — Question NOT covered by clinic facts → refuse + offer callback

```bash
curl -X POST '<URL>/enquiry' \
  -H 'Content-Type: application/json' \
  -d '{"name":"Faisal Khan","phone":"9012345678","email":"k21089528@gmail.com","enquiry_text":"Do you offer dental implants and how much do they cost per tooth?"}'
```

- **HTTP:** 200 `{"received":true,"message":"Enquiry recorded"}`
- **Email to patient:** reply says the clinic has **no information** on implants and invites a **call or callback** — it must NOT invent a price.

## Test 3 — Medical / health question → manual handling by staff

```bash
curl -X POST '<URL>/enquiry' \
  -H 'Content-Type: application/json' \
  -d '{"name":"Vikram Rao","phone":"9955123467","email":"k21089528@gmail.com","enquiry_text":"I have tooth sensitivity to hot and cold drinks for two weeks. Should I come for a check-up?"}'
```

- **HTTP:** 200 `{"received":true,"message":"Handled"}`
- **Staff email** (`driftershots@gmail.com`): subject like `Manual handling needed: medical_query (low)` with the summary + patient details.
- **Sheet (Sheet1):** row logged `category: medical_query`, `action: manual handling`.

## Test 4 — Complaint → manual handling by staff

```bash
curl -X POST '<URL>/enquiry' \
  -H 'Content-Type: application/json' \
  -d '{"name":"Ravi Patel","phone":"9876501234","email":"k21089528@gmail.com","enquiry_text":"I waited two hours for my appointment last week. This is the second time. I want to complain."}'
```

- **HTTP:** 200 `{"received":true,"message":"Handled"}`
- **Staff email** for manual handling; sheet row `category: complaint`, `action: manual handling`.

## Test 5 — High urgency → alert email fires as well

```bash
curl -X POST '<URL>/enquiry' \
  -H 'Content-Type: application/json' \
  -d '{"name":"Meera Iyer","phone":"9845087654","email":"k21089528@gmail.com","enquiry_text":"I have severe tooth pain since last night, can I come in today? It is really urgent."}'
```

- **HTTP:** 200 (auto reply if classified billing, or `Handled` if medical)
- **EXTRA alert email** to `driftershots@gmail.com` with subject like `URGENT ALERT - high urgency clinic enquiry`.

## Test 6 — Invalid phone → clean rejection (no row written)

```bash
curl -X POST '<URL>/enquiry' \
  -H 'Content-Type: application/json' \
  -d '{"name":"Jane Smith","phone":"555-0102","email":"jane@test.com","enquiry_text":"Book a cleaning"}'
```

- **HTTP:** 400 with `{"error":"Phone number must be a valid 10-digit Indian mobile number."}`
- **No** new row in the sheet.

---

## Quick reference — what a correct run looks like end-to-end

1. `200` response with `Enquiry recorded` or `Handled`.
2. Exactly one patient email (auto branch) — body matches clinic facts — or a staff email (manual branch).
3. Exactly one new row in Sheet1 with the right `action`.
4. (High urgency only) an extra `URGENT ALERT` email, and on repeated failures rows in the **Failures** tab.

## Notes

- **Production webhook not registering (as of handover):** test mode works; for `/webhook/enquiry` to answer, set the Webhook node to **Production** mode and the workflow **Active** in the target n8n. If it still 404s on cloud, open the Webhook node → **Listen for test event** copies the exact registered URL.
- **Import note:** after importing the JSON into a new workspace, re-pick the sheet tabs (`Sheet1`, `Clinic Info`, `Failures`) on the Google Sheets nodes and re-attach the 3 credentials (Groq, SMTP, Google Sheets OAuth2).