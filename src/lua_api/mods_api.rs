use super::SharedState;
use crate::mods::{ModInfo, ModManager};
use mlua::prelude::*;
use std::cell::RefCell;
use std::collections::{HashMap, HashSet};
use std::rc::Rc;
fn mod_info_from_table(tbl: &LuaTable) -> LuaResult<ModInfo> {
    let id: String = tbl
        .get::<_, String>("id")
        .map_err(|_| LuaError::RuntimeError("newMod requires 'id' field".into()))?;
    let dependencies = tbl
        .get::<_, LuaTable>("dependencies")
        .map(|deps| deps.sequence_values::<String>().flatten().collect())
        .unwrap_or_default();
    let capabilities = tbl
        .get::<_, LuaTable>("capabilities")
        .map(|caps| caps.sequence_values::<String>().flatten().collect())
        .unwrap_or_default();
    let config_schema = tbl
        .get::<_, LuaTable>("config_schema")
        .map(|schema| {
            schema
                .sequence_values::<LuaTable>()
                .flatten()
                .filter_map(|entry| {
                    let key: String = entry.get("key").ok()?;
                    let type_hint: String = entry.get("type").unwrap_or_else(|_| "any".into());
                    let default: String = entry.get("default").unwrap_or_default();
                    Some((key, type_hint, default))
                })
                .collect()
        })
        .unwrap_or_default();
    let asset_paths = tbl
        .get::<_, LuaTable>("assets")
        .map(|assets| assets.sequence_values::<String>().flatten().collect())
        .unwrap_or_default();
    let mut info = ModInfo::from_parts(
        id,
        tbl.get::<_, String>("name").ok(),
        tbl.get::<_, String>("version").ok(),
        tbl.get::<_, String>("author").ok(),
        tbl.get::<_, String>("description").ok(),
        tbl.get::<_, i32>("priority").ok(),
        dependencies,
    );
    info.api_version = tbl.get::<_, String>("api_version").ok();
    info.capabilities = capabilities;
    info.config_schema = config_schema;
    info.asset_paths = asset_paths;
    info.signature = tbl.get::<_, String>("signature").ok();
    Ok(info)
}
fn mod_info_to_table<'a>(lua: &'a Lua, info: &ModInfo) -> LuaResult<LuaTable<'a>> {
    let t = lua.create_table()?;
    t.set("id", info.id.as_str())?;
    t.set("name", info.name.as_str())?;
    t.set("version", info.version.as_str())?;
    t.set("author", info.author.as_str())?;
    t.set("description", info.description.as_str())?;
    t.set("priority", info.priority)?;
    t.set("enabled", info.enabled)?;
    t.set("loaded", info.loaded)?;
    if let Some(ref p) = info.path {
        t.set("path", p.as_str() as &str)?;
    }
    if let Some(ref av) = info.api_version {
        t.set("api_version", av.as_str())?;
    }
    let caps = {
        let c = lua.create_table()?;
        for (i, cap) in info.capabilities.iter().enumerate() {
            c.set(i + 1, cap.as_str())?;
        }
        c
    };
    t.set("capabilities", caps)?;
    let schema = {
        let s = lua.create_table()?;
        for (i, (key, type_hint, default)) in info.config_schema.iter().enumerate() {
            let entry = lua.create_table()?;
            entry.set("key", key.as_str())?;
            entry.set("type", type_hint.as_str())?;
            entry.set("default", default.as_str())?;
            s.set(i + 1, entry)?;
        }
        s
    };
    t.set("config_schema", schema)?;
    let assets = {
        let a = lua.create_table()?;
        for (i, asset) in info.asset_paths.iter().enumerate() {
            a.set(i + 1, asset.as_str())?;
        }
        a
    };
    t.set("assets", assets)?;
    if let Some(ref signature) = info.signature {
        t.set("signature", signature.as_str())?;
    }
    let deps = lua.create_table()?;
    for (i, dep) in info.dependencies.iter().enumerate() {
        deps.set(i + 1, dep.as_str() as &str)?;
    }
    t.set("dependencies", deps)?;
    Ok(t)
}
fn mod_infos_to_table<'a, 'lua>(
    lua: &'lua Lua,
    infos: impl Iterator<Item = &'a ModInfo>,
) -> LuaResult<LuaTable<'lua>> {
    let t = lua.create_table()?;
    for (i, info) in infos.enumerate() {
        t.set(i + 1, mod_info_to_table(lua, info)?)?;
    }
    Ok(t)
}
fn string_slice_to_table<'a>(lua: &'a Lua, items: &[String]) -> LuaResult<LuaTable<'a>> {
    let t = lua.create_table()?;
    for (i, s) in items.iter().enumerate() {
        t.set(i + 1, s.as_str())?;
    }
    Ok(t)
}
pub struct LuaMod {
    pub(super) inner: ModInfo,
    hooks: HashMap<String, LuaRegistryKey>,
    config: Option<LuaRegistryKey>,
}
impl LuaMod {
    pub fn new(inner: ModInfo) -> Self {
        Self {
            inner,
            hooks: HashMap::new(),
            config: None,
        }
    }
}
impl LuaUserData for LuaMod {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("getId", |_, this, ()| Ok(this.inner.id.clone()));
        methods.add_method("getName", |_, this, ()| Ok(this.inner.name.clone()));
        methods.add_method("getVersion", |_, this, ()| Ok(this.inner.version.clone()));
        methods.add_method("getAuthor", |_, this, ()| Ok(this.inner.author.clone()));
        methods.add_method("getDescription", |_, this, ()| {
            Ok(this.inner.description.clone())
        });
        methods.add_method("getDependencies", |lua, this, ()| {
            string_slice_to_table(lua, &this.inner.dependencies)
        });
        methods.add_method("getPriority", |_, this, ()| Ok(this.inner.priority));
        methods.add_method("isEnabled", |_, this, ()| Ok(this.inner.enabled));
        methods.add_method_mut("setEnabled", |_, this, enabled: bool| {
            this.inner.enabled = enabled;
            Ok(())
        });
        methods.add_method("isLoaded", |_, this, ()| Ok(this.inner.loaded));
        methods.add_method("getApiVersion", |_, this, ()| {
            Ok(this.inner.api_version.clone())
        });
        methods.add_method_mut("setApiVersion", |_, this, api_version: String| {
            this.inner.api_version = Some(api_version);
            Ok(())
        });
        methods.add_method("getCapabilities", |lua, this, ()| {
            string_slice_to_table(lua, &this.inner.capabilities)
        });
        methods.add_method_mut("setCapabilities", |_, this, caps: LuaTable| {
            this.inner.capabilities = caps.sequence_values::<String>().flatten().collect();
            Ok(())
        });
        methods.add_method("getConfigSchema", |lua, this, ()| {
            let t = lua.create_table()?;
            for (i, (key, type_hint, default)) in this.inner.config_schema.iter().enumerate() {
                let entry = lua.create_table()?;
                entry.set("key", key.as_str())?;
                entry.set("type", type_hint.as_str())?;
                entry.set("default", default.as_str())?;
                t.set(i + 1, entry)?;
            }
            Ok(t)
        });
        methods.add_method_mut("setConfigSchema", |_, this, schema: LuaTable| {
            this.inner.config_schema = schema
                .sequence_values::<LuaTable>()
                .flatten()
                .filter_map(|entry| {
                    let key: String = entry.get("key").ok()?;
                    let type_hint: String = entry.get("type").unwrap_or_else(|_| "any".into());
                    let default: String = entry.get("default").unwrap_or_default();
                    Some((key, type_hint, default))
                })
                .collect();
            Ok(())
        });
        methods.add_method_mut(
            "setHook",
            |lua, this, (name, func): (String, LuaFunction)| {
                if let Some(old_key) = this.hooks.remove(&name) {
                    lua.remove_registry_value(old_key)?;
                }
                let key = lua.create_registry_value(func)?;
                this.hooks.insert(name, key);
                Ok(())
            },
        );
        methods.add_method("getHook", |lua, this, name: String| {
            if let Some(key) = this.hooks.get(&name) {
                let func = lua.registry_value::<LuaFunction>(key)?;
                Ok(LuaValue::Function(func))
            } else {
                Ok(LuaValue::Nil)
            }
        });
        methods.add_method("hasHook", |_, this, name: String| {
            Ok(this.hooks.contains_key(&name))
        });
        methods.add_method("getHookNames", |lua, this, ()| {
            let t = lua.create_table()?;
            for (i, name) in this.hooks.keys().enumerate() {
                t.set(i + 1, name.as_str())?;
            }
            Ok(t)
        });
        methods.add_method_mut("setConfig", |lua, this, value: LuaValue| {
            if let Some(old_key) = this.config.take() {
                lua.remove_registry_value(old_key)?;
            }
            let key = lua.create_registry_value(value)?;
            this.config = Some(key);
            Ok(())
        });
        methods.add_method("getConfig", |lua, this, ()| {
            if let Some(key) = &this.config {
                lua.registry_value::<LuaValue>(key)
            } else {
                Ok(LuaValue::Nil)
            }
        });
        methods.add_method_mut("releaseRefs", |lua, this, ()| {
            for (_, key) in this.hooks.drain() {
                lua.remove_registry_value(key)?;
            }
            if let Some(key) = this.config.take() {
                lua.remove_registry_value(key)?;
            }
            Ok(())
        });
        methods.add_meta_method(LuaMetaMethod::ToString, |_, this, ()| {
            Ok(format!("Mod({})", this.inner.id))
        });
        methods.add_method("type", |_, _, ()| Ok("LMod"));
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LMod" || name == "Object")
        });
    }
}
pub struct LuaModManager {
    inner: ModManager,
}
impl LuaModManager {
    pub fn new() -> Self {
        Self {
            inner: ModManager::new(),
        }
    }
}
impl Default for LuaModManager {
    fn default() -> Self {
        Self::new()
    }
}
impl LuaUserData for LuaModManager {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method_mut("registerMod", |_, this, ud: LuaAnyUserData| {
            let info = ud.borrow::<LuaMod>()?.inner.clone();
            this.inner.register_mod(info);
            Ok(())
        });
        methods.add_method_mut("unregisterMod", |_, this, mod_id: String| {
            Ok(this.inner.unregister_mod(&mod_id))
        });
        methods.add_method("hasMod", |_, this, mod_id: String| {
            Ok(this.inner.has_mod(&mod_id))
        });
        methods.add_method("getModCount", |_, this, ()| Ok(this.inner.mod_count()));
        methods.add_method("getAllMods", |lua, this, ()| {
            mod_infos_to_table(lua, this.inner.all_mods().iter())
        });
        methods.add_method("getModsByCapability", |lua, this, capability: String| {
            mod_infos_to_table(
                lua,
                this.inner.get_mods_by_capability(&capability).into_iter(),
            )
        });
        methods.add_method("getLoadOrder", |lua, this, ()| {
            let order = this.inner.load_order();
            mod_infos_to_table(lua, order.into_iter())
        });
        methods.add_method("validateDependencies", |lua, this, ()| {
            string_slice_to_table(lua, &this.inner.validate_dependencies())
        });
        methods.add_method("hasCircularDependencies", |_, this, ()| {
            Ok(this.inner.has_circular_dependencies())
        });
        methods.add_method_mut("setLoadOrder", |_, this, order_table: LuaTable| {
            let order: Vec<String> = order_table.sequence_values::<String>().flatten().collect();
            this.inner.set_load_order(order);
            Ok(())
        });
        methods.add_method_mut("clearLoadOrder", |_, this, ()| {
            this.inner.clear_load_order();
            Ok(())
        });
        methods.add_method_mut("scanFolder", |lua, this, path: String| {
            let found = this.inner.scan_folder(&path);
            mod_infos_to_table(lua, found.iter())
        });
        methods.add_method("getModPath", |_, this, mod_id: String| {
            Ok(this.inner.get_mod(&mod_id).and_then(|m| m.path.clone()))
        });
        methods.add_method_mut("markForReload", |_, this, mod_id: String| {
            Ok(this.inner.mark_for_reload(&mod_id))
        });
        methods.add_method("getReloadQueue", |lua, this, ()| {
            string_slice_to_table(lua, this.inner.get_reload_queue())
        });
        methods.add_method_mut("clearReloadQueue", |_, this, ()| {
            this.inner.clear_reload_queue();
            Ok(())
        });
        methods.add_method_mut("processReloadQueue", |lua, this, ()| {
            string_slice_to_table(lua, &this.inner.process_reload_queue())
        });
        methods.add_meta_method(LuaMetaMethod::ToString, |_, this, ()| {
            Ok(format!("ModManager({} mods)", this.inner.mod_count()))
        });
        methods.add_method("type", |_, _, ()| Ok("LModManager"));
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LModManager" || name == "Object")
        });
    }
}
pub struct LuaContentRegistry {
    entries: HashMap<String, HashMap<String, LuaRegistryKey>>,
    types: HashSet<String>,
}
impl LuaContentRegistry {
    #[allow(clippy::new_without_default)]
    pub fn new() -> Self {
        Self {
            entries: HashMap::new(),
            types: HashSet::new(),
        }
    }
}
impl LuaUserData for LuaContentRegistry {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method_mut("registerType", |_, this, type_name: String| {
            this.types.insert(type_name.clone());
            this.entries.entry(type_name).or_default();
            Ok(())
        });
        methods.add_method_mut(
            "register",
            |lua, this, (type_name, id, obj): (String, String, LuaValue)| {
                if !this.types.contains(&type_name) {
                    return Err(LuaError::RuntimeError(format!(
                        "content type '{}' not registered",
                        type_name
                    )));
                }
                let key = lua.create_registry_value(obj)?;
                this.entries.entry(type_name).or_default().insert(id, key);
                Ok(())
            },
        );
        methods.add_method("get", |lua, this, (type_name, id): (String, String)| {
            let val = this
                .entries
                .get(&type_name)
                .and_then(|m| m.get(&id))
                .map(|key| lua.registry_value::<LuaValue>(key))
                .transpose()?
                .unwrap_or(LuaValue::Nil);
            Ok(val)
        });
        methods.add_method("getAll", |lua, this, type_name: String| {
            let tbl = lua.create_table()?;
            if let Some(map) = this.entries.get(&type_name) {
                for (id, key) in map {
                    let val: LuaValue = lua.registry_value(key)?;
                    tbl.set(id.as_str(), val)?;
                }
            }
            Ok(tbl)
        });
        methods.add_method("getTypes", |lua, this, ()| {
            let tbl = lua.create_table()?;
            for (i, t) in this.types.iter().enumerate() {
                tbl.set(i + 1, t.as_str())?;
            }
            Ok(tbl)
        });
        methods.add_meta_method(LuaMetaMethod::ToString, |_, this, ()| {
            Ok(format!("ContentRegistry({} types)", this.types.len()))
        });
        methods.add_method("type", |_, _, ()| Ok("LContentRegistry"));
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LContentRegistry" || name == "Object")
        });
    }
}
pub fn register(lua: &Lua, lurek: &LuaTable, _state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let tbl = lua.create_table()?;
    tbl.set(
        "newMod",
        lua.create_function(|lua, info: LuaTable| {
            let mod_info = mod_info_from_table(&info)?;
            lua.create_userdata(LuaMod::new(mod_info))
        })?,
    )?;
    tbl.set(
        "newModManager",
        lua.create_function(|lua, ()| lua.create_userdata(LuaModManager::new()))?,
    )?;
    tbl.set(
        "newRegistry",
        lua.create_function(|lua, ()| lua.create_userdata(LuaContentRegistry::new()))?,
    )?;
    tbl.set(
        "checkApiVersion",
        lua.create_function(|lua, (mod_ud, host_version): (LuaAnyUserData, String)| {
            let api_ver = {
                let m = mod_ud.borrow::<LuaMod>()?;
                m.inner.api_version.clone()
            };
            let required = match api_ver {
                None => return Ok((true, LuaValue::Nil)),
                Some(v) => v,
            };
            let parse = |s: &str| -> Option<(u32, u32, u32)> {
                let mut parts = s.splitn(3, '.');
                let maj = parts.next()?.parse::<u32>().ok()?;
                let min = parts.next()?.parse::<u32>().ok()?;
                let pat = parts
                    .next()
                    .and_then(|p| p.parse::<u32>().ok())
                    .unwrap_or(0);
                Some((maj, min, pat))
            };
            let (req_maj, req_min, _) = match parse(&required) {
                Some(v) => v,
                None => {
                    return Ok((
                        false,
                        LuaValue::String(
                            lua.create_string(
                                format!("mod api_version '{}' is not a valid semver", required)
                                    .as_bytes(),
                            )?,
                        ),
                    ))
                }
            };
            let (host_maj, host_min, _) = match parse(&host_version) {
                Some(v) => v,
                None => {
                    return Ok((
                        false,
                        LuaValue::String(
                            lua.create_string(
                                format!(
                                    "host api_version '{}' is not a valid semver",
                                    host_version
                                )
                                .as_bytes(),
                            )?,
                        ),
                    ))
                }
            };
            if req_maj != host_maj {
                return Ok((
                    false,
                    LuaValue::String(
                        lua.create_string(
                            format!(
                                "mod requires API {}.x but host provides {}.x",
                                req_maj, host_maj
                            )
                            .as_bytes(),
                        )?,
                    ),
                ));
            }
            if req_min > host_min {
                return Ok((
                    false,
                    LuaValue::String(
                        lua.create_string(
                            format!(
                                "mod requires API {}.{}.x but host provides {}.{}.x",
                                req_maj, req_min, host_maj, host_min
                            )
                            .as_bytes(),
                        )?,
                    ),
                ));
            }
            Ok((true, LuaValue::Nil))
        })?,
    )?;
    lurek.set("mods", tbl)?;
    Ok(())
}
