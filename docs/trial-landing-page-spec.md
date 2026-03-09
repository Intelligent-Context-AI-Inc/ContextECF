# Trial Landing Page Spec — timetocontext.co/trial

> Lovable / builder instruction set for the trial signup page.

---

## Page Purpose

Convert visitors into on-prem trial users by collecting minimal info and delivering registry credentials + a license file so they can run ContextECF locally in under 5 minutes.

---

## Page Structure

### 1. Hero Section

**Headline**: "Try ContextECF — Relationship Intelligence for Your CRM"

**Subheadline**: "Deploy on your own infrastructure. Your data never leaves your network. Up and running in 5 minutes."

**CTA Button**: "Start Free Trial" (scrolls to form)

---

### 2. What You Get (3 cards, icon + short text)

| Card | Icon idea | Text |
|------|-----------|------|
| Full Platform | server/stack | All core services: ingestion, search, briefs, drift signals, synthesis |
| Your Infrastructure | lock/shield | Runs on Docker Compose on your machine. Zero data leaves your network. |
| 14-Day Trial | calendar | Full write access for 14 days. Read/export access never expires. |

---

### 3. How It Works (numbered steps)

1. **Sign up below** — get your registry token instantly via email
2. **Clone and install** — one command: `./install.sh`
3. **Integrate** — JWT-authenticated APIs for ingestion, search, and synthesis

Include a small code snippet block:

```
git clone https://github.com/Intelligent-Context-AI-Inc/ContextECF.git
cd ContextECF/starter
export REGISTRY_TOKEN=<your-token>
./install.sh
```

---

### 4. Trial Signup Form

**Fields:**

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| Full Name | text | yes | |
| Work Email | email | yes | Validate domain (reject gmail/yahoo/hotmail if desired) |
| Company | text | yes | |
| Role | dropdown | no | Options: Engineering, Product, RevOps, Security, Other |
| Phone | tel | no | |

**Submit Button**: "Get Trial Credentials"

**Post-submit behavior:**
- Show confirmation: "Check your email for registry credentials and setup instructions."
- Send email to the address with: REGISTRY_TOKEN, REGISTRY URL, link to README quick-start, and a license.jwt attachment (or instructions to request one).
- CC or notify ash@intelligentcontext.ai on every submission.

---

### 5. What Happens After Signup (below form, always visible)

> **After you sign up, you'll receive:**
> - A container registry token (REGISTRY_TOKEN)
> - A registry URL
> - A 14-day trial license file (license.jwt)
> - Quick-start instructions
>
> **Need help?** Email ash@intelligentcontext.ai or call (916) 753-7432.

---

### 6. FAQ Section (collapsible)

**Q: What are the system requirements?**
A: Docker Engine 20.10+, Docker Compose v2+, 8 GB RAM, 10 GB free disk. Works on macOS, Linux, and Windows (WSL2).

**Q: Does any data leave my machine?**
A: No. ContextECF runs entirely on your infrastructure. The only external call is pulling container images from our registry during install.

**Q: What happens when the trial expires?**
A: Write operations stop (HTTP 402). Read and export access to your data is never blocked — you always own your data.

**Q: Can I connect to my CRM during the trial?**
A: Yes. The trial includes the Connector Gateway and API endpoints for Salesforce, Gmail, and Calendar integration.

**Q: Do I need Kubernetes?**
A: Not for the trial. Docker Compose is all you need. Kubernetes/Helm deployment is available for production.

---

### 7. Footer

- Link to [GitHub repo](https://github.com/Intelligent-Context-AI-Inc/ContextECF)
- Link to [API docs](https://github.com/Intelligent-Context-AI-Inc/ContextECF/blob/main/docs/api-overview.md)
- Contact: ash@intelligentcontext.ai | (916) 753-7432
- "Copyright 2024-2026 Intelligent Context AI, Inc."

---

## Design Notes

- Clean, minimal layout. No heavy graphics.
- Monospace font for code snippets.
- Primary color: use brand palette from timetocontext.co.
- Mobile responsive — form should work well on phone.
- Page should load fast (no heavy JS frameworks needed; static is fine).
- Consider adding a "Trusted by" or "Built for" section later once there are logos to show.

---

## Technical Notes (for Lovable / builder)

- Form submissions should send an email notification to ash@intelligentcontext.ai with all form fields.
- If automating credential delivery: generate a unique REGISTRY_TOKEN per signup, store in a lightweight backend or Supabase table, and email it.
- If manual: just collect the form data, email it to ash@intelligentcontext.ai, and show "We'll email your credentials within 1 business hour."
- The page lives at `timetocontext.co/trial`.
