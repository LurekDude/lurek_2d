"""Write src/lua_api/crafting_api.rs"""

content = r"""//! Lua bindings for `luna.crafting.*`.

use mlua::prelude::*;
use std::cell::RefCell;
use std::rc::Rc;

use crate::crafting::{
    CraftJob, CraftQueue, CraftSkill, Ingredient, Quality, Recipe, RecipeOutput,
    RecipeRegistry, Station, UpgradeNode, UpgradeTree,
};
use crate::lua_api::lua_types::{add_type_methods, LunaType};

// ─────────────────────────────────────────────────────────────────────────────
// LuaRecipe
// ─────────────────────────────────────────────────────────────────────────────

#[derive(Clone)]
pub struct LuaRecipe(pub Rc<RefCell<Recipe>>);

impl LunaType for LuaRecipe {
    const TYPE_NAME: &'static str = "Recipe";
    const TYPE_HIERARCHY: &'static [&'static str] = &["Recipe"];
}

impl LuaUserData for LuaRecipe {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods(methods);

        methods.add_method("getId", |_, this, ()| Ok(this.0.borrow().id.clone()));
        methods.add_method("getName", |_, this, ()| Ok(this.0.borrow().name.clone()));
        methods.add_method("setName", |_, this, v: String| { this.0.borrow_mut().name = v; Ok(()) });
        methods.add_method("getType", |_, this, ()| Ok(this.0.borrow().recipe_type.clone()));
        methods.add_method("getTime", |_, this, ()| Ok(this.0.borrow().time));
        methods.add_method("setTime", |_, this, v: f64| { this.0.borrow_mut().time = v; Ok(()) });
        methods.add_method("getStationLevel", |_, this, ()| Ok(this.0.borrow().station_level));
        methods.add_method("setStationLevel", |_, this, v: u32| { this.0.borrow_mut().station_level = v; Ok(()) });
        methods.add_method("getStationType", |_, this, ()| Ok(this.0.borrow().station_type.clone()));
        methods.add_method("setStationType", |_, this, v: String| { this.0.borrow_mut().station_type = v; Ok(()) });
        methods.add_method("getSkill", |_, this, ()| Ok(this.0.borrow().skill.clone()));
        methods.add_method("setSkill", |_, this, (name, level): (String, Option<u32>)| {
            let mut b = this.0.borrow_mut();
            b.skill = name;
            b.skill_level = level.unwrap_or(0);
            Ok(())
        });
        methods.add_method("getSkillXp", |_, this, ()| Ok(this.0.borrow().skill_xp));
        methods.add_method("setSkillXp", |_, this, v: f64| { this.0.borrow_mut().skill_xp = v; Ok(()) });
        methods.add_method("getDescription", |_, this, ()| Ok(this.0.borrow().description.clone()));
        methods.add_method("setDescription", |_, this, v: String| { this.0.borrow_mut().description = v; Ok(()) });
        methods.add_method("isEnabled", |_, this, ()| Ok(this.0.borrow().enabled));
        methods.add_method("setEnabled", |_, this, v: bool| { this.0.borrow_mut().enabled = v; Ok(()) });
        methods.add_method("hasTag", |_, this, tag: String| Ok(this.0.borrow().has_tag(&tag)));
        methods.add_method("addTag", |_, this, tag: String| {
            this.0.borrow_mut().tags.push(tag); Ok(())
        });

        methods.add_method("addIngredient", |_, this, (item_type, qty, consumed): (String, u32, Option<bool>)| {
            let mut ing = Ingredient::new(item_type, qty);
            ing.consumed = consumed.unwrap_or(true);
            this.0.borrow_mut().add_ingredient(ing);
            Ok(())
        });

        methods.add_method("addOutput", |_, this, (item_type, qty, quality): (String, u32, Option<String>)| {
            let mut out = RecipeOutput::new(item_type, qty);
            if let Some(q) = quality { out.quality = Quality::from_str(&q).unwrap_or(Quality::Normal); }
            this.0.borrow_mut().add_output(out);
            Ok(())
        });

        methods.add_method("getIngredients", |lua, this, ()| {
            let borrow = this.0.borrow();
            let t = lua.create_table()?;
            for (i, ing) in borrow.ingredients.iter().enumerate() {
                let row = lua.create_table()?;
                row.set("itemType", ing.item_type.clone())?;
                row.set("quantity", ing.quantity)?;
                row.set("consumed", ing.consumed)?;
                t.set(i + 1, row)?;
            }
            Ok(t)
        });

        methods.add_method("getOutputs", |lua, this, ()| {
            let borrow = this.0.borrow();
            let t = lua.create_table()?;
            for (i, out) in borrow.outputs.iter().enumerate() {
                let row = lua.create_table()?;
                row.set("itemType", out.item_type.clone())?;
                row.set("quantity", out.quantity)?;
                row.set("quality", out.quality.as_str())?;
                t.set(i + 1, row)?;
            }
            Ok(t)
        });
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// LuaRecipeRegistry
// ─────────────────────────────────────────────────────────────────────────────

#[derive(Clone)]
pub struct LuaRecipeRegistry(pub Rc<RefCell<RecipeRegistry>>);

impl LunaType for LuaRecipeRegistry {
    const TYPE_NAME: &'static str = "RecipeRegistry";
    const TYPE_HIERARCHY: &'static [&'static str] = &["RecipeRegistry"];
}

impl LuaUserData for LuaRecipeRegistry {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods(methods);

        methods.add_method("add", |_, this, recipe: LuaAnyUserData| {
            let r = recipe.borrow::<LuaRecipe>()?.0.borrow().clone();
            this.0.borrow_mut().add(r);
            Ok(())
        });
        methods.add_method("get", |_, this, id: String| {
            let borrow = this.0.borrow();
            let r = borrow.get(&id).cloned();
            drop(borrow);
            Ok(r.map(|r| LuaRecipe(Rc::new(RefCell::new(r)))))
        });
        methods.add_method("remove", |_, this, id: String| {
            Ok(this.0.borrow_mut().remove(&id))
        });
        methods.add_method("count", |_, this, ()| Ok(this.0.borrow().count()));
        methods.add_method("getIds", |lua, this, ()| {
            let borrow = this.0.borrow();
            let t = lua.create_sequence_from(borrow.ids().iter().cloned())?;
            Ok(t)
        });
        methods.add_method("findByOutput", |lua, this, item_type: String| {
            let borrow = this.0.borrow();
            let ids: Vec<String> = borrow.find_by_output(&item_type).iter().map(|s| s.to_string()).collect();
            drop(borrow);
            let t = lua.create_sequence_from(ids.into_iter())?;
            Ok(t)
        });
        methods.add_method("findByIngredient", |lua, this, item_type: String| {
            let borrow = this.0.borrow();
            let ids: Vec<String> = borrow.find_by_ingredient(&item_type).iter().map(|s| s.to_string()).collect();
            drop(borrow);
            let t = lua.create_sequence_from(ids.into_iter())?;
            Ok(t)
        });
        methods.add_method("forStation", |lua, this, station_type: String| {
            let borrow = this.0.borrow();
            let ids: Vec<String> = borrow.for_station(&station_type).iter().map(|s| s.to_string()).collect();
            drop(borrow);
            let t = lua.create_sequence_from(ids.into_iter())?;
            Ok(t)
        });
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// LuaStation
// ─────────────────────────────────────────────────────────────────────────────

#[derive(Clone)]
pub struct LuaStation(pub Rc<RefCell<Station>>);

impl LunaType for LuaStation {
    const TYPE_NAME: &'static str = "Station";
    const TYPE_HIERARCHY: &'static [&'static str] = &["Station"];
}

impl LuaUserData for LuaStation {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods(methods);

        methods.add_method("getType", |_, this, ()| Ok(this.0.borrow().station_type.clone()));
        methods.add_method("getLevel", |_, this, ()| Ok(this.0.borrow().level));
        methods.add_method("setLevel", |_, this, v: u32| { this.0.borrow_mut().level = v; Ok(()) });
        methods.add_method("getName", |_, this, ()| Ok(this.0.borrow().name.clone()));
        methods.add_method("setName", |_, this, v: String| { this.0.borrow_mut().name = v; Ok(()) });
        methods.add_method("getSpeedMultiplier", |_, this, ()| Ok(this.0.borrow().speed_multiplier));
        methods.add_method("setSpeedMultiplier", |_, this, v: f64| { this.0.borrow_mut().speed_multiplier = v; Ok(()) });
        methods.add_method("isActive", |_, this, ()| Ok(this.0.borrow().active));
        methods.add_method("setActive", |_, this, v: bool| { this.0.borrow_mut().active = v; Ok(()) });
        methods.add_method("canProcess", |_, this, recipe: LuaAnyUserData| {
            let rb = recipe.borrow::<LuaRecipe>()?;
            let recipe_inner = rb.0.borrow();
            Ok(this.0.borrow().can_process(&recipe_inner))
        });
        methods.add_method("effectiveTime", |_, this, recipe: LuaAnyUserData| {
            let rb = recipe.borrow::<LuaRecipe>()?;
            let recipe_inner = rb.0.borrow();
            Ok(this.0.borrow().effective_time(&recipe_inner))
        });
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// LuaCraftSkill
// ─────────────────────────────────────────────────────────────────────────────

#[derive(Clone)]
pub struct LuaCraftSkill(pub Rc<RefCell<CraftSkill>>);

impl LunaType for LuaCraftSkill {
    const TYPE_NAME: &'static str = "CraftSkill";
    const TYPE_HIERARCHY: &'static [&'static str] = &["CraftSkill"];
}

impl LuaUserData for LuaCraftSkill {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods(methods);

        methods.add_method("getName", |_, this, ()| Ok(this.0.borrow().name.clone()));
        methods.add_method("getXp", |_, this, ()| Ok(this.0.borrow().xp));
        methods.add_method("getLevel", |_, this, ()| Ok(this.0.borrow().level));
        methods.add_method("getXpToNext", |_, this, ()| Ok(this.0.borrow().get_xp_to_next()));
        methods.add_method("addXp", |_, this, amount: f64| Ok(this.0.borrow_mut().add_xp(amount)));
        methods.add_method("canUse", |_, this, recipe: LuaAnyUserData| {
            let rb = recipe.borrow::<LuaRecipe>()?;
            let recipe_inner = rb.0.borrow();
            Ok(this.0.borrow().can_use(&recipe_inner))
        });
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// LuaCraftQueue
// ─────────────────────────────────────────────────────────────────────────────

#[derive(Clone)]
pub struct LuaCraftQueue(pub Rc<RefCell<CraftQueue>>);

impl LunaType for LuaCraftQueue {
    const TYPE_NAME: &'static str = "CraftQueue";
    const TYPE_HIERARCHY: &'static [&'static str] = &["CraftQueue"];
}

impl LuaUserData for LuaCraftQueue {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods(methods);

        methods.add_method("enqueue", |_, this, (recipe_id, time, qty): (String, f64, Option<u32>)| {
            Ok(this.0.borrow_mut().enqueue(recipe_id, time, qty.unwrap_or(1)))
        });
        methods.add_method("cancel", |_, this, id: u32| {
            Ok(this.0.borrow_mut().cancel(id))
        });
        methods.add_method("update", |lua, this, dt: f64| {
            let finished = this.0.borrow_mut().update(dt);
            let t = lua.create_sequence_from(finished.into_iter())?;
            Ok(t)
        });
        methods.add_method("collectCompleted", |lua, this, ()| {
            let ids = this.0.borrow_mut().collect_completed();
            let t = lua.create_sequence_from(ids.into_iter())?;
            Ok(t)
        });
        methods.add_method("getJob", |lua, this, id: u32| {
            let borrow = this.0.borrow();
            if let Some(job) = borrow.get_job(id) {
                let t = lua.create_table()?;
                t.set("id", job.id)?;
                t.set("recipeId", job.recipe_id.clone())?;
                t.set("progress", job.progress)?;
                t.set("totalTime", job.total_time)?;
                t.set("quantity", job.quantity)?;
                t.set("completed", job.completed)?;
                t.set("paused", job.paused)?;
                t.set("percent", job.percent())?;
                drop(borrow);
                Ok(LuaValue::Table(t))
            } else {
                Ok(LuaValue::Nil)
            }
        });
        methods.add_method("count", |_, this, ()| Ok(this.0.borrow().count()));
        methods.add_method("isFull", |_, this, ()| Ok(this.0.borrow().is_full()));
        methods.add_method("getMaxJobs", |_, this, ()| Ok(this.0.borrow().max_jobs()));
        methods.add_method("getIds", |lua, this, ()| {
            let ids = this.0.borrow().ids();
            let t = lua.create_sequence_from(ids.into_iter())?;
            Ok(t)
        });
        methods.add_method("setJobPaused", |_, this, (id, paused): (u32, bool)| {
            if let Some(job) = this.0.borrow_mut().get_job_mut(id) { job.paused = paused; }
            Ok(())
        });
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// LuaUpgradeTree
// ─────────────────────────────────────────────────────────────────────────────

#[derive(Clone)]
pub struct LuaUpgradeTree(pub Rc<RefCell<UpgradeTree>>);

impl LunaType for LuaUpgradeTree {
    const TYPE_NAME: &'static str = "UpgradeTree";
    const TYPE_HIERARCHY: &'static [&'static str] = &["UpgradeTree"];
}

impl LuaUserData for LuaUpgradeTree {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods(methods);

        methods.add_method("getName", |_, this, ()| Ok(this.0.borrow().name.clone()));
        methods.add_method("count", |_, this, ()| Ok(this.0.borrow().count()));
        methods.add_method("addNode", |_, this, (id, name, prereqs): (String, String, Option<LuaTable>)| {
            let mut node = UpgradeNode::new(id, name);
            if let Some(t) = prereqs {
                for v in t.sequence_values::<String>() {
                    node.prerequisites.push(v?);
                }
            }
            this.0.borrow_mut().add_node(node);
            Ok(())
        });
        methods.add_method("canUnlock", |_, this, id: String| {
            Ok(this.0.borrow().can_unlock(&id))
        });
        methods.add_method("unlock", |_, this, id: String| {
            Ok(this.0.borrow_mut().unlock(&id))
        });
        methods.add_method("isUnlocked", |_, this, id: String| {
            let borrow = this.0.borrow();
            Ok(borrow.get_node(&id).map(|n| n.unlocked).unwrap_or(false))
        });
        methods.add_method("getNodeIds", |lua, this, ()| {
            let borrow = this.0.borrow();
            let t = lua.create_sequence_from(borrow.node_ids().iter().cloned())?;
            Ok(t)
        });
        methods.add_method("setNodeCost", |_, this, (id, cost_table): (String, LuaTable)| {
            let mut borrow = this.0.borrow_mut();
            if let Some(node) = borrow.get_node_mut(&id) {
                for pair in cost_table.pairs::<String, u32>() {
                    let (k, v) = pair?;
                    node.cost.insert(k, v);
                }
            }
            Ok(())
        });
        methods.add_method("getNodeCost", |lua, this, id: String| {
            let borrow = this.0.borrow();
            if let Some(node) = borrow.get_node(&id) {
                let t = lua.create_table()?;
                for (k, v) in &node.cost { t.set(k.as_str(), *v)?; }
                drop(borrow);
                Ok(LuaValue::Table(t))
            } else {
                Ok(LuaValue::Nil)
            }
        });
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// Register
// ─────────────────────────────────────────────────────────────────────────────

/// Register the `luna.crafting.*` table.
pub fn register(lua: &Lua, luna: &LuaTable) -> LuaResult<()> {
    let module = lua.create_table()?;

    module.set("newRecipe", lua.create_function(|_, (id, recipe_type): (String, Option<String>)| {
        let rt = recipe_type.unwrap_or_else(|| "shapeless".to_string());
        Ok(LuaRecipe(Rc::new(RefCell::new(Recipe::new(id, rt)))))
    })?)?;

    module.set("newRegistry", lua.create_function(|_, ()| {
        Ok(LuaRecipeRegistry(Rc::new(RefCell::new(RecipeRegistry::new()))))
    })?)?;

    module.set("newStation", lua.create_function(|_, (station_type, level): (String, Option<u32>)| {
        Ok(LuaStation(Rc::new(RefCell::new(Station::new(station_type, level.unwrap_or(1))))))
    })?)?;

    module.set("newCraftSkill", lua.create_function(|_, name: String| {
        Ok(LuaCraftSkill(Rc::new(RefCell::new(CraftSkill::new(name)))))
    })?)?;

    module.set("newCraftQueue", lua.create_function(|_, max_jobs: Option<usize>| {
        Ok(LuaCraftQueue(Rc::new(RefCell::new(CraftQueue::new(max_jobs.unwrap_or(10))))))
    })?)?;

    module.set("newUpgradeTree", lua.create_function(|_, name: Option<String>| {
        Ok(LuaUpgradeTree(Rc::new(RefCell::new(UpgradeTree::new(name.unwrap_or_default())))))
    })?)?;

    luna.set("crafting", module)?;
    Ok(())
}
"""

with open('src/lua_api/crafting_api.rs', 'w', encoding='utf-8') as f:
    f.write(content)
print('crafting_api.rs written')
