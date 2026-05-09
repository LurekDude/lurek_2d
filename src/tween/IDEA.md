# IDEA — src/tween

## Niezrobione TODO/WIP

- TODO(FEAT): relative tweens (`:relative()`/delta mode).
- TODO(FEAT): coroutine await/yield na zakończenie tweena/sekwencji.
- TODO(FEAT): introspekcja runtime tweena (`progress`, `elapsed`, `remaining`, pola).
- TODO(PERF): ograniczyć per-tick koszty lookupów i pracy na registry key.
- TODO(REL): łagodne auto-cancel gdy target tabeli znika (GC/despawn).
- TODO(TEST): edge-case testy `TweenState` (zero duration, pause/resume, ekstremalne dt).
- TODO(TEST-LUA): rozszerzyć testy sequence/spring/custom easing behavior.
- TODO(dedup): doprecyzować granicę `tween` vs `animation` (timeline/clip playback).
- TODO(helper): helpery `tween_chain` i `tween_color` dla częstych wzorców.
