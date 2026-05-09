# IDEA — src/pipeline

## Niezrobione TODO/WIP

- TODO(FEAT): uruchamianie niezależnych stage'y DAG równolegle (thread/worker dispatch), nie tylko sekwencyjnie.
- TODO(FEAT): pełne runtime branching if/else na poziomie grafu (poza prostym `addConditional` skip).
- TODO(PERF): ograniczyć klonowanie stringów w topological sort / parallel groups.
- TODO(dedup): wyjaśnić naming i odpowiedzialność `pipeline` vs pipeline po stronie renderingu.
- TODO(dedup): ocenić overlap `pipeline` z sekwencjami w `automation`.
- TODO(helper): helper/builder do deklaratywnego składania pipeline z tabel.
- TODO(plugin): utrzymać jako TIER-2-PLUGIN (feature-gate), chyba że zapadnie decyzja o pełnej migracji do library Lua.
