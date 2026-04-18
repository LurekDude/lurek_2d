// WRONG — same-group cross-import (Platform Services)
use crate::render::GpuRenderer;    // from inside src/audio/
use crate::audio::Mixer;           // from inside src/render/ — FORBIDDEN (same-group Platform Services cross-import)

// WRONG — domain module importing lua_api
use crate::lua_api::something;     // from inside src/physics/

// CORRECT — importing from a lower group
use crate::runtime::SharedState;   // Platform Services importing Core Runtime
use crate::math::Vec2;             // any group importing Foundations
