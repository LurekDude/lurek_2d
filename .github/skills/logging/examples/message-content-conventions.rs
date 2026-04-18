// GOOD: includes module context, key values, and what failed
log::warn!("physics: body {:?} placed outside world bounds ({:.1}, {:.1})", key, x, y);

// GOOD: info lifecycle event with details
log::info!("audio: loaded '{}' ({:.1} KB, {:?})", path, kb, source_type);

// BAD: no context � useless in a log file
log::debug!("done");

// BAD: panic-style � use error! not panic for recoverable errors
log::error!("unexpected state");
panic!("unexpected state");   // don't duplicate with a panic
