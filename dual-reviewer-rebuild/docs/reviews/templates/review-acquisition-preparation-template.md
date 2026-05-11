# review acquisition preparation template

> human `review acquisition gate` 前に、review acquisition boundary と upstream approved input を固定するための template。source of truth は approved spec, snapshot ref, workflow gate status であり、この memo はそれらの固定と参照に徹する。

## 1. role

- case id:
- target label:
- current review-acquisition role:
- operational interpretation:

## 2. fixed upstream approved spec set

### 2.1 umbrella inputs

- intent:
- optional umbrella refs:

### 2.2 approved requirements

- feature A requirements:

### 2.3 approved design

- feature A design:

### 2.4 approved tasks

- feature A tasks:

## 3. fixed implementation snapshot and review boundary

### 3.1 snapshot ref

- implementation snapshot ref:
- implementation protocol ref:
- implementation run template ref:

### 3.2 review boundary

implementation review acquisition の主対象に含めるもの:

- implementation-local concern:

implementation review acquisition の主対象にしないもの:

- excluded concern:

### 3.3 clean-room or provenance constraint

- canonical source:
- exclusion rule:

## 4. implementation order and shared artifact rule

- ordered owner flow:
- parallel / handoff rule:
- shared file owner:
- shared allocator owner:

## 5. validation and conformance entry points

- feature-local smoke tests:
- top-level smoke tests:
- review acquisition modes:

conformance review で見ること:

- implementation issue と upstream spec issue の切り分け
- caveat / disagreement retention
- reopen phase の切り分け

## 6. operational caveat

- gate interpretation:
- non-goal:

## 7. preparation conclusion

- fixed at this point:
- next action:
