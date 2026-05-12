//! Minimal relay/NAT punch helper payloads.

/// Relay ticket used to coordinate P2P attempts via an external relay service.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct RelayTicket {
    /// Room identifier.
    pub room_id: String,
    /// Peer identifier within the room.
    pub peer_id: String,
}

/// Encodes a relay ticket as an ASCII token.
pub fn encode_ticket(ticket: &RelayTicket) -> String {
    format!("{}|{}", ticket.room_id, ticket.peer_id)
}

/// Decodes a relay ticket token.
pub fn decode_ticket(token: &str) -> Option<RelayTicket> {
    let mut parts = token.split('|');
    let room_id = parts.next()?.to_string();
    let peer_id = parts.next()?.to_string();
    if room_id.is_empty() || peer_id.is_empty() {
        return None;
    }
    Some(RelayTicket { room_id, peer_id })
}

/// Creates a UDP punch probe payload between peers.
pub fn make_punch_probe(peer_id: &str) -> Vec<u8> {
    format!("LUREK_PUNCH:{}", peer_id).into_bytes()
}

/// Parses a UDP punch probe payload, returning the source peer id.
pub fn parse_punch_probe(data: &[u8]) -> Option<String> {
    let s = std::str::from_utf8(data).ok()?;
    let marker = "LUREK_PUNCH:";
    if !s.starts_with(marker) {
        return None;
    }
    Some(s[marker.len()..].to_string())
}
