# IDEA — src/thread

## Niezrobione TODO/WIP

- TODO(FEAT): bounded channels z backpressure (limit pojemności, zachowanie przy overflow).
- TODO(FEAT): lepsza introspekcja dostępnego API worker VM (co jest worker-safe).
- TODO(FEAT): composable promise chaining (`Promise:chain`/podobny mechanizm).
- TODO(PERF): zoptymalizować ścieżki `demand()`/wait pod duże obciążenie i długie timeouty.
- TODO(QUAL): zwiększyć odporność `ThreadPool::join` na zawieszonych workerów.
- TODO(TEST): stress-testy MPMC dla dużej konkurencji producer/consumer.
- TODO(dedup): ocenić overlap kolejek `thread::Channel` vs `event::EventQueue`.
- TODO(helper): helper `lurek.thread.async(fn)` do prostszego uruchamiania zadań asynchronicznych.
