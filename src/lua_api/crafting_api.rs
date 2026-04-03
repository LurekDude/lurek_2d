//! Lua bindings for `luna.crafting.*`.
//!
//! This module is part of Luna2D's `lua_api` subsystem and provides the implementation
//! details for crafting api-related operations and data management.
//! Key types exported from this module: `LuaRecipe`, `LuaRecipeRegistry`, `LuaStation`, `LuaCraftSkill`, `LuaCraftQueue`.
//! Primary functions: `register()`.
//!
//! All public items are documented. See the parent module for architectural context
//! and the `luna.*` Lua API for the scripting interface.

use mlua::prelude::*;
use std::cell::RefCell;
use std::rc::Rc;

use crate::crafting::{CraftQueue, CraftSkill, Ingredient, ModifierPool, Quality, Recipe, RecipeGroup, RecipeKnowledge, RecipeOutput, RecipeRegistry, Station, UpgradeNode, UpgradeTree};
use crate::lua_api::lua_types::{add_type_methods, LunaType};

// ─────────────────────────────────────────────────────────────────────────────
// LuaRecipe
// ─────────────────────────────────────────────────────────────────────────────

#[derive(Clone)]
/// Lua-callable handle wrapping [`Recipe`].
pub struct LuaRecipe(pub Rc<RefCell<Recipe>>);

impl LunaType for LuaRecipe {
    const TYPE_NAME: &'static str = "Recipe";
    const TYPE_HIERARCHY: &'static [&'static str] = &["Recipe"];
}

impl LuaUserData for LuaRecipe {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods(methods);

        /// Returns the unique string identifier of this recipe.
        /// @return any
        ///
        /// # Returns
        /// `string` — recipe ID.
        methods.add_method("getId", |_, this, ()| Ok(this.0.borrow().id.clone()));
        /// Returns the human-readable display name of this recipe.
        /// @return any
        ///
        /// # Returns
        /// `string`.
        methods.add_method("getName", |_, this, ()| Ok(this.0.borrow().name.clone()));
        /// Sets the display name of this recipe.
        /// @param v : string
        ///
        /// # Parameters
        /// - `name` — `string`: New display name.
        methods.add_method("setName", |_, this, v: String| { this.0.borrow_mut().name = v; Ok(()) });
        /// Returns the recipe type tag (e.g. `'smelt'`, `'craft'`).
        /// @return any
        ///
        /// # Returns
        /// `string` — recipe type.
        methods.add_method("getType", |_, this, ()| Ok(this.0.borrow().recipe_type.clone()));
        /// Returns the base crafting duration in seconds.
        /// @return any
        ///
        /// # Returns
        /// `number` — duration in seconds.
        methods.add_method("getTime", |_, this, ()| Ok(this.0.borrow().time));
        /// Sets the base crafting duration in seconds.
        /// @param v : number
        ///
        /// # Parameters
        /// - `time` — `number`: New duration in seconds.
        methods.add_method("setTime", |_, this, v: f64| { this.0.borrow_mut().time = v; Ok(()) });
        /// Returns the minimum station level required to craft this recipe.
        /// @return any
        ///
        /// # Returns
        /// `integer` — required station level.
        methods.add_method("getStationLevel", |_, this, ()| Ok(this.0.borrow().station_level));
        /// Sets the minimum station level required to craft this recipe.
        /// @param v : integer
        ///
        /// # Parameters
        /// - `level` — `integer`: Minimum station level.
        methods.add_method("setStationLevel", |_, this, v: u32| { this.0.borrow_mut().station_level = v; Ok(()) });
        /// Returns the station type string required to craft this recipe.
        /// @return any
        ///
        /// # Returns
        /// `string` — station type.
        methods.add_method("getStationType", |_, this, ()| Ok(this.0.borrow().station_type.clone()));
        /// Sets which station type is required for this recipe.
        /// @param v : string
        ///
        /// # Parameters
        /// - `type` — `string`: Station type identifier.
        methods.add_method("setStationType", |_, this, v: String| { this.0.borrow_mut().station_type = v; Ok(()) });
        /// Returns the skill name gated on this recipe, or an empty string if none.
        /// @return any
        ///
        /// # Returns
        /// `string` — required skill name, or `''`.
        methods.add_method("getSkill", |_, this, ()| Ok(this.0.borrow().skill.clone()));
        /// Sets the skill required to unlock and use this recipe.
        /// @param name : string
        /// @param level : integer?
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
        /// @return any
        ///
        /// # Returns
        /// `number` — XP awarded.
        methods.add_method("getSkillXp", |_, this, ()| Ok(this.0.borrow().skill_xp));
        /// Sets the skill XP awarded on completion.
        /// @param v : number
        ///
        /// # Parameters
        /// - `xp` — `number`: XP amount.
        methods.add_method("setSkillXp", |_, this, v: f64| { this.0.borrow_mut().skill_xp = v; Ok(()) });
        /// Returns the lore/description text for this recipe.
        /// @return any
        ///
        /// # Returns
        /// `string`.
        methods.add_method("getDescription", |_, this, ()| Ok(this.0.borrow().description.clone()));
        /// Sets the description text shown in crafting UI.
        /// @param v : string
        ///
        /// # Parameters
        /// - `desc` — `string`: Description string.
        methods.add_method("setDescription", |_, this, v: String| { this.0.borrow_mut().description = v; Ok(()) });
        /// Returns `true` if this recipe is currently craftable (not disabled).
        /// @return any
        ///
        /// # Returns
        /// `boolean`.
        methods.add_method("isEnabled", |_, this, ()| Ok(this.0.borrow().enabled));
        /// Enables or disables this recipe. Disabled recipes cannot be enqueued.
        /// @param v : boolean
        ///
        /// # Parameters
        /// - `enabled` — `boolean`: `true` to enable.
        methods.add_method("setEnabled", |_, this, v: bool| { this.0.borrow_mut().enabled = v; Ok(()) });

        /// Returns the UI category string for this recipe.
        /// @return any
        ///
        /// # Returns
        /// `string` — category name, or `''` if unset.
        methods.add_method("getCategory", |_, this, ()| Ok(this.0.borrow().category.clone()));
        /// Sets the UI category for this recipe (e.g. `'weapons'`, `'potions'`).
        /// @param v : string
        ///
        /// # Parameters
        /// - `category` — `string`: Category name.
        methods.add_method("setCategory", |_, this, v: String| { this.0.borrow_mut().category = v; Ok(()) });

        /// Returns the cooldown duration in seconds before this recipe can be used again.
        /// @return any
        ///
        /// # Returns
        /// `number` — cooldown in seconds.
        methods.add_method("getCooldown", |_, this, ()| Ok(this.0.borrow().cooldown));
        /// Sets the cooldown duration in seconds.
        /// @param v : number
        ///
        /// # Parameters
        /// - `cooldown` — `number`: Cooldown in seconds.
        methods.add_method("setCooldown", |_, this, v: f64| { this.0.borrow_mut().cooldown = v; Ok(()) });

        /// Returns `true` if this recipe can be crafted without a station.
        /// @return any
        ///
        /// # Returns
        /// `boolean`.
        methods.add_method("isHandCraftable", |_, this, ()| Ok(this.0.borrow().hand_craftable));
        /// Sets whether this recipe can be crafted without a station.
        /// @param v : boolean
        ///
        /// # Parameters
        /// - `craftable` — `boolean`: `true` to allow hand crafting.
        methods.add_method("setHandCraftable", |_, this, v: bool| { this.0.borrow_mut().hand_craftable = v; Ok(()) });

        /// Returns `true` if this recipe carries the given tag.
        /// @param tag : string
        /// @return any
        ///
        /// # Parameters
        /// - `tag` — `string`: Tag to test.
        ///
        /// # Returns
        /// `boolean`.
        methods.add_method("hasTag", |_, this, tag: String| Ok(this.0.borrow().has_tag(&tag)));
        /// Attaches a string tag to this recipe.
        /// @param tag : string
        ///
        /// # Parameters
        /// - `tag` — `string`: Tag to add.
        methods.add_method("addTag", |_, this, tag: String| {
            this.0.borrow_mut().tags.push(tag); Ok(())
        });

        /// Returns a list of all tags attached to this recipe.
        /// @return any
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
        /// @param item_type : string
        /// @param qty : integer
        /// @param consumed : boolean?
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
        /// @param item_type : string
        /// @param qty : integer
        /// @param quality : string?
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
        /// @return any
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
        /// @return any
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

        /// Removes all ingredients from this recipe.
        methods.add_method("clearIngredients", |_, this, ()| {
            this.0.borrow_mut().clear_ingredients(); Ok(())
        });
        /// Removes all outputs from this recipe.
        methods.add_method("clearOutputs", |_, this, ()| {
            this.0.borrow_mut().clear_outputs(); Ok(())
        });

        /// Adds a byproduct output (produced alongside main outputs, not guaranteed).
        /// @param item_type : string
        /// @param qty : integer
        /// @param chance : number?
        ///
        /// # Parameters
        /// - `item_type` — `string`: Item ID.
        /// - `qty` — `integer`: Quantity.
        /// - `chance` — `number` optional: Probability 0–1 (default `1.0`).
        methods.add_method("addByproduct", |_, this, (item_type, qty, chance): (String, u32, Option<f64>)| {
            this.0.borrow_mut().add_byproduct(item_type, qty, chance.unwrap_or(1.0));
            Ok(())
        });

        /// Adds a crafting condition requirement for this recipe (e.g. biome, weather).
        /// @param cond_type : string
        /// @param value : string
        ///
        /// # Parameters
        /// - `condition_type` — `string`: Condition type identifier.
        /// - `value` — `string`: Required value.
        methods.add_method("addCondition", |_, this, (cond_type, value): (String, String)| {
            this.0.borrow_mut().add_condition(cond_type, value); Ok(())
        });

        /// Returns all crafting conditions as a list of `{condType, value}` tables.
        /// @return any
        ///
        /// # Returns
        /// `table` of `{condType: string, value: string}`.
        methods.add_method("getConditions", |lua, this, ()| {
            let borrow = this.0.borrow();
            let t = lua.create_table()?;
            for (i, (ctype, val)) in borrow.get_conditions().iter().enumerate() {
                let row = lua.create_table()?;
                row.set("condType", ctype.clone())?;
                row.set("value", val.clone())?;
                t.set(i + 1, row)?;
            }
            Ok(t)
        });

        /// Returns whether output quality scales with the crafter's skill level.
        /// @return any
        ///
        /// # Returns
        /// `boolean`.
        methods.add_method("isOutputQualityScaling", |_, this, ()| {
            Ok(this.0.borrow().output_quality_scaling)
        });
        /// Sets whether output quality scales with the crafter's skill level.
        /// @param v : boolean
        ///
        /// # Parameters
        /// - `scaling` — `boolean`.
        methods.add_method("setOutputQualityScaling", |_, this, v: bool| {
            this.0.borrow_mut().output_quality_scaling = v; Ok(())
        });

        /// Returns the ID of the modifier pool rolled on completion (empty = none).
        /// @return any
        ///
        /// # Returns
        /// `string`.
        methods.add_method("getRandomModifierPool", |_, this, ()| {
            Ok(this.0.borrow().random_modifier_pool.clone())
        });
        /// Sets the modifier pool to roll on completion.
        /// @param v : string
        ///
        /// # Parameters
        /// - `pool_id` — `string`: Modifier pool ID.
        methods.add_method("setRandomModifierPool", |_, this, v: String| {
            this.0.borrow_mut().random_modifier_pool = v; Ok(())
        });

        /// Returns the skill-up XP curve name: `'linear'`, `'quadratic'`, `'exponential'`.
        /// @return any
        ///
        /// # Returns
        /// `string`.
        methods.add_method("getSkillUpCurve", |_, this, ()| {
            Ok(this.0.borrow().skill_up_curve.clone())
        });
        /// Sets the skill-up XP curve name.
        /// @param v : string
        ///
        /// # Parameters
        /// - `curve` — `string`: Curve name.
        methods.add_method("setSkillUpCurve", |_, this, v: String| {
            this.0.borrow_mut().skill_up_curve = v; Ok(())
        });
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// LuaRecipeRegistry
// ─────────────────────────────────────────────────────────────────────────────

#[derive(Clone)]
/// Lua-callable handle wrapping [`RecipeRegistry`].
pub struct LuaRecipeRegistry(pub Rc<RefCell<RecipeRegistry>>);

impl LunaType for LuaRecipeRegistry {
    const TYPE_NAME: &'static str = "RecipeRegistry";
    const TYPE_HIERARCHY: &'static [&'static str] = &["RecipeRegistry"];
}

impl LuaUserData for LuaRecipeRegistry {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods(methods);

        /// Registers a recipe in this registry. Raises an error if a recipe with the same ID already exists.
        /// @param recipe : Recipe
        ///
        /// # Parameters
        /// - `recipe` — `Recipe`: Recipe object to register.
        methods.add_method("add", |_, this, recipe: LuaAnyUserData| {
            let r = recipe.borrow::<LuaRecipe>()?.0.borrow().clone();
            this.0.borrow_mut().add(r);
            Ok(())
        });
        /// Returns the registered recipe with the given ID, or `nil` if none exists.
        /// @param id : string
        /// @return any
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
        /// @param id : string
        /// @return any
        ///
        /// # Parameters
        /// - `id` — `string`: Recipe ID to remove.
        methods.add_method("remove", |_, this, id: String| {
            Ok(this.0.borrow_mut().remove(&id))
        });
        /// Returns the total number of registered recipes.
        /// @return integer
        ///
        /// # Returns
        /// `integer`.
        methods.add_method("count", |_, this, ()| Ok(this.0.borrow().count()));
        /// Returns a list of all registered recipe IDs.
        /// @return any
        ///
        /// # Returns
        /// `table` of `string` IDs.
        methods.add_method("getIds", |lua, this, ()| {
            let borrow = this.0.borrow();
            let t = lua.create_sequence_from(borrow.ids().iter().cloned())?;
            Ok(t)
        });
        /// Returns all recipes that produce an item with the given ID.
        /// @param item_type : string
        /// @return any
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
        /// @param item_type : string
        /// @return any
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
        /// @param tag : string
        /// @return any
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
        /// @param station_type : string
        /// @return any
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

        /// Alias for `add`. Registers a recipe (error if duplicate ID).
        /// @param recipe : Recipe
        ///
        /// # Parameters
        /// - `recipe` — `Recipe`.
        methods.add_method("register", |_, this, recipe: LuaAnyUserData| {
            let r = recipe.borrow::<LuaRecipe>()?.0.borrow().clone();
            this.0.borrow_mut().add(r);
            Ok(())
        });

        /// Alias for `remove`. Unregisters the recipe with the given ID.
        /// @param id : string
        /// @return any
        ///
        /// # Parameters
        /// - `id` — `string`.
        ///
        /// # Returns
        /// `boolean` — `true` if it existed.
        methods.add_method("unregister", |_, this, id: String| {
            Ok(this.0.borrow_mut().remove(&id))
        });

        /// Returns all recipes in registration order as a list of `Recipe` objects.
        /// @return any
        ///
        /// # Returns
        /// `table` of `Recipe` objects.
        methods.add_method("getAll", |lua, this, ()| {
            let borrow = this.0.borrow();
            let recipes: Vec<Recipe> = borrow.ids().iter()
                .filter_map(|id| borrow.get(id).cloned())
                .collect();
            drop(borrow);
            let t = lua.create_table()?;
            for (i, r) in recipes.into_iter().enumerate() {
                t.set(i + 1, LuaRecipe(Rc::new(RefCell::new(r))))?;
            }
            Ok(t)
        });

        /// Returns all recipe IDs in the given UI category.
        /// @param category : string
        /// @return any
        ///
        /// # Parameters
        /// - `category` — `string`: Category name.
        ///
        /// # Returns
        /// `table` of `string` IDs.
        methods.add_method("getByCategory", |lua, this, category: String| {
            let ids = this.0.borrow().find_by_category(&category).iter().map(|s| s.to_string()).collect::<Vec<_>>();
            let t = lua.create_sequence_from(ids.into_iter())?;
            Ok(t)
        });
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// LuaStation
// ─────────────────────────────────────────────────────────────────────────────

#[derive(Clone)]
/// Lua-callable handle wrapping [`Station`].
pub struct LuaStation(pub Rc<RefCell<Station>>);

impl LunaType for LuaStation {
    const TYPE_NAME: &'static str = "Station";
    const TYPE_HIERARCHY: &'static [&'static str] = &["Station"];
}

impl LuaUserData for LuaStation {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods(methods);

        /// Returns the station type identifier string.
        /// @return any
        ///
        /// # Returns
        /// `string`.
        methods.add_method("getType", |_, this, ()| Ok(this.0.borrow().station_type.clone()));
        /// Returns the current upgrade level of this station.
        /// @return any
        ///
        /// # Returns
        /// `integer` — level.
        methods.add_method("getLevel", |_, this, ()| Ok(this.0.borrow().level));
        /// Sets the station's upgrade level, affecting which recipes it can process.
        /// @param v : integer
        ///
        /// # Parameters
        /// - `level` — `integer`: New station level.
        methods.add_method("setLevel", |_, this, v: u32| { this.0.borrow_mut().level = v; Ok(()) });
        /// Returns the display name of this station.
        /// @return any
        ///
        /// # Returns
        /// `string`.
        methods.add_method("getName", |_, this, ()| Ok(this.0.borrow().name.clone()));
        /// Sets the display name of this station.
        /// @param v : string
        ///
        /// # Parameters
        /// - `name` — `string`: New display name.
        methods.add_method("setName", |_, this, v: String| { this.0.borrow_mut().name = v; Ok(()) });
        /// Returns the crafting speed multiplier. `1.0` is normal speed.
        /// @return any
        ///
        /// # Returns
        /// `number`.
        methods.add_method("getSpeedMultiplier", |_, this, ()| Ok(this.0.borrow().speed_multiplier));
        /// Sets the crafting speed multiplier. Values above `1.0` reduce effective recipe time.
        /// @param v : number
        ///
        /// # Parameters
        /// - `mult` — `number`: Speed multiplier (e.g. `2.0` for double speed).
        methods.add_method("setSpeedMultiplier", |_, this, v: f64| { this.0.borrow_mut().speed_multiplier = v; Ok(()) });
        /// Returns `true` if this station is operational and can process recipes.
        /// @return any
        ///
        /// # Returns
        /// `boolean`.
        methods.add_method("isActive", |_, this, ()| Ok(this.0.borrow().active));
        /// Enables or disables this station.
        /// @param v : boolean
        ///
        /// # Parameters
        /// - `active` — `boolean`: `true` to enable.
        methods.add_method("setActive", |_, this, v: bool| { this.0.borrow_mut().active = v; Ok(()) });
        /// Returns `true` if this station can currently process the given recipe (level and type match).
        /// @param recipe : Recipe
        /// @return any
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
        /// @param recipe : Recipe
        /// @return any
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

        /// Returns the maximum upgrade level this station can reach.
        /// @return any
        ///
        /// # Returns
        /// `integer` — max level.
        methods.add_method("getMaxLevel", |_, this, ()| Ok(this.0.borrow().max_level));
        /// Sets the maximum upgrade level for this station.
        /// @param v : integer
        ///
        /// # Parameters
        /// - `max` — `integer`: Maximum level.
        methods.add_method("setMaxLevel", |_, this, v: u32| { this.0.borrow_mut().max_level = v; Ok(()) });

        /// Increments station level by 1. Returns `false` if already at max level.
        /// @return any
        ///
        /// # Returns
        /// `boolean` — `true` if upgraded successfully.
        methods.add_method("upgrade", |_, this, ()| Ok(this.0.borrow_mut().upgrade()));

        /// Returns the quality bonus applied to crafted items at this station.
        /// @return any
        ///
        /// # Returns
        /// `number`.
        methods.add_method("getQualityBonus", |_, this, ()| Ok(this.0.borrow().quality_bonus));
        /// Sets the quality bonus applied to crafted items at this station.
        /// @param v : number
        ///
        /// # Parameters
        /// - `bonus` — `number`: Quality bonus value.
        methods.add_method("setQualityBonus", |_, this, v: f64| { this.0.borrow_mut().quality_bonus = v; Ok(()) });

        /// Returns the output quantity multiplier applied by this station.
        /// @return any
        ///
        /// # Returns
        /// `number`.
        methods.add_method("getOutputMultiplier", |_, this, ()| Ok(this.0.borrow().output_multiplier));
        /// Sets the output quantity multiplier for this station.
        /// @param v : number
        ///
        /// # Parameters
        /// - `mult` — `number`: Output multiplier (e.g. `1.5` for 50% bonus).
        methods.add_method("setOutputMultiplier", |_, this, v: f64| { this.0.borrow_mut().output_multiplier = v; Ok(()) });

        /// Returns the station's world position as `(x, y)`.
        /// @return any
        ///
        /// # Returns
        /// `number, number` — x and y coordinates.
        methods.add_method("getPosition", |_, this, ()| {
            let b = this.0.borrow();
            Ok((b.x, b.y))
        });
        /// Sets the station's world position.
        /// @param x : number
        /// @param y : number
        ///
        /// # Parameters
        /// - `x` — `number`: X coordinate.
        /// - `y` — `number`: Y coordinate.
        methods.add_method("setPosition", |_, this, (x, y): (f64, f64)| {
            let mut b = this.0.borrow_mut();
            b.x = x; b.y = y; Ok(())
        });

        /// Returns the proximity radius within which players can use this station.
        /// @return any
        ///
        /// # Returns
        /// `number` — radius in world units. `0` means no proximity check.
        methods.add_method("getProximityRadius", |_, this, ()| Ok(this.0.borrow().proximity_radius));
        /// Sets the proximity radius for this station.
        /// @param v : number
        ///
        /// # Parameters
        /// - `radius` — `number`: Radius in world units.
        methods.add_method("setProximityRadius", |_, this, v: f64| { this.0.borrow_mut().proximity_radius = v; Ok(()) });

        /// Returns `true` if the given world position is within this station's proximity radius.
        /// @param x : number
        /// @param y : number
        /// @return any
        ///
        /// # Parameters
        /// - `x` — `number`: X coordinate to check.
        /// - `y` — `number`: Y coordinate to check.
        ///
        /// # Returns
        /// `boolean`.
        methods.add_method("isInRange", |_, this, (x, y): (f64, f64)| {
            Ok(this.0.borrow().is_in_range(x, y))
        });

        /// Returns the current fuel level of this station.
        /// @return any
        ///
        /// # Returns
        /// `number`.
        methods.add_method("getFuelLevel", |_, this, ()| Ok(this.0.borrow().fuel_level));
        /// Sets the fuel level directly.
        /// @param v : number
        ///
        /// # Parameters
        /// - `level` — `number`: New fuel level.
        methods.add_method("setFuelLevel", |_, this, v: f64| { this.0.borrow_mut().fuel_level = v; Ok(()) });

        /// Returns the maximum fuel capacity of this station.
        /// @return any
        ///
        /// # Returns
        /// `number`.
        methods.add_method("getFuelCapacity", |_, this, ()| Ok(this.0.borrow().fuel_capacity));
        /// Sets the maximum fuel capacity.
        /// @param v : number
        ///
        /// # Parameters
        /// - `capacity` — `number`: New maximum fuel.
        methods.add_method("setFuelCapacity", |_, this, v: f64| { this.0.borrow_mut().fuel_capacity = v; Ok(()) });

        /// Adds fuel to this station, clamped to capacity.
        /// @param amount : number
        ///
        /// # Parameters
        /// - `amount` — `number`: Fuel to add.
        methods.add_method("addFuel", |_, this, amount: f64| {
            this.0.borrow_mut().add_fuel(amount); Ok(())
        });

        /// Consumes fuel from this station. Returns `false` if insufficient fuel.
        /// @param amount : number
        /// @return any
        ///
        /// # Parameters
        /// - `amount` — `number`: Fuel to consume.
        ///
        /// # Returns
        /// `boolean` — `true` if consumed successfully.
        methods.add_method("consumeFuel", |_, this, amount: f64| {
            Ok(this.0.borrow_mut().consume_fuel(amount))
        });

        /// Returns a stored metadata value by key.
        /// @param key : string
        /// @return any
        ///
        /// # Parameters
        /// - `key` — `string`: Metadata key.
        ///
        /// # Returns
        /// `string` or `nil`.
        methods.add_method("getMetadata", |_, this, key: String| {
            Ok(this.0.borrow().metadata.get(&key).cloned())
        });
        /// Stores a metadata key-value pair on this station.
        /// @param key : string
        /// @param val : string
        ///
        /// # Parameters
        /// - `key` — `string`: Metadata key.
        /// - `value` — `string`: Metadata value.
        methods.add_method("setMetadata", |_, this, (key, val): (String, String)| {
            this.0.borrow_mut().metadata.insert(key, val); Ok(())
        });
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// LuaCraftSkill
// ─────────────────────────────────────────────────────────────────────────────

#[derive(Clone)]
/// Lua-callable handle wrapping [`CraftSkill`].
pub struct LuaCraftSkill(pub Rc<RefCell<CraftSkill>>);

impl LunaType for LuaCraftSkill {
    const TYPE_NAME: &'static str = "CraftSkill";
    const TYPE_HIERARCHY: &'static [&'static str] = &["CraftSkill"];
}

impl LuaUserData for LuaCraftSkill {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods(methods);

        /// Returns the skill's name identifier.
        /// @return any
        ///
        /// # Returns
        /// `string`.
        methods.add_method("getName", |_, this, ()| Ok(this.0.borrow().name.clone()));
        /// Returns the total accumulated XP for this skill.
        /// @return any
        ///
        /// # Returns
        /// `number` — total XP.
        methods.add_method("getXp", |_, this, ()| Ok(this.0.borrow().xp));
        /// Returns the current level derived from total XP.
        /// @return any
        ///
        /// # Returns
        /// `integer` — current level.
        methods.add_method("getLevel", |_, this, ()| Ok(this.0.borrow().level));
        /// Returns the XP required to reach the next level.
        /// @return any
        ///
        /// # Returns
        /// `number` — XP needed.
        methods.add_method("getXpToNext", |_, this, ()| Ok(this.0.borrow().get_xp_to_next()));
        /// Sets the skill directly to the given level, adjusting XP accordingly.
        /// @param level : integer
        ///
        /// # Parameters
        /// - `level` — `integer`: Target level.
        methods.add_method("setLevel", |_, this, level: u32| {
            this.0.borrow_mut().set_level(level);
            Ok(())
        });
        /// Adds `xp` to this skill's total, potentially triggering level-ups.
        /// @param amount : number
        /// @return any
        ///
        /// # Parameters
        /// - `xp` — `number`: XP to add.
        ///
        /// # Returns
        /// `integer` — number of levels gained.
        methods.add_method("addXp", |_, this, amount: f64| Ok(this.0.borrow_mut().add_xp(amount)));
        /// Returns `true` if this skill's level meets the minimum required to use the given recipe.
        /// @param recipe : Recipe
        /// @return any
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

        /// Returns the maximum level this skill can reach.
        /// @return any
        ///
        /// # Returns
        /// `integer`.
        methods.add_method("getMaxLevel", |_, this, ()| Ok(this.0.borrow().max_level));

        /// Returns the speed bonus (0–1 fraction) from skill mastery.
        /// @return any
        ///
        /// # Returns
        /// `number`.
        methods.add_method("getSpeedBonus", |_, this, ()| Ok(this.0.borrow().get_speed_bonus()));

        /// Returns the quality bonus (0–1 fraction) from skill mastery.
        /// @return any
        ///
        /// # Returns
        /// `number`.
        methods.add_method("getQualityBonus", |_, this, ()| Ok(this.0.borrow().get_quality_bonus()));

        /// Returns the yield/quantity bonus (0–1 fraction) from skill mastery.
        /// @return any
        ///
        /// # Returns
        /// `number`.
        methods.add_method("getYieldBonus", |_, this, ()| Ok(this.0.borrow().get_yield_bonus()));

        /// Registers a specialization branch for this skill.
        /// @param name : string
        ///
        /// # Parameters
        /// - `name` — `string`: Specialization name.
        methods.add_method("addSpecialization", |_, this, name: String| {
            this.0.borrow_mut().add_specialization(name); Ok(())
        });

        /// Locks in a specialization branch. Fails if already specialized.
        /// @param name : string
        /// @return any
        ///
        /// # Parameters
        /// - `name` — `string`: Specialization to choose.
        ///
        /// # Returns
        /// `boolean` — `true` if successfully chosen.
        methods.add_method("chooseSpecialization", |_, this, name: String| {
            Ok(this.0.borrow_mut().choose_specialization(&name))
        });

        /// Returns the chosen specialization name, or `nil` if none chosen yet.
        /// @return any
        ///
        /// # Returns
        /// `string` or `nil`.
        methods.add_method("getSpecialization", |_, this, ()| {
            Ok(this.0.borrow().specialization.clone())
        });

        /// Defines a perk node in this skill's perk tree.
        /// @param perk_id : string
        /// @param req_level : integer
        /// @param prereqs : table?
        ///
        /// # Parameters
        /// - `perk_id` — `string`: Unique perk identifier.
        /// - `required_level` — `integer`: Minimum skill level to unlock.
        /// - `prerequisites` — `table` optional: List of prerequisite perk IDs.
        methods.add_method("addPerk", |_, this, (perk_id, req_level, prereqs): (String, u32, Option<LuaTable>)| {
            let mut plist = Vec::new();
            if let Some(t) = prereqs {
                for v in t.sequence_values::<String>() { plist.push(v?); }
            }
            this.0.borrow_mut().add_perk(perk_id, req_level, plist);
            Ok(())
        });

        /// Attempts to unlock a perk. Fails if prerequisites or level not met.
        /// @param perk_id : string
        /// @return any
        ///
        /// # Parameters
        /// - `perk_id` — `string`.
        ///
        /// # Returns
        /// `boolean` — `true` if successfully unlocked.
        methods.add_method("unlockPerk", |_, this, perk_id: String| {
            Ok(this.0.borrow_mut().unlock_perk(&perk_id))
        });

        /// Returns `true` if the given perk is unlocked.
        /// @param perk_id : string
        /// @return any
        ///
        /// # Parameters
        /// - `perk_id` — `string`.
        ///
        /// # Returns
        /// `boolean`.
        methods.add_method("hasPerk", |_, this, perk_id: String| {
            Ok(this.0.borrow().has_perk(&perk_id))
        });

        /// Returns perk IDs whose prerequisites and level requirements are met.
        /// @return any
        ///
        /// # Returns
        /// `table` of `string` perk IDs.
        methods.add_method("getAvailablePerks", |lua, this, ()| {
            let ids = this.0.borrow().available_perks().iter().map(|s| s.to_string()).collect::<Vec<_>>();
            let t = lua.create_sequence_from(ids.into_iter())?;
            Ok(t)
        });

        /// Returns the WoW-style difficulty color for a recipe from this skill's perspective.
        /// @param recipe : Recipe
        /// @return any
        ///
        /// # Parameters
        /// - `recipe` — `Recipe`.
        ///
        /// # Returns
        /// `string` — `'orange'`, `'yellow'`, `'green'`, or `'grey'`.
        methods.add_method("getRecipeColor", |_, this, recipe: LuaAnyUserData| {
            let rb = recipe.borrow::<LuaRecipe>()?;
            let recipe_ref = rb.0.borrow();
            let color = this.0.borrow().recipe_color(&recipe_ref).to_string();
            Ok(color)
        });

        /// Returns the skill-up probability (0–1) for this skill when crafting a recipe.
        /// @param recipe : Recipe
        /// @return any
        ///
        /// # Parameters
        /// - `recipe` — `Recipe`.
        ///
        /// # Returns
        /// `number`.
        methods.add_method("skillUpChance", |_, this, recipe: LuaAnyUserData| {
            let rb = recipe.borrow::<LuaRecipe>()?;
            let recipe_ref = rb.0.borrow();
            let chance = this.0.borrow().skill_up_chance(&recipe_ref);
            Ok(chance)
        });
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// LuaCraftQueue
// ─────────────────────────────────────────────────────────────────────────────

#[derive(Clone)]
/// Lua-callable handle wrapping [`CraftQueue`].
pub struct LuaCraftQueue(pub Rc<RefCell<CraftQueue>>);

impl LunaType for LuaCraftQueue {
    const TYPE_NAME: &'static str = "CraftQueue";
    const TYPE_HIERARCHY: &'static [&'static str] = &["CraftQueue"];
}

impl LuaUserData for LuaCraftQueue {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods(methods);

        /// Enqueue on this CraftQueue.
        /// @param recipe_id : string
        /// @param time : number
        /// @param qty : integer?
        /// @return any
        ///
        /// # Parameters
        /// - `recipe_id` — `string`.
        /// - `time` — `number`.
        /// - `qty` — `integer` optional.
        methods.add_method("enqueue", |_, this, (recipe_id, time, qty): (String, f64, Option<u32>)| {
            Ok(this.0.borrow_mut().enqueue(recipe_id, time, qty.unwrap_or(1)))
        });
        /// Cancels the current operation.
        /// @param id : integer
        /// @return any
        ///
        /// # Parameters
        /// - `id` — `integer`.
        methods.add_method("cancel", |_, this, id: u32| {
            Ok(this.0.borrow_mut().cancel(id))
        });
        /// Advances the simulation by `dt` seconds.
        /// @param dt : number
        /// @return any
        ///
        /// # Parameters
        /// - `dt` — `number`.
        methods.add_method("update", |lua, this, dt: f64| {
            let finished = this.0.borrow_mut().update(dt);
            let t = lua.create_sequence_from(finished.into_iter())?;
            Ok(t)
        });
        /// Returns the IDs of jobs that completed since the last collection.
        /// @return any
        ///
        /// # Returns
        /// `table` of `integer` job IDs.
        methods.add_method("collectCompleted", |lua, this, ()| {
            let ids = this.0.borrow_mut().collect_completed();
            let t = lua.create_sequence_from(ids.into_iter())?;
            Ok(t)
        });
        /// Returns the job.
        /// @param id : integer
        /// @return any
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
        /// @return integer
        ///
        /// # Returns
        /// `integer`.
        methods.add_method("count", |_, this, ()| Ok(this.0.borrow().count()));
        /// Returns `true` if full.
        /// @return boolean
        ///
        /// # Returns
        /// `boolean`.
        methods.add_method("isFull", |_, this, ()| Ok(this.0.borrow().is_full()));
        /// Returns the max jobs.
        /// @return any
        ///
        /// # Returns
        /// The current max jobs.
        methods.add_method("getMaxJobs", |_, this, ()| Ok(this.0.borrow().max_jobs()));
        /// Returns the ids.
        /// @return any
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
        /// @return any
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
        /// @param id : integer
        /// @param paused : boolean
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
/// Lua-callable handle wrapping [`UpgradeTree`].
pub struct LuaUpgradeTree(pub Rc<RefCell<UpgradeTree>>);

impl LunaType for LuaUpgradeTree {
    const TYPE_NAME: &'static str = "UpgradeTree";
    const TYPE_HIERARCHY: &'static [&'static str] = &["UpgradeTree"];
}

impl LuaUserData for LuaUpgradeTree {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods(methods);

        /// Returns the name.
        /// @return any
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
        /// @return integer
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
        /// @param id : string
        /// @param name : string
        /// @param prereqs : table?
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
        /// @param id : string
        /// @return any
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
        /// @param id : string
        /// @return any
        ///
        /// # Parameters
        /// - `id` — `string`.
        methods.add_method("unlock", |_, this, id: String| {
            Ok(this.0.borrow_mut().unlock(&id))
        });
        /// Returns `true` if unlocked.
        /// @param id : string
        /// @return any
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
        /// @param id : string
        /// @return any
        ///
        /// # Parameters
        /// - `id` — `string`.
        methods.add_method("resetNode", |_, this, id: String| {
            Ok(this.0.borrow_mut().reset_node(&id))
        });
        /// Returns the unlocked ids.
        /// @return any
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
        /// @return any
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
        /// @param id : string
        /// @param cost_table : table
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
        /// @param id : string
        /// @return any
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

        /// Adds a directed edge from `from_id` to `to_id` in the DAG.
        /// @param from_id : string
        /// @param to_id : string
        ///
        /// # Parameters
        /// - `from_id` — `string`.
        /// - `to_id` — `string`.
        methods.add_method("addEdge", |_, this, (from_id, to_id): (String, String)| {
            this.0.borrow_mut().add_edge(&from_id, &to_id); Ok(())
        });

        /// Returns direct children of the given node.
        /// @param id : string
        /// @return any
        ///
        /// # Parameters
        /// - `id` — `string`.
        ///
        /// # Returns
        /// `table` of `string` child IDs.
        methods.add_method("getChildren", |lua, this, id: String| {
            let ids = this.0.borrow().get_children(&id).iter().map(|s| s.to_string()).collect::<Vec<_>>();
            let t = lua.create_sequence_from(ids.into_iter())?;
            Ok(t)
        });

        /// Returns all root node IDs (nodes with no parents).
        /// @return any
        ///
        /// # Returns
        /// `table` of `string` IDs.
        methods.add_method("getRootNodes", |lua, this, ()| {
            let ids = this.0.borrow().get_root_nodes().iter().map(|s| s.to_string()).collect::<Vec<_>>();
            let t = lua.create_sequence_from(ids.into_iter())?;
            Ok(t)
        });

        /// Returns the parent node ID of the given node, or `nil` if it is a root.
        /// @param id : string
        /// @return any
        ///
        /// # Parameters
        /// - `id` — `string`.
        ///
        /// # Returns
        /// `string` or `nil`.
        methods.add_method("getParent", |_, this, id: String| {
            Ok(this.0.borrow().get_parent(&id).map(|s| s.to_string()))
        });

        /// Returns the shortest path of node IDs from `from` to `to`, or an empty table.
        /// @param from : string
        /// @param to : string
        /// @return any
        ///
        /// # Parameters
        /// - `from` — `string`.
        /// - `to` — `string`.
        ///
        /// # Returns
        /// `table` of `string` IDs.
        methods.add_method("getPath", |lua, this, (from, to): (String, String)| {
            let path = this.0.borrow().get_path(&from, &to);
            let t = lua.create_sequence_from(path.into_iter())?;
            Ok(t)
        });

        /// Returns all node data as a list of `{id, name, unlocked, recipeId, outputItemType}` tables.
        /// @return any
        ///
        /// # Returns
        /// `table` of node info tables.
        methods.add_method("getAllNodes", |lua, this, ()| {
            let borrow = this.0.borrow();
            let nodes = borrow.get_all_nodes();
            let t = lua.create_table()?;
            for (i, node) in nodes.into_iter().enumerate() {
                let row = lua.create_table()?;
                row.set("id", node.id.clone())?;
                row.set("name", node.name.clone())?;
                row.set("unlocked", node.unlocked)?;
                row.set("recipeId", node.recipe_id.clone())?;
                row.set("outputItemType", node.output_item_type.clone())?;
                t.set(i + 1, row)?;
            }
            Ok(t)
        });

        /// Returns data for a single node as a table, or `nil` if not found.
        /// @param id : string
        /// @return any
        ///
        /// # Parameters
        /// - `id` — `string`.
        ///
        /// # Returns
        /// Table with `id`, `name`, `unlocked`, `recipeId`, `outputItemType`, or `nil`.
        methods.add_method("getNode", |lua, this, id: String| {
            let borrow = this.0.borrow();
            if let Some(node) = borrow.get_node(&id) {
                let t = lua.create_table()?;
                t.set("id", node.id.clone())?;
                t.set("name", node.name.clone())?;
                t.set("unlocked", node.unlocked)?;
                t.set("recipeId", node.recipe_id.clone())?;
                t.set("outputItemType", node.output_item_type.clone())?;
                drop(borrow);
                Ok(LuaValue::Table(t))
            } else {
                Ok(LuaValue::Nil)
            }
        });
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// LuaRecipeKnowledge
// ─────────────────────────────────────────────────────────────────────────────

#[derive(Clone)]
/// Lua-callable handle wrapping [`RecipeKnowledge`].
pub struct LuaRecipeKnowledge(pub Rc<RefCell<RecipeKnowledge>>);

impl LunaType for LuaRecipeKnowledge {
    const TYPE_NAME: &'static str = "RecipeKnowledge";
    const TYPE_HIERARCHY: &'static [&'static str] = &["RecipeKnowledge"];
}

impl LuaUserData for LuaRecipeKnowledge {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods(methods);

        /// Marks a recipe as discovered with an optional source string.
        /// @param id : string
        /// @param source : string?
        ///
        /// # Parameters
        /// - `recipe_id` — `string`: Recipe ID to discover.
        /// - `source` — `string` optional: Discovery source (e.g. `'scroll'`).
        methods.add_method("discover", |_, this, (id, source): (String, Option<String>)| {
            this.0.borrow_mut().discover(id, source.unwrap_or_default());
            Ok(())
        });
        /// Removes knowledge of a recipe. Returns `true` if the recipe was known.
        /// @param id : string
        /// @return any
        ///
        /// # Parameters
        /// - `recipe_id` — `string`: Recipe ID to forget.
        ///
        /// # Returns
        /// `boolean`.
        methods.add_method("forget", |_, this, id: String| {
            Ok(this.0.borrow_mut().forget(&id))
        });
        /// Returns `true` if the recipe is known (or auto-discover is on).
        /// @param id : string
        /// @return any
        ///
        /// # Parameters
        /// - `recipe_id` — `string`: Recipe ID to check.
        ///
        /// # Returns
        /// `boolean`.
        methods.add_method("isKnown", |_, this, id: String| {
            Ok(this.0.borrow().is_known(&id))
        });
        /// Returns a list of all known recipe IDs.
        /// @return any
        ///
        /// # Returns
        /// `table` of `string` IDs.
        methods.add_method("getKnown", |lua, this, ()| {
            let borrow = this.0.borrow();
            let ids: Vec<String> = borrow.get_known().iter().map(|s| s.to_string()).collect();
            drop(borrow);
            let t = lua.create_table()?;
            for (i, id) in ids.into_iter().enumerate() { t.set(i + 1, id)?; }
            Ok(t)
        });
        /// Returns the number of known recipes.
        /// @return integer
        ///
        /// # Returns
        /// `integer`.
        methods.add_method("count", |_, this, ()| Ok(this.0.borrow().count()));
        /// Returns the discovery source for a recipe, or `nil` if unknown.
        /// @param id : string
        /// @return any
        ///
        /// # Parameters
        /// - `recipe_id` — `string`.
        ///
        /// # Returns
        /// `string` or `nil`.
        methods.add_method("getSource", |_, this, id: String| {
            Ok(this.0.borrow().get_source(&id).map(|s| s.to_string()))
        });
        /// Enables or disables auto-discovery mode (all recipes always known).
        /// @param v : boolean
        ///
        /// # Parameters
        /// - `enabled` — `boolean`.
        methods.add_method("setAutoDiscover", |_, this, v: bool| {
            this.0.borrow_mut().set_auto_discover(v); Ok(())
        });
        /// Returns `true` if auto-discover mode is on.
        /// @return any
        ///
        /// # Returns
        /// `boolean`.
        methods.add_method("isAutoDiscover", |_, this, ()| {
            Ok(this.0.borrow().is_auto_discover())
        });
        /// Clears all recipe knowledge.
        methods.add_method("clear", |_, this, ()| {
            this.0.borrow_mut().clear(); Ok(())
        });

        /// Permanently learns a recipe via the prototype mechanic (Don't Starve pattern).
        /// @param id : string
        /// @return any
        ///
        /// # Parameters
        /// - `recipe_id` — `string`.
        ///
        /// # Returns
        /// `boolean` — `false` if already prototyped.
        methods.add_method("prototype", |_, this, id: String| {
            Ok(this.0.borrow_mut().prototype(id))
        });

        /// Returns `true` if the recipe has been prototyped.
        /// @param id : string
        /// @return any
        ///
        /// # Parameters
        /// - `recipe_id` — `string`.
        ///
        /// # Returns
        /// `boolean`.
        methods.add_method("isPrototyped", |_, this, id: String| {
            Ok(this.0.borrow().is_prototyped(&id))
        });

        /// Sets the resource cost required to research a recipe (Rust blueprint pattern).
        /// @param id : string
        /// @param cost : number
        ///
        /// # Parameters
        /// - `recipe_id` — `string`.
        /// - `cost` — `number`: Scrap / resource cost to unlock.
        methods.add_method("setResearchCost", |_, this, (id, cost): (String, f64)| {
            this.0.borrow_mut().set_research_cost(id, cost); Ok(())
        });

        /// Returns the research cost for a recipe (0 if not set).
        /// @param id : string
        /// @return any
        ///
        /// # Parameters
        /// - `recipe_id` — `string`.
        ///
        /// # Returns
        /// `number`.
        methods.add_method("getResearchCost", |_, this, id: String| {
            Ok(this.0.borrow().get_research_cost(&id))
        });

        /// Attempts to research a recipe by spending `scrap`. Returns `false` if not enough.
        /// @param id : string
        /// @param scrap : number
        /// @return any
        ///
        /// # Parameters
        /// - `recipe_id` — `string`.
        /// - `scrap` — `number`: Amount of scrap to spend.
        ///
        /// # Returns
        /// `boolean`.
        methods.add_method("research", |_, this, (id, scrap): (String, f64)| {
            Ok(this.0.borrow_mut().research(&id, scrap))
        });
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// LuaRecipeGroup
// ─────────────────────────────────────────────────────────────────────────────

#[derive(Clone)]
/// Lua-callable handle wrapping [`RecipeGroup`].
pub struct LuaRecipeGroup(pub Rc<RefCell<RecipeGroup>>);

impl LunaType for LuaRecipeGroup {
    const TYPE_NAME: &'static str = "RecipeGroup";
    const TYPE_HIERARCHY: &'static [&'static str] = &["RecipeGroup"];
}

impl LuaUserData for LuaRecipeGroup {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods(methods);

        /// Returns the group name.
        /// @return any
        ///
        /// # Returns
        /// `string`.
        methods.add_method("getName", |_, this, ()| Ok(this.0.borrow().name.clone()));
        /// Sets the group name.
        /// @param v : string
        ///
        /// # Parameters
        /// - `name` — `string`.
        methods.add_method("setName", |_, this, v: String| { this.0.borrow_mut().name = v; Ok(()) });
        /// Returns the icon asset path for this group.
        /// @return any
        ///
        /// # Returns
        /// `string`.
        methods.add_method("getIcon", |_, this, ()| Ok(this.0.borrow().icon.clone()));
        /// Sets the icon asset path.
        /// @param v : string
        ///
        /// # Parameters
        /// - `icon` — `string`: Asset path.
        methods.add_method("setIcon", |_, this, v: String| { this.0.borrow_mut().icon = v; Ok(()) });
        /// Returns the display order index.
        /// @return any
        ///
        /// # Returns
        /// `integer`.
        methods.add_method("getOrder", |_, this, ()| Ok(this.0.borrow().order));
        /// Sets the display order index.
        /// @param v : integer
        ///
        /// # Parameters
        /// - `order` — `integer`.
        methods.add_method("setOrder", |_, this, v: i32| { this.0.borrow_mut().order = v; Ok(()) });
        /// Adds a recipe ID to this group (no-op if already present).
        /// @param id : string
        ///
        /// # Parameters
        /// - `recipe_id` — `string`.
        methods.add_method("addRecipe", |_, this, id: String| {
            this.0.borrow_mut().add_recipe(id); Ok(())
        });
        /// Removes a recipe ID from this group. Returns `true` if it was present.
        /// @param id : string
        /// @return any
        ///
        /// # Parameters
        /// - `recipe_id` — `string`.
        ///
        /// # Returns
        /// `boolean`.
        methods.add_method("removeRecipe", |_, this, id: String| {
            Ok(this.0.borrow_mut().remove_recipe(&id))
        });
        /// Returns all recipe IDs in this group.
        /// @return any
        ///
        /// # Returns
        /// `table` of `string` IDs.
        methods.add_method("getRecipes", |lua, this, ()| {
            let borrow = this.0.borrow();
            let recipes = borrow.get_recipes();
            let t = lua.create_table()?;
            for (i, id) in recipes.iter().enumerate() { t.set(i + 1, id.clone())?; }
            Ok(t)
        });
        /// Returns the number of recipes in this group.
        /// @return integer
        ///
        /// # Returns
        /// `integer`.
        methods.add_method("count", |_, this, ()| Ok(this.0.borrow().count()));
        /// Returns `true` if this group contains the given recipe ID.
        /// @param id : string
        /// @return any
        ///
        /// # Parameters
        /// - `recipe_id` — `string`.
        ///
        /// # Returns
        /// `boolean`.
        methods.add_method("contains", |_, this, id: String| {
            Ok(this.0.borrow().contains(&id))
        });
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// LuaModifierPool
// ─────────────────────────────────────────────────────────────────────────────

#[derive(Clone)]
/// Lua-callable handle wrapping [`ModifierPool`].
pub struct LuaModifierPool(pub Rc<RefCell<ModifierPool>>);

impl LunaType for LuaModifierPool {
    const TYPE_NAME: &'static str = "ModifierPool";
    const TYPE_HIERARCHY: &'static [&'static str] = &["ModifierPool"];
}

impl LuaUserData for LuaModifierPool {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods(methods);

        /// Returns the name of this modifier pool.
        /// @return any
        ///
        /// # Returns
        /// `string`.
        methods.add_method("getName", |_, this, ()| Ok(this.0.borrow().name.clone()));

        /// Adds a modifier to the pool. Effects are a table of `{effectName: number}` pairs.
        /// @param name : string
        /// @param weight : number
        /// @param effects : table?
        ///
        /// # Parameters
        /// - `name` — `string`: Modifier name.
        /// - `weight` — `number`: Relative selection weight (higher = more likely).
        /// - `effects` — `table` optional: `{[effectName]: number}` effect magnitudes.
        methods.add_method("addModifier", |_, this, (name, weight, effects): (String, f64, Option<LuaTable>)| {
            let mut fx = std::collections::HashMap::new();
            if let Some(t) = effects {
                for pair in t.pairs::<String, f64>() {
                    let (k, v) = pair?;
                    fx.insert(k, v);
                }
            }
            this.0.borrow_mut().add_modifier(name, weight, fx);
            Ok(())
        });

        /// Removes a modifier by name. Returns `true` if it existed.
        /// @param name : string
        /// @return any
        ///
        /// # Parameters
        /// - `name` — `string`.
        ///
        /// # Returns
        /// `boolean`.
        methods.add_method("removeModifier", |_, this, name: String| {
            Ok(this.0.borrow_mut().remove_modifier(&name))
        });

        /// Returns the total combined weight of all pool entries.
        /// @return any
        ///
        /// # Returns
        /// `number`.
        methods.add_method("getTotalWeight", |_, this, ()| {
            Ok(this.0.borrow().get_total_weight())
        });

        /// Returns the number of entries in the pool.
        /// @return integer
        ///
        /// # Returns
        /// `integer`.
        methods.add_method("count", |_, this, ()| Ok(this.0.borrow().count()));

        /// Returns all modifier entries as a list of `{name, weight, effects}` tables.
        /// @return any
        ///
        /// # Returns
        /// `table` of modifier tables.
        methods.add_method("getModifiers", |lua, this, ()| {
            let borrow = this.0.borrow();
            let t = lua.create_table()?;
            for (i, entry) in borrow.get_modifiers().iter().enumerate() {
                let row = lua.create_table()?;
                row.set("name", entry.name.clone())?;
                row.set("weight", entry.weight)?;
                let fx = lua.create_table()?;
                for (k, v) in &entry.effects { fx.set(k.as_str(), *v)?; }
                row.set("effects", fx)?;
                t.set(i + 1, row)?;
            }
            Ok(t)
        });

        /// Rolls a random modifier using `seed` as a deterministic source.
        /// @param seed : integer
        /// @return any
        ///
        /// # Parameters
        /// - `seed` — `integer`: Deterministic seed value.
        ///
        /// # Returns
        /// `table` — `{name, weight, effects}`, or `nil` if pool is empty.
        methods.add_method("roll", |lua, this, seed: u64| {
            let borrow = this.0.borrow();
            if let Some(entry) = borrow.roll(seed) {
                let t = lua.create_table()?;
                t.set("name", entry.name.clone())?;
                t.set("weight", entry.weight)?;
                let fx = lua.create_table()?;
                for (k, v) in &entry.effects { fx.set(k.as_str(), *v)?; }
                t.set("effects", fx)?;
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

/// Register the `luna.crafting.*` table. Panics in debug mode if the same entity is registered twice.
///
/// # Parameters
/// - `lua` — `&Lua`.
/// - `luna` — `&LuaTable`.
///
/// # Returns
/// `LuaResult<()>`.
pub fn register(lua: &Lua, luna: &LuaTable) -> LuaResult<()> {
    let module = lua.create_table()?;

    /// Creates a new recipe instance.
    /// @param id : string
    /// @param recipe_type : string?
    /// @return any
    ///
    /// # Parameters
    /// - `id` — `string`.
    /// - `recipe_type` — `string` optional.
    module.set("newRecipe", lua.create_function(|_, (id, recipe_type): (String, Option<String>)| {
        let rt = recipe_type.unwrap_or_else(|| "shapeless".to_string());
        Ok(LuaRecipe(Rc::new(RefCell::new(Recipe::new(id, rt)))))
    })?)?;

    /// Creates a new recipe registry instance.
    /// @return any
    module.set("newRegistry", lua.create_function(|_, ()| {
        Ok(LuaRecipeRegistry(Rc::new(RefCell::new(RecipeRegistry::new()))))
    })?)?;

    /// Creates a new station instance.
    /// @param station_type : string
    /// @param level : integer?
    /// @return any
    ///
    /// # Parameters
    /// - `station_type` — `string`.
    /// - `level` — `integer` optional.
    module.set("newStation", lua.create_function(|_, (station_type, level): (String, Option<u32>)| {
        Ok(LuaStation(Rc::new(RefCell::new(Station::new(station_type, level.unwrap_or(1))))))
    })?)?;

    /// Creates a new craft skill instance.
    /// @param name : string
    /// @return any
    ///
    /// # Parameters
    /// - `name` — `string`.
    module.set("newCraftSkill", lua.create_function(|_, name: String| {
        Ok(LuaCraftSkill(Rc::new(RefCell::new(CraftSkill::new(name)))))
    })?)?;

    /// Creates a new craft queue instance.
    /// @param max_jobs : integer?
    /// @return any
    ///
    /// # Parameters
    /// - `max_jobs` — `integer` optional.
    module.set("newCraftQueue", lua.create_function(|_, max_jobs: Option<usize>| {
        Ok(LuaCraftQueue(Rc::new(RefCell::new(CraftQueue::new(max_jobs.unwrap_or(10))))))
    })?)?;

    /// Creates a new upgrade tree instance.
    /// @param name : string?
    /// @return any
    ///
    /// # Parameters
    /// - `name` — `string` optional.
    module.set("newUpgradeTree", lua.create_function(|_, name: Option<String>| {
        Ok(LuaUpgradeTree(Rc::new(RefCell::new(UpgradeTree::new(name.unwrap_or_default())))))
    })?)?;

    /// Creates a new recipe knowledge tracker.
    /// @return any
    module.set("newRecipeKnowledge", lua.create_function(|_, ()| {
        Ok(LuaRecipeKnowledge(Rc::new(RefCell::new(RecipeKnowledge::new()))))
    })?)?;

    /// Creates a new recipe group for UI organization.
    /// @param name : string
    /// @return any
    ///
    /// # Parameters
    /// - `name` — `string`: Group name.
    module.set("newRecipeGroup", lua.create_function(|_, name: String| {
        Ok(LuaRecipeGroup(Rc::new(RefCell::new(RecipeGroup::new(name)))))
    })?)?;

    /// Creates a new modifier pool.
    /// @param name : string
    /// @return any
    ///
    /// # Parameters
    /// - `name` — `string`: Pool identifier.
    module.set("newModifierPool", lua.create_function(|_, name: String| {
        Ok(LuaModifierPool(Rc::new(RefCell::new(ModifierPool::new(name)))))
    })?)?;

    luna.set("crafting", module)?;
    Ok(())
}
