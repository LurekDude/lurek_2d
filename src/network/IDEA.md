# IDEA — src/network

## Niezrobione TODO/WIP

- TODO(FEAT): NAT punchthrough / relay support dla połączeń P2P poza LAN.
- TODO(FEAT): room/matchmaking API ponad obecnym discovery LAN.
- TODO(FEAT): szyfrowanie pakietów ENet (TLS obejmuje tylko HTTP/WS).
- TODO(QUAL): zweryfikować i ewentualnie poprawić domyślne `DEFAULT_PEERS = 166`.
- TODO(PERF): ograniczyć ryzyko blokady wątku sieciowego przez synchroniczne `tungstenite::connect`.
- TODO(PERF): rozważyć lepszą strategię pollingu niż liniowe iteracje po wszystkich połączeniach TCP.
- TODO(dedup): ocenić integrację `network::net_thread` z `thread::Channel` zamiast surowego `mpsc`.
- TODO(dedup): rozważyć konsolidację MessagePack (`network::message` vs potencjalny `serial`).
- TODO(helper): helper/library `net-sync` dla typowych wzorców synchronizacji encji i predykcji.
