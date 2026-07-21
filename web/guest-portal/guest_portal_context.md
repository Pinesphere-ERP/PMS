You are working on Pinesphere PMS.

Repository structure:

- pinesphere_backend/ → FastAPI backend.
- pinesphere_stay/ → Flutter operational app.
- guest_portal/ → Separate guest-facing web portal.

Critical architecture constraints:

- Guest portal is NOT account-based.
- Guest portal is strictly stay-scoped.
- Guest has no permanent account.
- Authentication = booking reference + mobile number + OTP.
- Portal access begins only after check-in.
- Portal access ends after checkout + 24h grace window.
- Portal JWT must be stay-scoped, not user-scoped.
- Flutter owns operational state transitions:
    - check-in
    - room changes
    - guest updates
    - checkout
- Guest portal must NEVER mutate booking lifecycle directly.

Non-negotiable rules:

- Never create guest accounts.
- Never create passwords.
- Never duplicate business logic already present in backend.
- Reuse existing modules whenever possible.
- Preserve multi-tenancy.
- Preserve offline-first architecture.
- Preserve audit logging.
- Preserve role-based access.

Task requirements:

1. Analyze backend, Flutter app, and guest_portal folders.
2. Discover existing APIs, models, services, auth flow, booking lifecycle, and notifications.
3. Reuse existing architecture whenever possible.
4. Avoid introducing duplicate entities.
5. Produce implementation first.
6. Then implement.
7. Keep changes minimal and production-grade.
8. Follow existing coding conventions.