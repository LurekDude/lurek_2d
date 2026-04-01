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

        /// Returns the unique string identifier of this recipe.
        ///
        /// # Returns
        /// `string` — recipe ID.
        methods.add_method("getId", |_, this, ()| Ok(this.0.borrow().id.clone()));
        /// Returns the human-readable display name of this recipe.
        ///
        /// # Returns
        /// `string`.
        methods.add_method("getName", |_, this, ()| Ok(this.0.borrow().name.clone()));
        /// Sets the display name of this recipe.
        ///
        /// # Parameters
        /// - `name` — `string`: New display name.
        methods.add_method("setName", |_, this, v: String| { this.0.borrow_mut().name = v; Ok(()) });
        /// Returns the recipe type tag (e.g. `'smelt'`, `'craft'`).
        ///
        /// # Returns
        /// `string` — recipe type.
        methods.add_method("getType", |_, this, ()| Ok(this.0.borrow().recipe_type.clone()));
        /// Returns the base crafting duration in seconds.
        ///
        /// # Returns
        /// `number` — duration in seconds.
        methods.add_method("getTime", |_, this, ()| Ok(this.0.borrow().time));
        /// Sets the base crafting duration in seconds.
        ///
        /// # Parameters
        /// - `time` — `number`: New duration in seconds.
        methods.add_method("setTime", |_, this, v: f64| { this.0.borrow_mut().time = v; Ok(()) });
        /// Returns the minimum station level required to craft this recipe.
        ///
        /// # Returns
        /// `integer` — required station level.
        methods.add_method("getStationLevel", |_, this, ()| Ok(this.0.borrow().station_level));
        /// Sets the minimum station level required to craft this recipe.
        ///
        /// # Parameters
        /// - `level` — `integer`: Minimum station level.
        methods.add_method("setStationLevel", |_, this, v: u32| { this.0.borrow_mut().station_level = v; Ok(()) });
        /// Returns the station type string required to craft this recipe.
        ///
        /// # Returns
        /// `string` — station type.
        methods.add_method("getStationType", |_, this, ()| Ok(this.0.borrow().station_type.clone()));
        /// Sets which station type is required for this recipe.
        ///
        /// # Parameters
        /// - `type` — `string`: Station type identifier.
        methods.add_method("setStationType", |_, this, v: String| { this.0.borrow_mut().station_type = v; Ok(()) });
        /// Returns the skill name gated on this recipe, or an empty string if none.
        ///
        /// # Returns
        /// `string` — required skill name, or `''`.
        methods.add_method("getSkill", |_, this, ()| Ok(this.0.borrow().skill.clone()));
        /// Sets the skill required to unlock and use this recipe.
        ///
        /// # Parameters
        /// - `skill` — `string`: Skill name.
        methods.add_method("setSkill", |_, this, (name, level): (String, Option<u32>)| {
            let mut b = this.0.borrow_mut();
            b.skill = name;
            b.skill_level = level.unwrap_or(0);
            Ok(())
        });
        /// Returns the XP awarded to the required skill when this recipe is completed.
        ///
        /// # Returns
        /// `number` — XP awarded.
        methods.add_method("getSkillXp", |_, this, ()| Ok(this.0.borrow().skill_xp));
        /// Sets the skill XP awarded on completion.
        ///
        /// # Parameters
        /// - `xp` — `number`: XP amount.
        methods.add_method("setSkillXp", |_, this, v: f64| { this.0.borrow_mut().skill_xp = v; Ok(()) });
        /// Returns the lore/description text for this recipe.
        ///
        /// # Returns
        /// `string`.
        methods.add_method("getDescription", |_, this, ()| Ok(this.0.borrow().description.clone()));
        /// Sets the description text shown in crafting UI.
        ///
        /// # Parameters
        /// - `desc` — `string`: Description string.
        methods.add_method("setDescription", |_, this, v: String| { this.0.borrow_mut().description = v; Ok(()) });
        /// Returns `true` if this recipe is currently craftable (not disabled).
        ///
        /// # Returns
        /// `boolean`.
        methods.add_method("isEnabled", |_, this, ()| Ok(this.0.borrow().enabled));
        /// Enables or disables this recipe. Disabled recipes cannot be enqueued.
        ///
        /// # Parameters
        /// - `enabled` — `boolean`: `true` to enable.
        methods.add_method("setEnabled", |_, this, v: bool| { this.0.borrow_mut().enabled = v; Ok(()) });
        /// Returns `true` if this recipe carries the given tag.
        ///
        /// # Parameters
        /// - `tag` — `string`: Tag to test.
        ///
        /// # Returns
        /// `boolean`.
        methods.add_method("hasTag", |_, this, tag: String| Ok(this.0.borrow().has_tag(&tag)));
        /// Attaches a string tag to this recipe.
        ///
        /// # Parameters
        /// - `tag` — `string`: Tag to add.
        methods.add_method("addTag", |_, this, tag: String| {
            this.0.borrow_mut().tags.push(tag); Ok(())
        });

        /// Returns a list of all tags attached to this recipe.
        ///
        /// # Returns
        /// `table` of `string` tags.
        methods.add_method("getTags", |lua, this, ()| {
            let tags = this.0.borrow().get_tags().to_vec();
            let t = lua.create_table()?;
            for (i, tag) in tags.into_iter().enumerate() { t.set(i + 1, tag)?; }
            Ok(t)
        });
        /// Adds an ingredient requirement to this recipe.
        ///
        /// # Parameters
        /// - `id` — `string`: Item ID of the ingredient.
        /// - `count` — `integer`: Number of units required.
        methods.add_method("addIngredient", |_, this, (item_type, qty, consumed): (String, u32, Option<bool>)| {
            let mut ing = Ingredient::new(item_type, qty);
            ing.consumed = consumed.unwrap_or(true);
            this.0.borrow_mut().add_ingredient(ing);
            Ok(())
        });

        /// Adds an output item produced when this recipe is completed.
        ///
        /// # Parameters
        /// - `id` — `string`: Item ID of the output.
        /// - `count` — `integer`: Number of units produced.
        methods.add_method("addOutput", |_, this, (item_type, qty, quality): (String, u32, Option<String>)| {
            let mut out = RecipeOutput::new(item_type, qty);
            if let Some(q) = quality { out.quality = Quality::from_str(&q).unwrap_or(Quality::Normal); }
            this.0.borrow_mut().add_output(out);
            Ok(())
        });

        /// Returns a list of all ingredient requirements as `{id, count}` tables.
        ///
        /// # Returns
        /// `table` of `{id: string, count: integer}` tables.
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

        /// Returns a list of all output items as `{id, count}` tables.
        ///
        /// # Returns
        /// `table` of `{id: string, count: integer}` tables.
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

        /// Registers a recipe in this registry. Raises an error if a recipe with the same ID already exists.
        ///
        /// # Parameters
        /// - `recipe` — `Recipe`: Recipe object to register.
        methods.add_method("add", |_, this, recipe: LuaAnyUserData| {
            let r = recipe.borrow::<LuaRecipe>()?.0.borrow().clone();
            this.0.borrow_mut().add(r);
            Ok(())
        });
        /// Returns the registered recipe with the given ID, or `nil` if none exists.
        ///
        /// # Parameters
        /// - `id` — `string`: Recipe ID to look up.
        ///
        /// # Returns
        /// `Recipe` or `nil`.
        methods.add_method("get", |_, this, id: String| {
            let borrow = this.0.borrow();
            let r = borrow.get(&id).cloned();
            drop(borrow);
            Ok(r.map(|r| LuaRecipe(Rc::new(RefCell::new(r)))))
        });
        /// Removes the recipe with the given ID from this registry.
        ///
        /// # Parameters
        /// - `id` — `string`: Recipe ID to remove.
        methods.add_method("remove", |_, this, id: String| {
            Ok(this.0.borrow_mut().remove(&id))
        });
        /// Returns the total number of registered recipes.
        ///
        /// # Returns
        /// `integer`.
        methods.add_method("count", |_, this, ()| Ok(this.0.borrow().count()));
        /// Returns a list of all registered recipe IDs.
        ///
        /// # Returns
        /// `table` of `string` IDs.
        methods.add_method("getIds", |lua, this, ()| {
            let borrow = this.0.borrow();
            let t = lua.create_sequence_from(borrow.ids().iter().cloned())?;
            Ok(t)
        });
        /// Returns all recipes that produce an item with the given ID.
        ///
        /// # Parameters
        /// - `item_id` — `string`: Output item ID to search for.
        ///
        /// # Returns
        /// `table` of `Recipe` objects.
        methods.add_method("findByOutput", |lua, this, item_type: String| {
            let borrow = this.0.borrow();
            let ids: Vec<String> = borrow.find_by_output(&item_type).iter().map(|s| s.to_string()).collect();
            drop(borrow);
            let t = lua.create_sequence_from(ids.into_iter())?;
            Ok(t)
        });
        /// Returns all recipes that consume an item with the given ID as an ingredient.
        ///
        /// # Parameters
        /// - `item_id` — `string`: Ingredient item ID to search for.
        ///
        /// # Returns
        /// `table` of `Recipe` objects.
        methods.add_method("findByIngredient", |lua, this, item_type: String| {
            let borrow = this.0.borrow();
            let ids: Vec<String> = borrow.find_by_ingredient(&item_type).iter().map(|s| s.to_string()).collect();
            drop(borrow);
            let t = lua.create_sequence_from(ids.into_iter())?;
            Ok(t)
        });
        /// Returns all recipes that carry the given tag.
        ///
        /// # Parameters
        /// - `tag` — `string`: Tag string to match.
        ///
        /// # Returns
        /// `table` of `Recipe` objects.
        methods.add_method("findByTag", |lua, this, tag: String| {
            let ids = this.0.borrow().find_by_tag(&tag).iter().map(|s| s.to_string()).collect::<Vec<_>>();
            let t = lua.create_table()?;
            for (i, id) in ids.into_iter().enumerate() { t.set(i + 1, id)?; }
            Ok(t)
        });
        /// Returns all recipes that require the given station type.
        ///
        /// # Parameters
        /// - `station_type` — `string`: Station type identifier.
        ///
        /// # Returns
        /// `table` of `Recipe` objects.
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

        /// Returns the station type identifier string.
        ///
        /// # Returns
        /// `string`.
        methods.add_method("getType", |_, this, ()| Ok(this.0.borrow().station_type.clone()));
        /// Returns the current upgrade level of this station.
        ///
        /// # Returns
        /// `integer` — level.
        methods.add_method("getLevel", |_, this, ()| Ok(this.0.borrow().level));
        /// Sets the station's upgrade level, affecting which recipes it can process.
        ///
        /// # Parameters
        /// - `level` — `integer`: New station level.
        methods.add_method("setLevel", |_, this, v: u32| { this.0.borrow_mut().level = v; Ok(()) });
        /// Returns the display name of this station.
        ///
        /// # Returns
        /// `string`.
        methods.add_method("getName", |_, this, ()| Ok(this.0.borrow().name.clone()));
        /// Sets the display name of this station.
        ///
        /// # Parameters
        /// - `name` — `string`: New display name.
        methods.add_method("setName", |_, this, v: String| { this.0.borrow_mut().name = v; Ok(()) });
        /// Returns the crafting speed multiplier. `1.0` is normal speed.
        ///
        /// # Returns
        /// `number`.
        methods.add_method("getSpeedMultiplier", |_, this, ()| Ok(this.0.borrow().speed_multiplier));
        /// Sets the crafting speed multiplier. Values above `1.0` reduce effective recipe time.
        ///
        /// # Parameters
        /// - `mult` — `number`: Speed multiplier (e.g. `2.0` for double speed).
        methods.add_method("setSpeedMultiplier", |_, this, v: f64| { this.0.borrow_mut().speed_multiplier = v; Ok(()) });
        /// Returns `true` if this station is operational and can process recipes.
        ///
        /// # Returns
        /// `boolean`.
        methods.add_method("isActive", |_, this, ()| Ok(this.0.borrow().active));
        /// Enables or disables this station.
        ///
        /// # Parameters
        /// - `active` — `boolean`: `true` to enable.
        methods.add_method("setActive", |_, this, v: bool| { this.0.borrow_mut().active = v; Ok(()) });
        /// Returns `true` if this station can currently process the given recipe (level and type match).
        ///
        /// # Parameters
        /// - `recipe` — `Recipe`: Recipe to check against this station's type and level.
        ///
        /// # Returns
        /// `boolean`.
        methods.add_method("canProcess", |_, this, recipe: LuaAnyUserData| {
            let rb = recipe.borrow::<LuaRecipe>()?;
            let recipe_inner = rb.0.borrow();
            Ok(this.0.borrow().can_process(&recipe_inner))
        });
        /// Returns the effective crafting time for `recipe` after applying this station's speed multiplier.
        ///
        /// # Parameters
        /// - `recipe` — `Recipe`: The recipe to evaluate.
        ///
        /// # Returns
        /// `number` — effective time in seconds.
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

        /// Returns the skill's name identifier.
        ///
        /// # Returns
        /// `string`.
        methods.add_method("getName", |_, this, ()| Ok(this.0.borrow().name.clone()));
        /// Returns the total accumulated XP for this skill.
        ///
        /// # Returns
        /// `number` — total XP.
        methods.add_method("getXp", |_, this, ()| Ok(this.0.borrow().xp));
        /// Returns the current level derived from total XP.
        ///
        /// # Returns
        /// `integer` — current level.
        methods.add_method("getLevel", |_, this, ()| Ok(this.0.borrow().level));
        /// Returns the XP required to reach the next level.
        ///
        /// # Returns
        /// `number` — XP needed.
        methods.add_method("getXpToNext", |_, this, ()| Ok(this.0.borrow().get_xp_to_next()));
        /// Sets the skill directly to the given level, adjusting XP accordingly.
        ///
        /// # Parameters
        /// - `level` — `integer`: Target level.
        methods.add_method("setLevel", |_, this, level: u32| {
            this.0.borrow_mut().set_level(level);
            Ok(())
        });
        /// Adds `xp` to this skill's total, potentially triggering level-ups.
        ///
        /// # Parameters
        /// - `xp` — `number`: XP to add.
        methods.add_method("addXp", |_, this, amount: f64| Ok(this.0.borrow_mut().add_xp(amount)));
        /// Returns `true` if this skill's level meets the minimum required to use the given recipe.
        ///
        /// # Parameters
        /// - `recipe` — `Recipe`: Recipe to check skill requirement against.
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
