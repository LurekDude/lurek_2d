//! Lua bindings for `luna.crafting.*`.

use mlua::prelude::*;
use std::cell::RefCell;
use std::rc::Rc;

use crate::crafting::{CraftQueue, CraftSkill, Ingredient, Quality, Recipe, RecipeOutput, RecipeRegistry, Station, UpgradeNode, UpgradeTree};
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

        /// Returns the id.
        ///
        /// # Parameters
        /// - `v` — `string`.
        ///
        /// # Returns
        /// The current id.
        methods.add_method("getId", |_, this, ()| Ok(this.0.borrow().id.clone()));
        /// Returns the name.
        ///
        /// # Parameters
        /// - `v` — `string`.
        ///
        /// # Returns
        /// The current name.
        methods.add_method("getName", |_, this, ()| Ok(this.0.borrow().name.clone()));
        /// Sets the name.
        ///
        /// # Parameters
        /// - `v` — `string`.
        methods.add_method("setName", |_, this, v: String| { this.0.borrow_mut().name = v; Ok(()) });
        /// Returns the type.
        ///
        /// # Parameters
        /// - `v` — `number`.
        ///
        /// # Returns
        /// The current type.
        methods.add_method("getType", |_, this, ()| Ok(this.0.borrow().recipe_type.clone()));
        /// Returns the time.
        ///
        /// # Parameters
        /// - `name` — `string`.
        /// - `level` — `integer` optional.
        ///
        /// # Returns
        /// The current time.
        methods.add_method("getTime", |_, this, ()| Ok(this.0.borrow().time));
        /// Sets the time.
        ///
        /// # Parameters
        /// - `name` — `string`.
        /// - `level` — `integer` optional.
        methods.add_method("setTime", |_, this, v: f64| { this.0.borrow_mut().time = v; Ok(()) });
        /// Returns the station level.
        ///
        /// # Parameters
        /// - `name` — `string`.
        /// - `level` — `integer` optional.
        ///
        /// # Returns
        /// The current station level.
        methods.add_method("getStationLevel", |_, this, ()| Ok(this.0.borrow().station_level));
        /// Sets the station level.
        ///
        /// # Parameters
        /// - `name` — `string`.
        /// - `level` — `integer` optional.
        methods.add_method("setStationLevel", |_, this, v: u32| { this.0.borrow_mut().station_level = v; Ok(()) });
        /// Returns the station type.
        ///
        /// # Parameters
        /// - `name` — `string`.
        /// - `level` — `integer` optional.
        ///
        /// # Returns
        /// The current station type.
        methods.add_method("getStationType", |_, this, ()| Ok(this.0.borrow().station_type.clone()));
        /// Sets the station type.
        ///
        /// # Parameters
        /// - `name` — `string`.
        /// - `level` — `integer` optional.
        methods.add_method("setStationType", |_, this, v: String| { this.0.borrow_mut().station_type = v; Ok(()) });
        /// Returns the skill.
        ///
        /// # Parameters
        /// - `name` — `string`.
        /// - `level` — `integer` optional.
        ///
        /// # Returns
        /// The current skill.
        methods.add_method("getSkill", |_, this, ()| Ok(this.0.borrow().skill.clone()));
        /// Sets the skill.
        ///
        /// # Parameters
        /// - `name` — `string`.
        /// - `level` — `integer` optional.
        methods.add_method("setSkill", |_, this, (name, level): (String, Option<u32>)| {
            let mut b = this.0.borrow_mut();
            b.skill = name;
            b.skill_level = level.unwrap_or(0);
            Ok(())
        });
        /// Returns the skill xp.
        ///
        /// # Parameters
        /// - `v` — `number`.
        ///
        /// # Returns
        /// The current skill xp.
        methods.add_method("getSkillXp", |_, this, ()| Ok(this.0.borrow().skill_xp));
        /// Sets the skill xp.
        ///
        /// # Parameters
        /// - `v` — `number`.
        methods.add_method("setSkillXp", |_, this, v: f64| { this.0.borrow_mut().skill_xp = v; Ok(()) });
        /// Returns the description.
        ///
        /// # Parameters
        /// - `v` — `string`.
        ///
        /// # Returns
        /// The current description.
        methods.add_method("getDescription", |_, this, ()| Ok(this.0.borrow().description.clone()));
        /// Sets the description.
        ///
        /// # Parameters
        /// - `v` — `string`.
        methods.add_method("setDescription", |_, this, v: String| { this.0.borrow_mut().description = v; Ok(()) });
        /// Returns `true` if enabled.
        ///
        /// # Parameters
        /// - `v` — `boolean`.
        ///
        /// # Returns
        /// `boolean`.
        methods.add_method("isEnabled", |_, this, ()| Ok(this.0.borrow().enabled));
        /// Sets the enabled.
        ///
        /// # Parameters
        /// - `v` — `boolean`.
        methods.add_method("setEnabled", |_, this, v: bool| { this.0.borrow_mut().enabled = v; Ok(()) });
        /// Returns `true` if tag.
        ///
        /// # Parameters
        /// - `tag` — `string`.
        ///
        /// # Returns
        /// `boolean`.
        methods.add_method("hasTag", |_, this, tag: String| Ok(this.0.borrow().has_tag(&tag)));
        /// Adds tag to the collection.
        ///
        /// # Parameters
        /// - `tag` — `string`.
        methods.add_method("addTag", |_, this, tag: String| {
            this.0.borrow_mut().tags.push(tag); Ok(())
        });

        /// Returns the tags.
        ///
        /// # Parameters
        /// - `item_type` — `string`.
        /// - `qty` — `integer`.
        /// - `consumed` — `boolean` optional.
        ///
        /// # Returns
        /// The current tags.
        methods.add_method("getTags", |lua, this, ()| {
            let tags = this.0.borrow().get_tags().to_vec();
            let t = lua.create_table()?;
            for (i, tag) in tags.into_iter().enumerate() { t.set(i + 1, tag)?; }
            Ok(t)
        });
        /// Adds ingredient to the collection.
        ///
        /// # Parameters
        /// - `item_type` — `string`.
        /// - `qty` — `integer`.
        /// - `consumed` — `boolean` optional.
        methods.add_method("addIngredient", |_, this, (item_type, qty, consumed): (String, u32, Option<bool>)| {
            let mut ing = Ingredient::new(item_type, qty);
            ing.consumed = consumed.unwrap_or(true);
            this.0.borrow_mut().add_ingredient(ing);
            Ok(())
        });

        /// Adds output to the collection.
        ///
        /// # Parameters
        /// - `item_type` — `string`.
        /// - `qty` — `integer`.
        /// - `quality` — `string` optional.
        methods.add_method("addOutput", |_, this, (item_type, qty, quality): (String, u32, Option<String>)| {
            let mut out = RecipeOutput::new(item_type, qty);
            if let Some(q) = quality { out.quality = Quality::from_str(&q).unwrap_or(Quality::Normal); }
            this.0.borrow_mut().add_output(out);
            Ok(())
        });

        /// Returns the ingredients.
        ///
        /// # Returns
        /// The current ingredients.
        methods.add_method("getIngredients", |lua, this, ()| {
            let borrow = this.0.borrow();
            let t = lua.create_table()?;
            for (i, ing) in borrow.ingredients.iter().enumerate() {
                let row = lua.create_table()?;
                /// Item type on this Recipe.
                ///
                /// # Returns
                /// The result.
                row.set("itemType", ing.item_type.clone())?;
                /// Quantity on this Recipe.
                ///
                /// # Returns
                /// The result.
                row.set("quantity", ing.quantity)?;
                /// Consumed on this Recipe.
                ///
                /// # Returns
                /// The result.
                row.set("consumed", ing.consumed)?;
                t.set(i + 1, row)?;
            }
            Ok(t)
        });

        /// Returns the outputs.
        ///
        /// # Returns
        /// The current outputs.
        methods.add_method("getOutputs", |lua, this, ()| {
            let borrow = this.0.borrow();
            let t = lua.create_table()?;
            for (i, out) in borrow.outputs.iter().enumerate() {
                let row = lua.create_table()?;
                /// Item type on this Recipe.
                ///
                /// # Returns
                /// The result.
                row.set("itemType", out.item_type.clone())?;
                /// Quantity on this Recipe.
                ///
                /// # Returns
                /// The result.
                row.set("quantity", out.quantity)?;
                /// Quality on this Recipe.
                ///
                /// # Returns
                /// The result.
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

        /// Adds an entry to the collection.
        ///
        /// # Parameters
        /// - `recipe` — `userdata`.
        methods.add_method("add", |_, this, recipe: LuaAnyUserData| {
            let r = recipe.borrow::<LuaRecipe>()?.0.borrow().clone();
            this.0.borrow_mut().add(r);
            Ok(())
        });
        /// Returns the current value.
        ///
        /// # Parameters
        /// - `id` — `string`.
        ///
        /// # Returns
        /// The current get.
        methods.add_method("get", |_, this, id: String| {
            let borrow = this.0.borrow();
            let r = borrow.get(&id).cloned();
            drop(borrow);
            Ok(r.map(|r| LuaRecipe(Rc::new(RefCell::new(r)))))
        });
        /// Removes the entry from the collection.
        ///
        /// # Parameters
        /// - `id` — `string`.
        methods.add_method("remove", |_, this, id: String| {
            Ok(this.0.borrow_mut().remove(&id))
        });
        /// Returns the number of items.
        ///
        /// # Parameters
        /// - `item_type` — `string`.
        ///
        /// # Returns
        /// `integer`.
        methods.add_method("count", |_, this, ()| Ok(this.0.borrow().count()));
        /// Returns the ids.
        ///
        /// # Parameters
        /// - `item_type` — `string`.
        ///
        /// # Returns
        /// The current ids.
        methods.add_method("getIds", |lua, this, ()| {
            let borrow = this.0.borrow();
            let t = lua.create_sequence_from(borrow.ids().iter().cloned())?;
            Ok(t)
        });
        /// Find by output on this RecipeRegistry.
        ///
        /// # Parameters
        /// - `item_type` — `string`.
        methods.add_method("findByOutput", |lua, this, item_type: String| {
            let borrow = this.0.borrow();
            let ids: Vec<String> = borrow.find_by_output(&item_type).iter().map(|s| s.to_string()).collect();
            drop(borrow);
            let t = lua.create_sequence_from(ids.into_iter())?;
            Ok(t)
        });
        /// Find by ingredient on this RecipeRegistry.
        ///
        /// # Parameters
        /// - `item_type` — `string`.
        methods.add_method("findByIngredient", |lua, this, item_type: String| {
            let borrow = this.0.borrow();
            let ids: Vec<String> = borrow.find_by_ingredient(&item_type).iter().map(|s| s.to_string()).collect();
            drop(borrow);
            let t = lua.create_sequence_from(ids.into_iter())?;
            Ok(t)
        });
        /// Find by tag on this RecipeRegistry.
        ///
        /// # Parameters
        /// - `tag` — `string`.
        methods.add_method("findByTag", |lua, this, tag: String| {
            let ids = this.0.borrow().find_by_tag(&tag).iter().map(|s| s.to_string()).collect::<Vec<_>>();
            let t = lua.create_table()?;
            for (i, id) in ids.into_iter().enumerate() { t.set(i + 1, id)?; }
            Ok(t)
        });
        /// For station on this RecipeRegistry.
        ///
        /// # Parameters
        /// - `station_type` — `string`.
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

        /// Returns the type.
        ///
        /// # Parameters
        /// - `v` — `integer`.
        ///
        /// # Returns
        /// The current type.
        methods.add_method("getType", |_, this, ()| Ok(this.0.borrow().station_type.clone()));
        /// Returns the level.
        ///
        /// # Parameters
        /// - `v` — `integer`.
        ///
        /// # Returns
        /// The current level.
        methods.add_method("getLevel", |_, this, ()| Ok(this.0.borrow().level));
        /// Sets the level.
        ///
        /// # Parameters
        /// - `v` — `integer`.
        methods.add_method("setLevel", |_, this, v: u32| { this.0.borrow_mut().level = v; Ok(()) });
        /// Returns the name.
        ///
        /// # Parameters
        /// - `v` — `string`.
        ///
        /// # Returns
        /// The current name.
        methods.add_method("getName", |_, this, ()| Ok(this.0.borrow().name.clone()));
        /// Sets the name.
        ///
        /// # Parameters
        /// - `v` — `string`.
        methods.add_method("setName", |_, this, v: String| { this.0.borrow_mut().name = v; Ok(()) });
        /// Returns the speed multiplier.
        ///
        /// # Parameters
        /// - `v` — `number`.
        ///
        /// # Returns
        /// The current speed multiplier.
        methods.add_method("getSpeedMultiplier", |_, this, ()| Ok(this.0.borrow().speed_multiplier));
        /// Sets the speed multiplier.
        ///
        /// # Parameters
        /// - `v` — `number`.
        methods.add_method("setSpeedMultiplier", |_, this, v: f64| { this.0.borrow_mut().speed_multiplier = v; Ok(()) });
        /// Returns `true` if active.
        ///
        /// # Parameters
        /// - `v` — `boolean`.
        ///
        /// # Returns
        /// `boolean`.
        methods.add_method("isActive", |_, this, ()| Ok(this.0.borrow().active));
        /// Sets the active.
        ///
        /// # Parameters
        /// - `v` — `boolean`.
        methods.add_method("setActive", |_, this, v: bool| { this.0.borrow_mut().active = v; Ok(()) });
        /// Returns `true` if process.
        ///
        /// # Parameters
        /// - `recipe` — `userdata`.
        ///
        /// # Returns
        /// `boolean`.
        methods.add_method("canProcess", |_, this, recipe: LuaAnyUserData| {
            let rb = recipe.borrow::<LuaRecipe>()?;
            let recipe_inner = rb.0.borrow();
            Ok(this.0.borrow().can_process(&recipe_inner))
        });
        /// Effective time on this Station.
        ///
        /// # Parameters
        /// - `recipe` — `userdata`.
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

        /// Returns the name.
        ///
        /// # Parameters
        /// - `level` — `integer`.
        ///
        /// # Returns
        /// The current name.
        methods.add_method("getName", |_, this, ()| Ok(this.0.borrow().name.clone()));
        /// Returns the xp.
        ///
        /// # Parameters
        /// - `level` — `integer`.
        ///
        /// # Returns
        /// The current xp.
        methods.add_method("getXp", |_, this, ()| Ok(this.0.borrow().xp));
        /// Returns the level.
        ///
        /// # Parameters
        /// - `level` — `integer`.
        ///
        /// # Returns
        /// The current level.
        methods.add_method("getLevel", |_, this, ()| Ok(this.0.borrow().level));
        /// Returns the xp to next.
        ///
        /// # Parameters
        /// - `level` — `integer`.
        ///
        /// # Returns
        /// The current xp to next.
        methods.add_method("getXpToNext", |_, this, ()| Ok(this.0.borrow().get_xp_to_next()));
        /// Sets the level.
        ///
        /// # Parameters
        /// - `level` — `integer`.
        methods.add_method("setLevel", |_, this, level: u32| {
            this.0.borrow_mut().set_level(level);
            Ok(())
        });
        /// Adds xp to the collection.
        ///
        /// # Parameters
        /// - `amount` — `number`.
        methods.add_method("addXp", |_, this, amount: f64| Ok(this.0.borrow_mut().add_xp(amount)));
        /// Returns `true` if use.
        ///
        /// # Parameters
        /// - `recipe` — `userdata`.
        ///
        /// # Returns
        /// `boolean`.
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

        /// Enqueue on this CraftQueue.
        ///
        /// # Parameters
        /// - `recipe_id` — `string`.
        /// - `time` — `number`.
        /// - `qty` — `integer` optional.
        methods.add_method("enqueue", |_, this, (recipe_id, time, qty): (String, f64, Option<u32>)| {
            Ok(this.0.borrow_mut().enqueue(recipe_id, time, qty.unwrap_or(1)))
        });
        /// Cancels the current operation.
        ///
        /// # Parameters
        /// - `id` — `integer`.
        methods.add_method("cancel", |_, this, id: u32| {
            Ok(this.0.borrow_mut().cancel(id))
        });
        /// Advances the simulation by `dt` seconds.
        ///
        /// # Parameters
        /// - `dt` — `number`.
        methods.add_method("update", |lua, this, dt: f64| {
            let finished = this.0.borrow_mut().update(dt);
            let t = lua.create_sequence_from(finished.into_iter())?;
            Ok(t)
        });
        /// Collect completed on this CraftQueue.
        ///
        /// # Parameters
        /// - `id` — `integer`.
        methods.add_method("collectCompleted", |lua, this, ()| {
            let ids = this.0.borrow_mut().collect_completed();
            let t = lua.create_sequence_from(ids.into_iter())?;
            Ok(t)
        });
        /// Returns the job.
        ///
        /// # Parameters
        /// - `id` — `integer`.
        ///
        /// # Returns
        /// The current job.
        methods.add_method("getJob", |lua, this, id: u32| {
            let borrow = this.0.borrow();
            if let Some(job) = borrow.get_job(id) {
                let t = lua.create_table()?;
                /// Id on this CraftQueue.
                ///
                /// # Returns
                /// The result.
                t.set("id", job.id)?;
                /// Recipe id on this CraftQueue.
                ///
                /// # Returns
                /// The result.
                t.set("recipeId", job.recipe_id.clone())?;
                /// Progress on this CraftQueue.
                ///
                /// # Returns
                /// The result.
                t.set("progress", job.progress)?;
                /// Total time on this CraftQueue.
                ///
                /// # Returns
                /// The result.
                t.set("totalTime", job.total_time)?;
                /// Quantity on this CraftQueue.
                ///
                /// # Returns
                /// The result.
                t.set("quantity", job.quantity)?;
                /// Completed on this CraftQueue.
                ///
                /// # Returns
                /// The result.
                t.set("completed", job.completed)?;
                /// Paused on this CraftQueue.
                ///
                /// # Returns
                /// The result.
                t.set("paused", job.paused)?;
                /// Percent on this CraftQueue.
                ///
                /// # Returns
                /// The result.
                t.set("percent", job.percent())?;
                drop(borrow);
                Ok(LuaValue::Table(t))
            } else {
                Ok(LuaValue::Nil)
            }
        });
        /// Returns the number of items.
        ///
        /// # Returns
        /// `integer`.
        methods.add_method("count", |_, this, ()| Ok(this.0.borrow().count()));
        /// Returns `true` if full.
        ///
        /// # Returns
        /// `boolean`.
        methods.add_method("isFull", |_, this, ()| Ok(this.0.borrow().is_full()));
        /// Returns the max jobs.
        ///
        /// # Returns
        /// The current max jobs.
        methods.add_method("getMaxJobs", |_, this, ()| Ok(this.0.borrow().max_jobs()));
        /// Returns the ids.
        ///
        /// # Returns
        /// The current ids.
        methods.add_method("getIds", |lua, this, ()| {
            let ids = this.0.borrow().ids();
            let t = lua.create_sequence_from(ids.into_iter())?;
            Ok(t)
        });
        /// Removes all entries.
        ///
        /// # Returns
        /// The result.
        methods.add_method("clear", |_, this, ()| {
            this.0.borrow_mut().clear();
            Ok(())
        });
        /// Returns the all jobs.
        ///
        /// # Returns
        /// The current all jobs.
        methods.add_method("getAllJobs", |lua, this, ()| {
            let jobs = this.0.borrow().all_jobs();
            let t = lua.create_table()?;
            for (i, (id, recipe_id, qty, progress, paused)) in jobs.into_iter().enumerate() {
                let entry = lua.create_table()?;
                /// Id on this CraftQueue.
                ///
                /// # Returns
                /// The result.
                entry.set("id", id as u64)?;
                /// Recipe id on this CraftQueue.
                ///
                /// # Returns
                /// The result.
                entry.set("recipeId", recipe_id)?;
                /// Quantity on this CraftQueue.
                ///
                /// # Parameters
                /// - `id` — `integer`.
                /// - `paused` — `boolean`.
                entry.set("quantity", qty)?;
                /// Progress on this CraftQueue.
                ///
                /// # Parameters
                /// - `id` — `integer`.
                /// - `paused` — `boolean`.
                entry.set("progress", progress)?;
                /// Paused on this CraftQueue.
                ///
                /// # Parameters
                /// - `id` — `integer`.
                /// - `paused` — `boolean`.
                entry.set("paused", paused)?;
                t.set(i + 1, entry)?;
            }
            Ok(t)
        });
        /// Sets the job paused.
        ///
        /// # Parameters
        /// - `id` — `integer`.
        /// - `paused` — `boolean`.
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

        /// Returns the name.
        ///
        /// # Parameters
        /// - `id` — `string`.
        /// - `name` — `string`.
        /// - `prereqs` — `table` optional.
        ///
        /// # Returns
        /// The current name.
        methods.add_method("getName", |_, this, ()| Ok(this.0.borrow().name.clone()));
        /// Returns the number of items.
        ///
        /// # Parameters
        /// - `id` — `string`.
        /// - `name` — `string`.
        /// - `prereqs` — `table` optional.
        ///
        /// # Returns
        /// `integer`.
        methods.add_method("count", |_, this, ()| Ok(this.0.borrow().count()));
        /// Adds node to the collection.
        ///
        /// # Parameters
        /// - `id` — `string`.
        /// - `name` — `string`.
        /// - `prereqs` — `table` optional.
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
        /// Returns `true` if unlock.
        ///
        /// # Parameters
        /// - `id` — `string`.
        ///
        /// # Returns
        /// `boolean`.
        methods.add_method("canUnlock", |_, this, id: String| {
            Ok(this.0.borrow().can_unlock(&id))
        });
        /// Unlock on this UpgradeTree.
        ///
        /// # Parameters
        /// - `id` — `string`.
        methods.add_method("unlock", |_, this, id: String| {
            Ok(this.0.borrow_mut().unlock(&id))
        });
        /// Returns `true` if unlocked.
        ///
        /// # Parameters
        /// - `id` — `string`.
        ///
        /// # Returns
        /// `boolean`.
        methods.add_method("isUnlocked", |_, this, id: String| {
            let borrow = this.0.borrow();
            Ok(borrow.get_node(&id).map(|n| n.unlocked).unwrap_or(false))
        });
        /// Reset node on this UpgradeTree.
        ///
        /// # Parameters
        /// - `id` — `string`.
        methods.add_method("resetNode", |_, this, id: String| {
            Ok(this.0.borrow_mut().reset_node(&id))
        });
        /// Returns the unlocked ids.
        ///
        /// # Returns
        /// The current unlocked ids.
        methods.add_method("getUnlockedIds", |lua, this, ()| {
            let ids = this.0.borrow().get_unlocked_ids();
            let t = lua.create_table()?;
            for (i, id) in ids.into_iter().enumerate() { t.set(i + 1, id)?; }
            Ok(t)
        });
        /// Returns the node ids.
        ///
        /// # Parameters
        /// - `id` — `string`.
        /// - `cost_table` — `table`.
        ///
        /// # Returns
        /// The current node ids.
        methods.add_method("getNodeIds", |lua, this, ()| {
            let borrow = this.0.borrow();
            let t = lua.create_sequence_from(borrow.node_ids().iter().cloned())?;
            Ok(t)
        });
        /// Sets the node cost.
        ///
        /// # Parameters
        /// - `id` — `string`.
        /// - `cost_table` — `table`.
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
        /// Returns the node cost.
        ///
        /// # Parameters
        /// - `id` — `string`.
        ///
        /// # Returns
        /// The current node cost.
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

    /// Creates a new recipe instance.
    ///
    /// # Parameters
    /// - `id` — `string`.
    /// - `recipe_type` — `string` optional.
    module.set("newRecipe", lua.create_function(|_, (id, recipe_type): (String, Option<String>)| {
        let rt = recipe_type.unwrap_or_else(|| "shapeless".to_string());
        Ok(LuaRecipe(Rc::new(RefCell::new(Recipe::new(id, rt)))))
    })?)?;

    /// Creates a new registry instance.
    ///
    /// # Parameters
    /// - `station_type` — `string`.
    /// - `level` — `integer` optional.
    module.set("newRegistry", lua.create_function(|_, ()| {
        Ok(LuaRecipeRegistry(Rc::new(RefCell::new(RecipeRegistry::new()))))
    })?)?;

    /// Creates a new station instance.
    ///
    /// # Parameters
    /// - `station_type` — `string`.
    /// - `level` — `integer` optional.
    module.set("newStation", lua.create_function(|_, (station_type, level): (String, Option<u32>)| {
        Ok(LuaStation(Rc::new(RefCell::new(Station::new(station_type, level.unwrap_or(1))))))
    })?)?;

    /// Creates a new craft skill instance.
    ///
    /// # Parameters
    /// - `name` — `string`.
    module.set("newCraftSkill", lua.create_function(|_, name: String| {
        Ok(LuaCraftSkill(Rc::new(RefCell::new(CraftSkill::new(name)))))
    })?)?;

    /// Creates a new craft queue instance.
    ///
    /// # Parameters
    /// - `max_jobs` — `integer` optional.
    module.set("newCraftQueue", lua.create_function(|_, max_jobs: Option<usize>| {
        Ok(LuaCraftQueue(Rc::new(RefCell::new(CraftQueue::new(max_jobs.unwrap_or(10))))))
    })?)?;

    /// Creates a new upgrade tree instance.
    ///
    /// # Parameters
    /// - `name` — `string` optional.
    module.set("newUpgradeTree", lua.create_function(|_, name: Option<String>| {
        Ok(LuaUpgradeTree(Rc::new(RefCell::new(UpgradeTree::new(name.unwrap_or_default())))))
    })?)?;

    /// Crafting on this UpgradeTree.
    ///
    /// # Returns
    /// The result.
    luna.set("crafting", module)?;
    Ok(())
}
