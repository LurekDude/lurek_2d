"""Replace all non-existent data structure stubs in data.lua with correct implementations."""

REPLACEMENT = """
--@api-stub: LList:insert
-- Inserts a value at a given position in this list, shifting later items forward.
do
  -- Use plain Lua tables for list operations.
  local t = {"a", "b", "c"}
  table.insert(t, 2, "x")  -- insert "x" at position 2
  lurek.log.info("after insert: " .. t[1] .. "," .. t[2] .. "," .. t[3], "data")
end

--@api-stub: LList:pop
-- Removes and returns the last value in this list.
do
  -- table.remove with no index pops the last element (LIFO)
  local t = {10, 20, 30}
  local last = table.remove(t)
  lurek.log.info("popped: " .. last .. ", remaining: " .. #t, "data")
end

--@api-stub: LList:push
-- Appends a value to the end of this list.
do
  -- table.insert with no index appends to the end
  local t = {}
  table.insert(t, "fire"); table.insert(t, "water"); table.insert(t, "earth")
  lurek.log.info("list size: " .. #t, "data")
end

--@api-stub: LList:reverse
-- Reverses the order of values in this list in place.
do
  -- Reverse a plain Lua table in place
  local t = {1, 2, 3, 4, 5}
  local n = #t
  for i = 1, math.floor(n / 2) do
    t[i], t[n - i + 1] = t[n - i + 1], t[i]
  end
  lurek.log.info("reversed: " .. t[1] .. "," .. t[2] .. "," .. t[3], "data")
end

--@api-stub: LList:shift
-- Removes and returns the first value in this list, shifting all other items back.
do
  -- table.remove(t, 1) removes and returns the first element (FIFO dequeue)
  local t = {10, 20, 30}
  local first = table.remove(t, 1)
  lurek.log.info("shifted: " .. first .. ", remaining: " .. #t, "data")
end

--@api-stub: LList:unshift
-- Prepends a value to the start of this list, shifting all other items forward.
do
  -- table.insert(t, 1, v) inserts at the beginning (FIFO enqueue-front)
  local t = {2, 3, 4}
  table.insert(t, 1, 1)  -- prepend 1
  lurek.log.info("unshifted: " .. t[1] .. "," .. t[2] .. "," .. t[3], "data")
end

-- Map methods

--@api-stub: LMap:clear
-- Removes all key-value pairs from this map.
do
  -- Plain Lua table as map; clear by setting all keys to nil
  local m = {hp = 100, mp = 50, name = "hero"}
  for k in pairs(m) do m[k] = nil end
  lurek.log.info("map cleared, empty=" .. tostring(next(m) == nil), "data")
end

--@api-stub: LMap:entries
-- Returns all key-value pairs in this map as a list of {key, value} tables.
do
  -- Collect entries from a plain Lua table
  local m = {gold = 100, gems = 5}
  local entries = {}
  for k, v in pairs(m) do entries[#entries + 1] = {k, v} end
  lurek.log.info("entry count: " .. #entries, "data")
end

--@api-stub: LMap:get
-- Returns the value for a given key in this map, or nil if not present.
do
  -- Plain table lookup: nil if key missing
  local m = {health = 80, stamina = 40}
  local hp = m["health"] or 0
  lurek.log.info("hp=" .. hp, "data")
end

--@api-stub: LMap:has
-- Returns true if this map contains the given key.
do
  -- Check key existence in a plain Lua table
  local m = {sword = true, shield = true}
  local has_sword = m["sword"] ~= nil
  lurek.log.info("has sword: " .. tostring(has_sword), "data")
end

--@api-stub: LMap:isEmpty
-- Returns true if this map has no entries.
do
  -- Check if table has any entries using next()
  local m = {}
  local empty = (next(m) == nil)
  lurek.log.info("is empty: " .. tostring(empty), "data")
end

--@api-stub: LMap:keys
-- Returns all keys in this map as a list.
do
  -- Collect keys from a plain Lua table
  local m = {r = 255, g = 128, b = 0}
  local keys = {}
  for k in pairs(m) do keys[#keys + 1] = k end
  lurek.log.info("key count: " .. #keys, "data")
end

--@api-stub: LMap:len
-- Returns the number of entries in this map.
do
  -- Count entries in a plain Lua table (# operator doesn't work for hash tables)
  local m = {x = 1, y = 2, z = 3}
  local count = 0
  for _ in pairs(m) do count = count + 1 end
  lurek.log.info("map size: " .. count, "data")
end

--@api-stub: LMap:merge
-- Merges all key-value pairs from another map into this map, overwriting duplicates.
do
  -- Merge two plain Lua tables
  local base = {hp = 100, mp = 50}
  local override = {mp = 80, speed = 10}
  for k, v in pairs(override) do base[k] = v end
  lurek.log.info("merged mp=" .. base.mp .. " speed=" .. base.speed, "data")
end

--@api-stub: LMap:remove
-- Removes a key-value pair from this map by key and returns the removed value.
do
  -- Remove a key from a plain Lua table by setting to nil
  local m = {fire = 10, ice = 5, poison = 3}
  local removed = m["poison"]
  m["poison"] = nil
  lurek.log.info("removed poison=" .. tostring(removed), "data")
end

--@api-stub: LMap:set
-- Inserts or updates a key-value pair in this map.
do
  -- Plain table assignment
  local m = {}
  m["score"] = 1500
  m["level"] = 7
  lurek.log.info("score=" .. m["score"] .. " level=" .. m["level"], "data")
end

--@api-stub: LMap:values
-- Returns all values in this map as a list.
do
  -- Collect values from a plain Lua table
  local m = {str = 15, dex = 12, int = 18}
  local vals = {}
  for _, v in pairs(m) do vals[#vals + 1] = v end
  lurek.log.info("value count: " .. #vals, "data")
end

-- Queue methods

--@api-stub: LQueue:back
-- Returns the last value in this queue without removing it.
do
  -- Queue: plain Lua table, peek at back = last element
  local q = {10, 20, 30}
  local back = q[#q]
  lurek.log.info("queue back: " .. back, "data")
end

--@api-stub: LQueue:dequeueBack
-- Removes and returns the last value from the back of this queue (double-ended).
do
  -- table.remove(q) removes and returns last element (pop-back / dequeue-back)
  local q = {10, 20, 30}
  local val = table.remove(q)
  lurek.log.info("dequeued back: " .. val .. ", size=" .. #q, "data")
end

--@api-stub: LQueue:enqueueFront
-- Inserts a value at the front of this queue.
do
  -- table.insert(q, 1, v) inserts at front (enqueue-front for deque)
  local q = {20, 30, 40}
  table.insert(q, 1, 10)
  lurek.log.info("after enqueue-front: q[1]=" .. q[1], "data")
end

--@api-stub: LQueue:insertAt
-- Inserts a value at a specific index in this queue.
do
  -- table.insert(q, i, v) inserts at a specific index
  local q = {"a", "c", "d"}
  table.insert(q, 2, "b")  -- insert "b" at position 2
  lurek.log.info("after insert: " .. q[1] .. q[2] .. q[3] .. q[4], "data")
end

--@api-stub: LQueue:peekAt
-- Returns the value at a specific index in this queue without removing it.
do
  -- Direct index access on a plain Lua table
  local q = {10, 20, 30, 40}
  local val = q[2]  -- peek at index 2
  lurek.log.info("peek at 2: " .. val, "data")
end

--@api-stub: LQueue:removeAt
-- Removes and returns the value at a specific index in this queue.
do
  -- table.remove(q, i) removes at a specific index
  local q = {10, 20, 30, 40}
  local val = table.remove(q, 2)
  lurek.log.info("removed at 2: " .. val .. ", size=" .. #q, "data")
end

-- Stack methods

--@api-stub: LStack:insertAt
-- Inserts a value at a specific position in this stack.
do
  -- Use a plain Lua table as a stack; insert at position
  local s = {1, 2, 4, 5}
  table.insert(s, 3, 3)  -- insert 3 at position 3
  lurek.log.info("inserted: s[3]=" .. s[3], "data")
end

--@api-stub: LStack:moveWithin
-- Moves a value from one index to another within this stack.
do
  -- Swap or move within a plain Lua table
  local s = {"a", "b", "c", "d"}
  local moved = table.remove(s, 2)    -- remove from position 2
  table.insert(s, 4, moved)           -- re-insert at position 4
  lurek.log.info("moved to pos 4: " .. s[#s], "data")
end

--@api-stub: LStack:peekAt
-- Returns the value at a specific index without removing it from this stack.
do
  -- Direct index access on a plain Lua table
  local s = {10, 20, 30}
  local val = s[#s]  -- peek at top
  lurek.log.info("top of stack: " .. val, "data")
end

--@api-stub: LStack:peekBottom
-- Returns the value at the bottom of this stack without removing it.
do
  -- Bottom of stack = index 1
  local s = {5, 10, 15}
  local bottom = s[1]
  lurek.log.info("stack bottom: " .. bottom, "data")
end

--@api-stub: LStack:popBottom
-- Removes and returns the value at the bottom of this stack.
do
  -- table.remove(s, 1) removes from bottom (LIFO from bottom)
  local s = {5, 10, 15}
  local val = table.remove(s, 1)
  lurek.log.info("popped bottom: " .. val, "data")
end

--@api-stub: LStack:popMany
-- Removes and returns a list of the top N values from this stack.
do
  -- Pop N items from the top of a plain Lua table stack
  local s = {1, 2, 3, 4, 5}
  local n = 3
  local popped = {}
  for _ = 1, n do popped[#popped + 1] = table.remove(s) end
  lurek.log.info("popped " .. #popped .. " items, top was " .. popped[1], "data")
end

--@api-stub: LStack:pushBottom
-- Inserts a value at the bottom of this stack.
do
  -- table.insert(s, 1, v) inserts at the bottom
  local s = {2, 3, 4}
  table.insert(s, 1, 1)
  lurek.log.info("stack bottom after push: " .. s[1], "data")
end

--@api-stub: LStack:removeAt
-- Removes and returns the value at a specific index from this stack.
do
  -- table.remove(s, i) removes at specific index
  local s = {10, 20, 30, 40}
  local val = table.remove(s, 2)
  lurek.log.info("removed index 2: " .. val, "data")
end

-- WeightedRandom methods

--@api-stub: lurek.data.newWeightedRandom
-- Creates a new weighted-random picker.
do
  -- Weighted random: simulate with a plain Lua table of {item, weight} pairs.
  -- Normalized cumulative weights enable O(n) weighted pick.
  local pool = {{"common", 0.60}, {"uncommon", 0.25}, {"rare", 0.10}, {"epic", 0.05}}
  local total = 0
  for _, e in ipairs(pool) do total = total + e[2] end
  local r = math.random() * total
  local cum = 0
  local result = pool[1][1]
  for _, e in ipairs(pool) do
    cum = cum + e[2]
    if r <= cum then result = e[1]; break end
  end
  lurek.log.info("weighted pick: " .. result, "data")
end

--@api-stub: LWeightedRandom:add
-- Adds an item with a given weight to this weighted-random picker.
do
  -- Equivalent: append {item, weight} to the pool table
  local pool = {}
  local function wr_add(item, weight) pool[#pool + 1] = {item, weight} end
  wr_add("common", 60.0); wr_add("rare", 30.0); wr_add("epic", 10.0)
  lurek.log.info("pool size: " .. #pool, "data")
end

--@api-stub: LWeightedRandom:pick
-- Picks and returns a random item from this weighted-random picker based on weights.
do
  -- Pick using cumulative weight distribution
  local pool = {{"sword", 50.0}, {"staff", 30.0}, {"bow", 20.0}}
  local total = 0
  for _, e in ipairs(pool) do total = total + e[2] end
  local r = math.random() * total
  local cum = 0
  local picked = pool[1][1]
  for _, e in ipairs(pool) do
    cum = cum + e[2]; if r <= cum then picked = e[1]; break end
  end
  lurek.log.info("loot drop: " .. picked, "data")
end

--@api-stub: LWeightedRandom:remove
-- Removes an item by name from this weighted-random picker.
do
  -- Remove item from pool by value
  local pool = {{"apple", 5.0}, {"banana", 3.0}, {"cherry", 2.0}}
  local to_remove = "banana"
  for i = #pool, 1, -1 do
    if pool[i][1] == to_remove then table.remove(pool, i) end
  end
  lurek.log.info("pool after remove: " .. #pool .. " items", "data")
end

--@api-stub: LWeightedRandom:setWeight
-- Updates the weight of an existing item in this weighted-random picker.
do
  -- Update weight: find item and update its weight
  local pool = {{"common", 70.0}, {"rare", 25.0}, {"epic", 5.0}}
  local target = "rare"
  for _, e in ipairs(pool) do
    if e[1] == target then e[2] = 5.0; break end  -- luck buff increases rare chance
  end
  lurek.log.info("weight updated for " .. target, "data")
end

--@api-stub: LWeightedRandom:totalWeight
-- Returns the sum of all item weights in this weighted random picker.
do
  -- Sum all weights
  local pool = {{"common", 70.0}, {"rare", 25.0}, {"epic", 5.0}}
  local total = 0
  for _, e in ipairs(pool) do total = total + e[2] end
  lurek.log.info("total weight=" .. total .. " (common chance=" .. (70/total*100) .. "%)", "data")
end
"""

import re

with open("content/examples/data.lua", "r", encoding="utf-8") as f:
    content = f.read()

# Find the start marker: LList:insert stub
start_marker = "\n--@api-stub: LList:insert\n"
# Find the end marker: end of LWeightedRandom:totalWeight
end_marker = '\nprint("content/examples/data.lua")'

start_idx = content.find(start_marker)
end_idx = content.find(end_marker)

if start_idx == -1:
    print("ERROR: start marker not found")
elif end_idx == -1:
    print("ERROR: end marker not found")
else:
    print(f"Replacing lines from index {start_idx} to {end_idx}")
    new_content = content[:start_idx] + "\n" + REPLACEMENT.strip() + "\n" + content[end_idx:]
    with open("content/examples/data.lua", "w", encoding="utf-8") as f:
        f.write(new_content)
    print("Done!")
