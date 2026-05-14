
/// Relay session ticket identifying a room and the connecting peer.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct RelayTicket {
    /// Room identifier assigned by the relay server.
    pub room_id: String,
    /// Peer identifier assigned by the relay server.
    pub peer_id: String,
}
/// Encode a `RelayTicket` as a `"room_id|peer_id"` string for wire transport.
pub fn encode_ticket(ticket: &RelayTicket) -> String {
    format!("{}|{}", ticket.room_id, ticket.peer_id)
}
/// Parse a `"room_id|peer_id"` token back into a `RelayTicket`; returns `None` if either part is empty.
pub fn decode_ticket(token: &str) -> Option<RelayTicket> {
    let mut parts = token.split('|');
    let room_id = parts.next()?.to_string();
    let peer_id = parts.next()?.to_string();
    if room_id.is_empty() || peer_id.is_empty() {
        return None;
    }
    Some(RelayTicket { room_id, peer_id })
}
/// Build a UDP hole-punch probe payload for the given `peer_id`.
pub fn make_punch_probe(peer_id: &str) -> Vec<u8> {
    format!("LUREK_PUNCH:{}", peer_id).into_bytes()
}
/// Parse a UDP hole-punch probe and return the embedded peer ID; returns `None` if the magic prefix is absent.
pub fn parse_punch_probe(data: &[u8]) -> Option<String> {
    let s = std::str::from_utf8(data).ok()?;
    let marker = "LUREK_PUNCH:";
    if !s.starts_with(marker) {
        return None;
    }
    Some(s[marker.len()..].to_string())
}
