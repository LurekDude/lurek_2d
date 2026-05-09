# IDEA — src/runtime

## Niezrobione TODO/WIP

- TODO(FEAT): rozszerzyć budżet zasobów poza tekstury (fonty, canvasy, shadery, inne pule).
- TODO(FEAT): rozważyć hot-reload części konfiguracji `conf.toml` (tylko pola mutowalne runtime).
- TODO(PERF): ograniczyć alokacje w `evict_lru_resources`.
- TODO(QUAL): podzielić bardzo duży `SharedState` na mniejsze podstany domenowe.
- TODO(REL): usunąć/uzasadnić `unsafe` lifetime extension w `messages::get_message` (lub przejść na bezpieczniejszy typ zwrotny).
- TODO(dedup): potwierdzić single source of truth dla `Clock` (`runtime` vs `timer`).
- TODO(dedup): ocenić czy konstrukcja/zarządzanie `EventQueue` powinny być skupione w `event`.
- TODO(helper): helper `config_inspector` do debugowego podglądu aktywnej konfiguracji.
