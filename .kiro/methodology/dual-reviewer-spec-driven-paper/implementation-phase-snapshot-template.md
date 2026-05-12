# implementation phase snapshot template

_作成: 2026-05-12_  
_status: template v0.1_  
_purpose: review acquisition に入れる implementation snapshot を固定するための最小 template_

---

## 1. Role

この文書は、`<case id>` の implementation source tree または seed artifact のうち、
review acquisition に入れる snapshot を固定するための boundary note である。

ここで固定するのは次である。

1. snapshot identity
2. snapshot root
3. included artifact set
4. snapshot の読み方
5. known incompleteness

この文書は source of truth ではなく、
current cut を参照可能にするための固定ノートである。

---

## 2. Snapshot Identity

- snapshot id: `<snapshot-id>`
- batch label: `<batch-label>`
- target label: `<target-label>`
- role in paper:
  - `<pilot | supporting case | core case>`

---

## 3. Snapshot Root and Provenance

- implementation workspace:
  - `<workspace path>`
- snapshot root:
  - `<source root path>`
- source provenance:
  - `<fresh spec-origin source tree | clean-room seed workspace | reverse-engineered workspace>`

必要なら追加:

- canonical source:
  - `<external spec or source seed ref>`
- file-set digest:
  - `<optional digest>`

---

## 4. Included Artifact Set

### 4.1 Top-Level Entrypoint or Main Anchor

- `<main file or spec seed file>`

### 4.2 Owner A Files

- `<file 1>`
- `<file 2>`

### 4.3 Owner B Files

- `<file 1>`
- `<file 2>`

artifact 数が多すぎる場合は、directory 単位の fixed include list にしてよい。

---

## 5. Fixed Snapshot Reading

この snapshot で読ませたいことを書く。

最低限含める観点:

- top-level entrypoint が薄いか、または anchor が明確か
- owner boundary が見えるか
- handoff chain が見えるか
- stub や未実装があっても boundary が崩れていないか

---

## 6. Known Incompleteness

この snapshot で未実装または未固定のもの:

- `<runtime integration gap>`
- `<hardware or deployment gap>`
- `<behavioral uncertainty>`

したがって、この snapshot は
`<hardware-ready implementation | full production implementation>` ではなく
`<reviewable first boundary snapshot | protocol acquisition snapshot>`
として扱う。

---

## 7. Exclusions

review acquisition の主対象にしないもの:

- `<secret provisioning>`
- `<calibration or tuning>`
- `<external docs only>`
- `<future extension not in current boundary>`

---

## 8. Immediate Operational Rule

snapshot を fixed とみなす前に確認すること:

1. common upstream input が固定されている
2. excluded source が review evidence に入らない
3. `single / dual / dual+judgment` が同一 snapshot ref を使う

これを満たした時点で snapshot は fixed とみなす。
