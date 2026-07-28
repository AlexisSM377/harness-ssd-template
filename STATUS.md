# harness-sdd-template — Status

**Última actualización**: 2026-07-28
**Componentes del template**: 8/8 base + skills/ (nuevo)
**En producción**: n/a (es una plantilla, no un proyecto desplegable)

---

## Qué es este proyecto

Plantilla canónica versionada para arrancar proyectos nuevos con el arnés
Harness SDD (Spec-Driven Development). Ver `README.md` para los 8
componentes y `apply-template.sh` para instalarla en un proyecto destino.

---

## Cómo arrancar

```bash
./apply-template.sh <dir-proyecto-destino> <nombre-proyecto> [stack]
```

Este repo en sí no tiene build/test — es documentación + shell scripts.
`template/init.sh` es el `init.sh` que se copia al proyecto destino, no algo
que se corre aquí.

---

## Estado actual

- Los 8 componentes originales (specs, Clean Architecture, Obsidian,
  multi-IA, agentes, TDD, trazabilidad, `init.sh`) — estables, sin cambios
  desde `f76ff3f`.
- **Nuevo**: `template/.claude/skills/` — convención de skills reutilizables,
  plana con prefijo de track (`<track>-<nombre>/SKILL.md`). Ver
  `template/.claude/skills/README.md`. Detalle de la decisión y por qué no
  se anida por categoría: `plans/001-flat-skills-taxonomy.md`.
- `plans/` — nuevo directorio, usado por el skill `/improve` para planes de
  mejora de este mismo repo (plantilla). Plan 001 ejecutado y mergeado a
  `main` (commit `9056fc3`).

---

## Última sesión

**2026-07-28** — Se detectó que Claude Code no autodetecta skills anidadas
en subcarpetas por categoría (solo escanea `.claude/skills/<nombre>/SKILL.md`,
un nivel — anthropics/claude-code#28266, #40640, feature request abierto sin
shippear). Se descartó replicar la estructura anidada de una captura de
referencia ("loopkit" vault) y en su lugar se definió convención plana con
prefijo de track. Se agregó `template/.claude/skills/README.md` (convención
+ 9 tracks sugeridos) y un skill de ejemplo (`docs-readme-sync`). Se
actualizaron `README.md` y `template/AGENTS.md` para reflejar la nueva
ubicación. Ejecutado vía `/improve execute` (worktree aislado + review),
aprobado y mergeado a `main`. Worktree y branch temporal limpiados.
Resultado: verde. Próximos pasos: ninguno pendiente de esta sesión.

---

## Stack

N/A — este repo es la plantilla en sí (bash + markdown). El stack real vive
en cada proyecto destino, configurado en su `init.config.sh`.
