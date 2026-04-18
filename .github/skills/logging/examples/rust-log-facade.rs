use log::{error, warn, info, debug, trace};

// Error: unrecoverable � frame will abort or session will fail
log::error!("failed to load texture '{}': {}", path, e);

// Warn: recoverable � engine continues with degraded behaviour
log::warn!("audio device not found, running headless");

// Info: lifecycle events � startup, shutdown, resource load
log::info!("Lua VM created with {} API modules", count);

// Debug: per-call detail � disabled in release by default
log::debug!("draw command queue flushed: {} commands", n);

// Trace: per-frame or per-iteration � very hot, use sparingly
log::trace!("vertex buffer updated: {} bytes", size);
