# Wiki Update Workflow

Use this when a durable requirement, decision or knowledge structure changes.

1. Use the wiki index or search to find the owning topic. Read relevant source and
   linked constraints, reusing context already available.
2. Read `.project-wiki/schema.md` when creating or changing entity structure and
   choose the appropriate entity type; follow
   `.project-wiki/methods/knowledge-maintenance.md` for where each kind of
   knowledge is kept.
3. Update the existing authoritative topic or create a focused entity when needed.
   Cite sources with their status. Preserve confirmation sources, dates,
   boundaries and unresolved questions;
   distinguish accepted requirements from implemented behavior and observations.
4. Record conflicts instead of smoothing them over. Keep a transcript, rough
   note, audit or research fragment that is not yet authoritative under
   `.project-wiki/raw/` with its original bytes, and promote only confirmed,
   durable claims into current topic pages.
5. Use links for cross-topic rules. Update other topics only where their own
   contract changes; do not duplicate business requirements into root entries,
   the index or operational runbooks.
6. Update `.project-wiki/index.md` only for changed pages, paths or reading routes.
   When the project keeps a human reading guide, maintain it as defined in the
   [knowledge maintenance method](../../.project-wiki/methods/knowledge-maintenance.md).
   Record a concise change summary and owning-topic link in `.project-wiki/log.md`.
7. For restructuring, map every old section to its destination and verify retained
   content, provenance and links. Run checks proportionate to the actual change.
8. If a live Issue governs the work, synchronize its contract under the existing
   GitHub workflow; wiki updates do not replace that requirement.
