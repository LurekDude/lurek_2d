# Quest Tracker

Quest tables, objective types, multi-step progression, journal UI, and completion rewards.

## Key Concepts

- **Quest table**: Each quest has id, title, description, objectives, state, and rewards.
- **Objective types**: Reach a location, collect N items, defeat N enemies, talk to NPC.
- **State machine**: `inactive` → `active` → `complete` (or `failed`).
- **Multi-step**: Objectives completed in sequence. Next objective unlocks when previous completes.
- **Journal UI**: List active quests, show progress, highlight tracked quest.

## Quest Data

```lua
local QUESTS = {
    {
        id = "rescue_cat",
        title = "Lost Cat",
        description = "Find the elder's missing cat in the forest.",
        objectives = {
            { type = "reach",   target = "forest_cave", label = "Go to the forest cave", done = false },
            { type = "collect", target = "cat",   count = 1, current = 0, label = "Find the cat", done = false },
            { type = "talk",    target = "elder",  label = "Return to the elder", done = false },
        },
        rewards = { xp = 50, items = { { id = "potion", count = 3 } } },
        state = "inactive",  -- inactive | active | complete | failed
    },
}
```

## Quest Manager

```lua
local active_quests = {}

local function start_quest(quest_id)
    for _, q in ipairs(QUESTS) do
        if q.id == quest_id and q.state == "inactive" then
            q.state = "active"
            active_quests[#active_quests + 1] = q
            return true
        end
    end
    return false
end

local function current_objective(quest)
    for _, obj in ipairs(quest.objectives) do
        if not obj.done then return obj end
    end
    return nil
end

local function complete_quest(quest)
    quest.state = "complete"
    -- Grant rewards
    if quest.rewards.xp then player.xp = player.xp + quest.rewards.xp end
    if quest.rewards.items then
        for _, item in ipairs(quest.rewards.items) do
            add_item(player.inv, item.id, item.count)
        end
    end
end
```

## Objective Progress

```lua
local function notify_reach(location_id)
    for _, q in ipairs(active_quests) do
        local obj = current_objective(q)
        if obj and obj.type == "reach" and obj.target == location_id then
            obj.done = true
            check_quest_complete(q)
        end
    end
end

local function notify_collect(item_id, count)
    for _, q in ipairs(active_quests) do
        local obj = current_objective(q)
        if obj and obj.type == "collect" and obj.target == item_id then
            obj.current = obj.current + count
            if obj.current >= obj.count then
                obj.done = true
                check_quest_complete(q)
            end
        end
    end
end

local function notify_kill(enemy_type)
    for _, q in ipairs(active_quests) do
        local obj = current_objective(q)
        if obj and obj.type == "kill" and obj.target == enemy_type then
            obj.current = (obj.current or 0) + 1
            if obj.current >= obj.count then
                obj.done = true
                check_quest_complete(q)
            end
        end
    end
end

local function notify_talk(npc_id)
    for _, q in ipairs(active_quests) do
        local obj = current_objective(q)
        if obj and obj.type == "talk" and obj.target == npc_id then
            obj.done = true
            check_quest_complete(q)
        end
    end
end

local function check_quest_complete(quest)
    for _, obj in ipairs(quest.objectives) do
        if not obj.done then return end
    end
    complete_quest(quest)
end
```

## Journal UI

```lua
local function draw_journal()
    luna.gfx.setColor(0, 0, 0, 0.9)
    luna.gfx.rectangle("fill", 50, 30, 700, 540)
    luna.gfx.setColor(1, 1, 1, 1)
    luna.gfx.print("QUEST JOURNAL", 60, 40)

    local y = 80
    for _, q in ipairs(active_quests) do
        luna.gfx.setColor(1, 1, 0.5, 1)
        luna.gfx.print(q.title, 70, y)
        y = y + 20
        for _, obj in ipairs(q.objectives) do
            local mark = obj.done and "[x] " or "[ ] "
            local progress = ""
            if obj.count then progress = " (" .. (obj.current or 0) .. "/" .. obj.count .. ")" end
            luna.gfx.setColor(obj.done and {0.5,0.5,0.5} or {1,1,1})
            luna.gfx.print("  " .. mark .. obj.label .. progress, 80, y)
            y = y + 18
        end
        y = y + 10
    end
    luna.gfx.setColor(1, 1, 1, 1)
end
```

## Common Pitfalls

- **Objectives out of order** — `current_objective` returns the first incomplete one. If you want parallel objectives, iterate all instead.
- **Duplicate notifications** — guard against double-counting (e.g., picking up 2 items fires `notify_collect` twice with count=1).
- **Quest not removed from active** — when completed or failed, remove from `active_quests` or filter in the UI.
- **Missing save integration** — quest state must be serialized. Save `state`, `current` counts, and `done` flags.
- **Reward overflow** — check inventory space before granting item rewards. Handle full inventory gracefully.
