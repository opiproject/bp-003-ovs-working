# Maintenance and Update Notes

This project intentionally stays simple: docs-first, artifact-backed, easy for sponsor and intern to maintain.

## Update Cadence

- Weekly: sync deliverable status and blockers.
- Per milestone: archive evidence and update acceptance checklist.
- Before any TSC touchpoint: refresh blueprint stage and partner attribution notes.

## Source-of-Truth Order

1. Local folder artifacts (`docs/`, `specs/`, `artifacts/`)
2. OPI blueprint framework requirements
3. OPI blueprint registry entry (BP-003 metadata)

## Plugin/Workflow Dependencies

- Honey rule active globally via `~/.cursor/rules/honey.mdc`.
- Context Mode active as local plugin via `~/.cursor/plugins/local/context-mode/`.
- Restart Cursor after plugin/rule updates.

## Plugin Update Commands

### Honey

```bash
curl -sL "https://raw.githubusercontent.com/Green-PT/honey-for-devs/main/.cursor/rules/honey.mdc" \
  -o ~/.cursor/rules/honey.mdc
```

### Context Mode

```bash
rm -rf /tmp/context-mode-dl
mkdir -p /tmp/context-mode-dl
curl -sL "https://github.com/mksglu/context-mode/archive/refs/heads/main.tar.gz" \
  -o /tmp/context-mode-dl/main.tar.gz
tar -xzf /tmp/context-mode-dl/main.tar.gz -C /tmp/context-mode-dl
rm -rf ~/.cursor/plugins/local/context-mode
mv /tmp/context-mode-dl/context-mode-main ~/.cursor/plugins/local/context-mode
```

## Repo Hygiene

- Keep public proposal/meeting *outcomes* (not raw board notes) under `docs/`.
- Keep acceptance criteria and milestone tracking under `specs/`.
- Keep deployment assets under `artifacts/`.
- Keep framework references under `references/`.
- **Never commit** `private/` (emails, personal timelines, internal eval notes).
