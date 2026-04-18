// Temporary diagnostic: add to a hot path to trace data flow
log::debug!("[DEBUG] value at {} = {:?}", line!(), my_value);

// Remove before commit. Use RUST_LOG=lurek2d=debug to see debug! output.
// Never leave log::debug! in production hot paths (per-frame).
