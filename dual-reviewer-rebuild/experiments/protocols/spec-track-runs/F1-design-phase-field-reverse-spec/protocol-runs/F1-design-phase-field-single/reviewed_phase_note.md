          # reviewed phase note

          ## 1. run scope

          - run label: `F1-design-phase-field-single`
          - case id: `F1-design-phase-field-reverse-spec`
          - track: `spec`
          - review mode: `single_review`
          - reviewed phase: `design`
          - operator: `phase-field-design-pilot`
          - reviewed phase ref:
            - `.kiro/specs/phase-field-reverse-spec/design.md`
          - adjacent phase refs:
          - `.kiro/specs/phase-field-reverse-spec/requirements.md`
  - `.kiro/specs/phase-field-reverse-spec/tasks.md`

          ## 2. phase findings

          phase-local issues:
  - [high] The design introduces a large number of tightly coupled component boundaries across Numerical Engine, clamp/correction helpers, snapshot I/O, visualization, and three executables, so downstream tasks must keep ownership and integration boundaries explicit to avoid silent coupling drift. (refs: `.kiro/specs/phase-field-reverse-spec/design.md`, `.kiro/specs/phase-field-reverse-spec/requirements.md`)
  - [medium] Static allocation, clamp non-convergence handling, and step-level diagnostic propagation are already fixed in design, so downstream implementation tasks need to preserve these failure contracts rather than reinterpreting them as local coding choices. (refs: `.kiro/specs/phase-field-reverse-spec/design.md`)

          cross-phase inconsistencies:
  - [high] The design is generated but not approved, and the tasks phase is also unapproved, so the current design should not be treated as implementation-ready without a design/tasks recheck against the approved requirements contract. (refs: `.kiro/specs/phase-field-reverse-spec/design.md`, `.kiro/specs/phase-field-reverse-spec/spec.json`, `.kiro/specs/phase-field-reverse-spec/tasks.md`)

          caveats:
  - (none)

          ## 3. reopen assessment

          - reopen required: `true`
          - target reopen phases: `design, tasks`
          - intent-attributed issues:
  - [medium] The clean-room scientific intent still constrains the design surface: component responsibilities and accepted dependencies must remain derivable from the narrow canonical sources instead of silently importing extra assumptions. (refs: `.kiro/specs/phase-field-reverse-spec/intent.md`, `.kiro/specs/phase-field-reverse-spec/design.md`)

          ## 4. next action

          - next action: `design boundary と failure contract を再確認し、その前提で tasks 側の ownership と acceptance routing を引き直す`
