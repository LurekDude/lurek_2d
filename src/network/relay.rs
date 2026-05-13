#[derive(Debug, Clone, PartialEq, Eq)]
pub struct RelayTicket {
    pub room_id: String,
    pub peer_id: String,
}
pub fn encode_ticket(ticket: &RelayTicket) -> String {
    format!("{}|{}", ticket.room_id, ticket.peer_id)
}
pub fn decode_ticket(token: &str) -> Option<RelayTicket> {
    let mut parts = token.split('|');
    let room_id = parts.next()?.to_string();
    let peer_id = parts.next()?.to_string();
    if room_id.is_empty() || peer_id.is_empty() {
        return None;
    }
    Some(RelayTicket { room_id, peer_id })
}
pub fn make_punch_probe(peer_id: &str) -> Vec<u8> {
    format!("LUREK_PUNCH:{}", peer_id).into_bytes()
}
pub fn parse_punch_probe(data: &[u8]) -> Option<String> {
    let s = std::str::from_utf8(data).ok()?;
    let marker = "LUREK_PUNCH:";
    if !s.starts_with(marker) {
        return None;
    }
    Some(s[marker.len()..].to_string())
}
