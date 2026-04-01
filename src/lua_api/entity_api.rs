//! Registers the `luna.entity.*` ECS universe API.
//!
//! Exposes `Universe` as Lua UserData (`LuaUniverse`) with entity lifecycle,
//! component operations, querying, systems, tags, layers, and blueprints.

use std::cell::RefCell;
use std::rc::Rc;

use mlua::prelude::*;

use crate::entity::Universe;

use super::lua_types::{add_type_methods, LunaType};

// ---------------------------------------------------------------------------
// LuaUniverse
// ---------------------------------------------------------------------------

/// Lua wrapper around a [`Universe`] ECS world.
#[derive(Clone)]
struct LuaUniverse {
    inner: Rc<RefCell<Universe>>,
}

impl LunaType for LuaUniverse {
    const TYPE_NAME: &'static str = "Universe";
    const TYPE_HIERARCHY: &'static [&'static str] = &["Universe", "Object"];
}

impl LuaUserData for LuaUniverse {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods(methods);

        // === Entity Lifecycle ===

        methods.add_method("spawn", |_, this, ()| Ok(this.inner.borrow_mut().spawn()));

        methods.add_method("kill", |lua, this, id: u32| {
            this.inner.borrow_mut().kill(id, lua)
        });

        methods.add_method("isAlive", |_, this, id: u32| {
            Ok(this.inner.borrow().is_alive(id))
        });

        // === Component Operations ===

        methods.add_method(
            "set",
            |lua, this, (id, name, value): (u32, String, LuaValue)| {
                this.inner.borrow_mut().set_component(lua, id, &name, value)
            },
        );

        methods.add_method("get", |lua, this, (id, name): (u32, String)| {
            this.inner.borrow().get_component(lua, id, &name)
        });

        methods.add_method("has", |lua, this, (id, name): (u32, String)| {
            this.inner.borrow().has_component(lua, id, &name)
        });

        methods.add_method("remove", |lua, this, (id, name): (u32, String)| {
            this.inner.borrow().remove_component(lua, id, &name)
        });

        methods.add_method("getComponents", |lua, this, id: u32| {
            this.inner.borrow().get_component_names(lua, id)
        });

        // === Querying ===

        methods.add_method("query", |lua, this, args: LuaMultiValue| {
            let names: Vec<String> = args
                .into_iter()
                .filter_map(|v| match v {
                    LuaValue::String(s) => s.to_str().ok().map(|s| s.to_string()),
                    _ => None,
                })
                .collect();
            this.inner.borrow().query(lua, &names)
        });

        methods.add_method(
            "each",
            |lua, this, (name, callback): (String, LuaFunction)| {
                this.inner.borrow().each(lua, &name, callback)
            },
        );

        methods.add_method("getEntities", |_, this, ()| {
            Ok(this.inner.borrow().get_entities())
        });

        methods.add_method("getEntityCount", |_, this, ()| {
            Ok(this.inner.borrow().get_entity_count())
        });

        // === System Management ===

        methods.add_method("addSystem", |lua, this, system: LuaTable| {
            this.inner.borrow_mut().add_system(lua, system)
        });

        methods.add_method("removeSystem", |lua, this, system: LuaTable| {
            this.inner.borrow_mut().remove_system(lua, system)
        });

        methods.add_method("update", |lua, this, dt: f64| {
            let count = this.inner.borrow().get_system_count(lua)?;
            if count == 0 {
                return Ok(());
            }
            let store = this.inner.borrow().get_system_store(lua)?;
            let world_clone = this.clone();
            for i in 1..=count {
                let system: LuaTable = store.get(i)?;
                if let Ok(func) = system.get::<_, LuaFunction>("update") {
                    func.call::<_, ()>((system.clone(), world_clone.clone(), dt))?;
                }
            }
            Ok(())
        });

        methods.add_method("draw", |lua, this, ()| {
            let count = this.inner.borrow().get_system_count(lua)?;
            if count == 0 {
                return Ok(());
            }
            let store = this.inner.borrow().get_system_store(lua)?;
            let world_clone = this.clone();
            for i in 1..=count {
                let system: LuaTable = store.get(i)?;
                if let Ok(func) = system.get::<_, LuaFunction>("draw") {
                    func.call::<_, ()>((system.clone(), world_clone.clone()))?;
                }
            }
            Ok(())
        });

        methods.add_method("emit", |lua, this, args: LuaMultiValue| {
            let mut args_iter = args.into_iter();
            let event: String = match args_iter.next() {
                Some(LuaValue::String(s)) => s.to_str()?.to_string(),
                _ => {
                    return Err(LuaError::runtime(
                        "emit() requires event name as first argument",
                    ))
                }
            };
            let extra_args: Vec<LuaValue> = args_iter.collect();

            let count = this.inner.borrow().get_system_count(lua)?;
            if count == 0 {
                return Ok(());
            }
            let store = this.inner.borrow().get_system_store(lua)?;
            let world_clone = this.clone();
            for i in 1..=count {
                let system: LuaTable = store.get(i)?;
                if let Ok(func) = system.get::<_, LuaFunction>(event.as_str()) {
                    let mut call_args = Vec::with_capacity(2 + extra_args.len());
                    call_args.push(LuaValue::Table(system.clone()));
                    call_args.push(LuaValue::UserData(
                        lua.create_userdata(world_clone.clone())?,
                    ));
                    call_args.extend(extra_args.iter().cloned());
                    func.call::<_, ()>(LuaMultiValue::from_vec(call_args))?;
                }
            }
            Ok(())
        });

        methods.add_method("getSystemCount", |lua, this, ()| {
            this.inner.borrow().get_system_count(lua)
        });

        // === Lifecycle/Reset ===

        methods.add_method("clear", |lua, this, ()| this.inner.borrow_mut().clear(lua));

        methods.add_method("release", |lua, this, ()| {
            this.inner.borrow_mut().clear(lua)
        });

        // === String Tags ===

        methods.add_method("addTag", |_, this, (id, tag): (u32, String)| {
            this.inner.borrow_mut().add_tag(id, &tag);
            Ok(())
        });

        methods.add_method("removeTag", |_, this, (id, tag): (u32, String)| {
            this.inner.borrow_mut().remove_tag(id, &tag);
            Ok(())
        });

        methods.add_method("hasTag", |_, this, (id, tag): (u32, String)| {
            Ok(this.inner.borrow().has_tag(id, &tag))
        });

        methods.add_method("getTags", |_, this, id: u32| {
            Ok(this.inner.borrow().get_tags(id))
        });

        methods.add_method("getEntitiesByTag", |_, this, tag: String| {
            Ok(this.inner.borrow().get_entities_by_tag(&tag))
        });

        // === Layer System ===

        methods.add_method("setLayer", |_, this, (id, layer): (u32, i32)| {
            this.inner.borrow_mut().set_layer(id, layer);
            Ok(())
        });

        methods.add_method("getLayer", |_, this, id: u32| {
            Ok(this.inner.borrow().get_layer(id))
        });

        methods.add_method("getEntitiesByLayer", |_, this, layer: i32| {
            Ok(this.inner.borrow().get_entities_by_layer(layer))
        });

        methods.add_method("getEntitiesSorted", |_, this, ()| {
            Ok(this.inner.borrow().get_entities_sorted())
        });

        // === Bitmap Tags ===

        methods.add_method("defineTag", |_, this, name: String| {
            this.inner.borrow_mut().define_tag(&name)
        });

        methods.add_method("bitmapTag", |_, this, (id, name): (u32, String)| {
            this.inner.borrow_mut().bitmap_tag(id, &name)
        });

        methods.add_method("bitmapUntag", |_, this, (id, name): (u32, String)| {
            this.inner.borrow_mut().bitmap_untag(id, &name);
            Ok(())
        });

        methods.add_method("hasBitmapTag", |_, this, (id, name): (u32, String)| {
            Ok(this.inner.borrow().has_bitmap_tag(id, &name))
        });

        methods.add_method("queryBitmapTag", |_, this, name: String| {
            Ok(this.inner.borrow().query_bitmap_tag(&name))
        });

        methods.add_method("queryBitmapAny", |_, this, names: LuaTable| {
            let name_vec: Vec<String> = names
                .sequence_values::<String>()
                .collect::<LuaResult<Vec<String>>>()?;
            Ok(this.inner.borrow().query_bitmap_any(&name_vec))
        });

        methods.add_method("queryBitmapAll", |_, this, names: LuaTable| {
            let name_vec: Vec<String> = names
                .sequence_values::<String>()
                .collect::<LuaResult<Vec<String>>>()?;
            Ok(this.inner.borrow().query_bitmap_all(&name_vec))
        });

        methods.add_method("getBitmapTagBit", |_, this, name: String| {
            Ok(this.inner.borrow().get_bitmap_tag_bit(&name))
        });

        // === Blueprints ===

        methods.add_method(
            "defineBlueprint",
            |lua, this, (name, components): (String, LuaTable)| {
                this.inner
                    .borrow_mut()
                    .define_blueprint(lua, &name, components)
            },
        );

        methods.add_method(
            "extendBlueprint",
            |lua, this, (name, parent, overrides): (String, String, LuaTable)| {
                this.inner
                    .borrow_mut()
                    .extend_blueprint(lua, &name, &parent, overrides)
            },
        );

        methods.add_method(
            "spawnBlueprint",
            |lua, this, (name, overrides): (String, Option<LuaTable>)| {
                this.inner
                    .borrow_mut()
                    .spawn_blueprint(lua, &name, overrides)
            },
        );

        methods.add_method("hasBlueprint", |lua, this, name: String| {
            this.inner.borrow().has_blueprint(lua, &name)
        });

        methods.add_method("removeBlueprint", |lua, this, name: String| {
            this.inner.borrow().remove_blueprint(lua, &name)
        });

        methods.add_method("listBlueprints", |lua, this, ()| {
            this.inner.borrow().list_blueprints(lua)
        });

        methods.add_method("getBlueprintComponents", |lua, this, name: String| {
            this.inner.borrow().get_blueprint_components(lua, &name)
        });
    }
}

// ---------------------------------------------------------------------------
// Registration
// ---------------------------------------------------------------------------

/// Registers the `luna.entity` table with the `newUniverse` factory function.
///
/// # Parameters
/// - `lua` — `&Lua`.
/// - `luna` — `&LuaTable`.
///
/// # Returns
/// `LuaResult<()>`.
pub fn register(lua: &Lua, luna: &LuaTable) -> LuaResult<()> {
    let entity = lua.create_table()?;

    entity.set(
        "newUniverse",
        lua.create_function(|_lua, ()| {
            Ok(LuaUniverse {
                inner: Rc::new(RefCell::new(Universe::new())),
            })
        })?,
    )?;

    luna.set("entity", entity)?;
    Ok(())
}
