# Trial Landing Page Spec

**URL**: timetocontext.co/trial

---

## Page Purpose

Convert developers, architects, and enterprise teams into trial users of ContextECF by letting them deploy the Enterprise Context Fabric locally in minutes.

The goal is to demonstrate that ContextECF can run entirely inside their infrastructure while assembling enterprise context across systems.

---

## 1. Hero Section

**Headline**: ContextECF — The Enterprise Context Fabric for AI Systems

**Subheadline**: Deploy ContextECF on-premise or in your cloud and assemble real-time enterprise context across CRM, messaging, documents, and operational systems. Run the entire platform locally in under 5 minutes.

**Supporting Line**: Your data never leaves your infrastructure.

**Primary CTA**: "Start Free Trial" (scrolls to signup form)

---

## 2. The Problem Section

**Title**: AI systems fail when they lack context.

**Copy**:

Enterprise knowledge is scattered across dozens of systems: CRM, Slack / Teams, email, documents, ticketing systems, code repositories, and operational tools.

AI assistants and applications must search these systems repeatedly, resulting in:

- Incomplete answers
- Hallucinations
- High token costs
- Slow response times

**Bridge Statement**: ContextECF solves this by assembling context before AI systems need it.

---

## 3. What ContextECF Does

**Title**: The Context Infrastructure Layer

**Description**: ContextECF continuously ingests signals from enterprise systems and assembles them into structured context packages that AI systems and applications can access instantly. Instead of searching for information, systems retrieve ready-to-use context.

**Key Benefits**:

| Capability | Description |
|------------|-------------|
| Context Assembly | Combines signals from CRM, documents, meetings, tickets, and messaging systems |
| Deterministic APIs | Retrieve structured context in milliseconds |
| Context Synthesis | Generate briefs, summaries, and insight signals |
| Policy Governance | Enforce security and access controls across context |
| Deploy Anywhere | Run on-premise or in your own cloud (AWS, GCP, Azure) |

---

## 4. What You Get in the Trial

**Card 1 — Full Context Fabric**
Run the complete ContextECF platform locally. Includes ingestion, context search, synthesis, and context drift signals.

**Card 2 — Your Infrastructure**
ContextECF runs entirely inside your network using Docker Compose. No enterprise data leaves your environment.

**Card 3 — 14-Day Trial**
Full read/write access for 14 days. After expiration you retain read and export access to your data.

---

## 5. How It Works

**Step 1 — Sign Up**
Register below and receive a container registry token and trial license.

**Step 2 — Install**
Clone the repository and run the install script.

```bash
git clone https://github.com/Intelligent-Context-AI-Inc/ContextECF.git
cd ContextECF/starter
export REGISTRY_TOKEN=<your-token>
./install.sh
```

**Step 3 — Integrate**
Use ContextECF APIs to ingest signals and retrieve assembled context. Endpoints include: ingestion, context search, synthesis, and briefs.

---

## 6. Example Developer Workflow

Developers typically start by connecting: CRM data, email metadata, meeting transcripts, and document signals.

Within minutes ContextECF begins producing context briefs and relationship signals.

---

## 7. Trial Signup Form

**Fields:**

| Field | Type | Required |
|-------|------|----------|
| Full Name | text | Yes |
| Work Email | email | Yes |
| Company | text | Yes |
| Role | dropdown | No |
| Phone | tel | No |

Role dropdown options: Engineering, Platform, DevOps, Product, Security, Other

**Submit Button**: "Get Trial Credentials"

**Post-submit behavior:**
- Show confirmation: "Check your email for registry credentials and setup instructions."
- Send email to the address with: container registry token, registry URL, trial license file, and quick-start instructions.
- Notify ash@intelligentcontext.ai on every submission.

---

## 8. What Happens After Signup (below form, always visible)

> **After you sign up, you'll receive:**
> - A container registry token (REGISTRY_TOKEN)
> - A registry URL
> - A 14-day trial license file (license.jwt)
> - Quick-start instructions
>
> **Need help?** Email ash@intelligentcontext.ai or call (916) 753-7432.

---

## 9. System Requirements

- Docker Engine 20.10+
- Docker Compose v2+
- 8 GB RAM
- 10 GB free disk

Works on: macOS, Linux, Windows (WSL2)

---

## 10. FAQ (collapsible)

**Q: Does any data leave my machine?**
A: No. ContextECF runs entirely inside your infrastructure. The only external call is pulling container images from our registry during install.

**Q: Do I need Kubernetes?**
A: Not for the trial. Docker Compose is sufficient. Kubernetes deployment is available for production environments.

**Q: What happens when the trial expires?**
A: Write operations stop. Read and export access remain available. Your data always remains yours.

**Q: What enterprise systems can I connect?**
A: The trial includes connectors for CRM, email, calendar, and messaging systems via the Connector Gateway.

---

## 11. Footer

**Links:**
- [GitHub repository](https://github.com/Intelligent-Context-AI-Inc/ContextECF)
- [API documentation](https://github.com/Intelligent-Context-AI-Inc/ContextECF/blob/main/docs/api-overview.md)

**Contact:**
ash@intelligentcontext.ai | (916) 753-7432

Copyright 2024-2026 Intelligent Context AI, Inc.

---

## Design Notes

- Clean, minimal layout. No heavy graphics.
- Monospace font for code snippets.
- Primary color: use brand palette from timetocontext.co.
- Mobile responsive — form should work well on phone.
- Page should load fast (no heavy JS frameworks needed; static is fine).

---

## Technical Notes (for Lovable / builder)

- Form submissions should send an email notification to ash@intelligentcontext.ai with all form fields.
- If automating credential delivery: generate a unique REGISTRY_TOKEN per signup, store in a lightweight backend or Supabase table, and email it.
- If manual: just collect the form data, email it to ash@intelligentcontext.ai, and show "We'll email your credentials within 1 business hour."
- The page lives at `timetocontext.co/trial`.
