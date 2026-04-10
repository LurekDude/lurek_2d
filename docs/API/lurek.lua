---@meta
--- Auto-generated Lurek2D API documentation for LuaCATS.

luna = {}

---@class lurek.ai
lurek.ai = {}

--- Lua-side wrapper around an [`AIWorld`].
---@class AIWorld
local AIWorld = {}

--- Registers a new named agent and returns its handle.
---@param name any
---@return Agent
function AIWorld:addAgent(name) end

--- Returns the agent handle for the given name, or nil.
---@param name any
---@return Agent?
function AIWorld:getAgent(name) end

--- Returns the number of registered agents.
---@return integer
function AIWorld:getAgentCount() end

--- Returns a snapshot of the world-level blackboard.
---@return Blackboard
function AIWorld:getGlobalBlackboard() end

--- Removes an agent by its userdata handle.
---@param agent any
---@return nil
function AIWorld:removeAgent(agent) end

--- Returns the type name of this object.
---@return string
function AIWorld:type() end

--- Returns true if this object is of the given type.
---@param name any
---@return boolean
function AIWorld:typeOf(name) end

--- Advances all agents by dt seconds.
---@param dt any
---@return nil
function AIWorld:update(dt) end

--- Lua-side wrapper for an agent accessed by name through the owning world.
---@class Agent
local Agent = {}

--- Adds a tag to this agent.
---@param tag any
---@return nil
function Agent:addTag(tag) end

--- Returns the agent's local blackboard.
---@return Blackboard
function Agent:getBlackboard() end

--- Returns the name of the current decision model.
---@return string
function Agent:getDecisionModel() end

--- Returns the maximum steering force cap.
---@return number
function Agent:getMaxForce() end

--- Returns the maximum speed cap.
---@return number
function Agent:getMaxSpeed() end

--- Returns the agent's registered name.
---@return string
function Agent:getName() end

--- Returns the agent's current position.
---@return number
function Agent:getPosition() end

--- Returns the agent's scheduling priority.
---@return integer
function Agent:getPriority() end

--- Returns the agent's current velocity.
---@return number
function Agent:getVelocity() end

--- Returns true if the agent has the given tag.
---@param tag any
---@return boolean
function Agent:hasTag(tag) end

--- Removes a tag from this agent.
---@param tag any
---@return nil
function Agent:removeTag(tag) end

--- Sets the active decision model.
---@param model any
---@return nil
function Agent:setDecisionModel(model) end

--- Sets the maximum steering force cap.
---@param v any
---@return nil
function Agent:setMaxForce(v) end

--- Sets the maximum speed cap.
---@param v any
---@return nil
function Agent:setMaxSpeed(v) end

--- Sets the agent's world-space position.
---@param x any
---@param y any
---@return nil
function Agent:setPosition(x, y) end

--- Sets the scheduling priority (higher = earlier).
---@param p any
---@return nil
function Agent:setPriority(p) end

--- Sets the agent's velocity vector.
---@param x any
---@param y any
---@return nil
function Agent:setVelocity(x, y) end

--- Returns the type name of this object.
---@return string
function Agent:type() end

--- Returns true if this object is of the given type.
---@param name any
---@return boolean
function Agent:typeOf(name) end

--- Lua-side wrapper around a [`BTNode`].
---@class BTNode
local BTNode = {}

--- Adds a child node (Selector, Sequence, or Parallel only).
---@param child_ud any
---@return nil
function BTNode:addChild(child_ud) end

--- Returns the number of direct children.
---@return integer
function BTNode:getChildCount() end

--- Returns the repeat count, or 0 if not a Repeater.
---@return integer
function BTNode:getCount() end

--- Returns the node type as a string.
---@return string
function BTNode:getNodeType() end

--- Resets all running-child memos and repeater counters.
---@return nil
function BTNode:reset() end

--- Sets the single child of a decorator node.
---@param child_ud any
---@return nil
function BTNode:setChild(child_ud) end

--- Sets the repeat count for a Repeater node.
---@param n any
---@return nil
function BTNode:setCount(n) end

--- Sets the failure policy for a Parallel node.
---@param policy any
---@return nil
function BTNode:setFailurePolicy(policy) end

--- Sets the success policy for a Parallel node.
---@param policy any
---@return nil
function BTNode:setSuccessPolicy(policy) end

--- Returns the type name of this object.
---@return string
function BTNode:type() end

--- Returns true if this object is of the given type.
---@param name any
---@return boolean
function BTNode:typeOf(name) end

--- Lua-side wrapper around a [`BehaviorTree`].
---@class BehaviorTree
local BehaviorTree = {}

--- Returns the status from the last tick.
---@return string
function BehaviorTree:getLastStatus() end

--- Sets the root node of this behavior tree.
---@param node_ud any
---@return nil
function BehaviorTree:setRoot(node_ud) end

--- Returns the type name of this object.
---@return string
function BehaviorTree:type() end

--- Returns true if this object is of the given type.
---@param name any
---@return boolean
function BehaviorTree:typeOf(name) end

--- Lua-side wrapper around a [`Blackboard`].
---@class Blackboard
local Blackboard = {}

--- Removes all local entries.
---@return nil
function Blackboard:clear() end

--- Returns all local keys as a table.
---@return table
function Blackboard:getKeys() end

--- Returns the number of local entries.
---@return integer
function Blackboard:getSize() end

--- Returns true if a value exists under the key.
---@param key any
---@return boolean
function Blackboard:has(key) end

--- Removes the entry at key.
---@param key any
---@return nil
function Blackboard:remove(key) end

--- Stores a boolean under the given key.
---@param key any
---@param value any
---@return nil
function Blackboard:setBool(key, value) end

--- Stores a number under the given key.
---@param key any
---@param value any
---@return nil
function Blackboard:setNumber(key, value) end

--- Stores a string under the given key.
---@param key any
---@param value any
---@return nil
function Blackboard:setString(key, value) end

--- Returns the type name of this object.
---@return string
function Blackboard:type() end

--- Returns true if this object is of the given type.
---@param name any
---@return boolean
function Blackboard:typeOf(name) end

--- Lua-side wrapper around a [`CommandQueue`].
---@class CommandQueue
local CommandQueue = {}

--- Cancels the front command if it is interruptible.
---@return boolean
function CommandQueue:cancelCurrent() end

--- Discards all queued commands.
---@return nil
function CommandQueue:clear() end

--- Returns the number of queued commands.
---@return integer
function CommandQueue:getCount() end

--- Returns the target coordinates of the front command.
---@return number
function CommandQueue:getCurrentTarget() end

--- Returns the kind of the front command, or nil.
---@return string?
function CommandQueue:getCurrentType() end

--- Returns true if there are no queued commands.
---@return boolean
function CommandQueue:isEmpty() end

--- Returns the type name of this object.
---@return string
function CommandQueue:type() end

--- Returns true if this object is of the given type.
---@param name any
---@return boolean
function CommandQueue:typeOf(name) end

--- Lua-side wrapper around a [`GOAPPlanner`].
---@class GOAPPlanner
local GOAPPlanner = {}

--- Returns the number of registered actions.
---@return integer
function GOAPPlanner:getActionCount() end

--- Returns the number of registered goals.
---@return integer
function GOAPPlanner:getGoalCount() end

--- Returns the type name of this object.
---@return string
function GOAPPlanner:type() end

--- Returns true if this object is of the given type.
---@param name any
---@return boolean
function GOAPPlanner:typeOf(name) end

--- Lua-side wrapper around an [`InfluenceMap`].
---@class InfluenceMap
local InfluenceMap = {}

--- Adds a named influence layer.
---@param name any
---@return nil
function InfluenceMap:addLayer(name) end

--- Clears all layers.
---@return nil
function InfluenceMap:clearAll() end

--- Clears all influence in a layer.
---@param layer any
---@return nil
function InfluenceMap:clearLayer(layer) end

--- Multiplies all influences by a decay factor.
---@param layer any
---@param factor any
---@return nil
function InfluenceMap:decay(layer, factor) end

--- Returns the cell size in world units.
---@return number
function InfluenceMap:getCellSize() end

--- Returns the grid height.
---@return integer
function InfluenceMap:getHeight() end

--- Returns the world-space position of the maximum value.
---@param layer any
---@return number
function InfluenceMap:getMaxPosition(layer) end

--- Returns the world-space position of the minimum value.
---@param layer any
---@return number
function InfluenceMap:getMinPosition(layer) end

--- Returns the grid width.
---@return integer
function InfluenceMap:getWidth() end

--- Returns true if the named layer exists.
---@param name any
---@return boolean
function InfluenceMap:hasLayer(name) end

--- Returns the type name of this object.
---@return string
function InfluenceMap:type() end

--- Returns true if this object is of the given type.
---@param name any
---@return boolean
function InfluenceMap:typeOf(name) end

--- Lua-side wrapper around a [`QLearner`].
---@class QLearner
local QLearner = {}

--- Returns the greedy-best action for the state (1-based).
---@param state any
---@return integer
function QLearner:bestAction(state) end

--- Selects an action using epsilon-greedy policy (1-based).
---@param state any
---@return integer
function QLearner:chooseAction(state) end

--- Restores the Q-table from a JSON string.
---@param json any
---@return nil
function QLearner:deserialize(json) end

--- Ends the current episode, applying epsilon decay.
---@return nil
function QLearner:endEpisode() end

--- Returns the number of discrete actions.
---@return integer
function QLearner:getActionCount() end

--- Returns the current discount factor.
---@return number
function QLearner:getDiscountFactor() end

--- Returns the number of completed episodes.
---@return integer
function QLearner:getEpisodeCount() end

--- Returns the epsilon decay multiplier.
---@return number
function QLearner:getExplorationDecay() end

--- Returns the current exploration rate.
---@return number
function QLearner:getExplorationRate() end

--- Returns the current learning rate.
---@return number
function QLearner:getLearningRate() end

--- Returns the Q-value for a state-action pair (1-based).
---@param state any
---@param action any
---@return number
function QLearner:getQValue(state, action) end

--- Returns the number of discrete states.
---@return integer
function QLearner:getStateCount() end

--- Serializes the Q-table to a JSON string.
---@return string
function QLearner:serialize() end

--- Sets the discount factor gamma.
---@param v any
---@return nil
function QLearner:setDiscountFactor(v) end

--- Sets the epsilon decay multiplier.
---@param v any
---@return nil
function QLearner:setExplorationDecay(v) end

--- Sets the exploration rate epsilon.
---@param v any
---@return nil
function QLearner:setExplorationRate(v) end

--- Sets the learning rate alpha.
---@param v any
---@return nil
function QLearner:setLearningRate(v) end

--- Returns the type name of this object.
---@return string
function QLearner:type() end

--- Returns true if this object is of the given type.
---@param name any
---@return boolean
function QLearner:typeOf(name) end

--- Lua-side wrapper around a [`Squad`].
---@class Squad
local Squad = {}

--- Adds an agent by name to this squad.
---@param name any
---@return nil
function Squad:addMember(name) end

--- Returns the squad's shared blackboard.
---@return Blackboard
function Squad:getBlackboard() end

--- Returns the current formation type name.
---@return string
function Squad:getFormation() end

--- Returns the formation spacing in world units.
---@return number
function Squad:getFormationSpacing() end

--- Returns the leader name, or nil.
---@return string?
function Squad:getLeader() end

--- Returns the number of squad members.
---@return integer
function Squad:getMemberCount() end

--- Returns the member names as a table.
---@return table
function Squad:getMembers() end

--- Returns the squad name.
---@return string
function Squad:getName() end

--- Removes an agent by name from this squad.
---@param name any
---@return nil
function Squad:removeMember(name) end

--- Sets the squad leader by name.
---@param name any
---@return nil
function Squad:setLeader(name) end

--- Returns the type name of this object.
---@return string
function Squad:type() end

--- Returns true if this object is of the given type.
---@param name any
---@return boolean
function Squad:typeOf(name) end

--- Lua-side wrapper around a [`StateMachine`].
---@class StateMachine
local StateMachine = {}

--- Registers a named state with optional lifecycle callbacks.
---@param name any
---@param opts any
---@return nil
function StateMachine:addState(name, opts) end

--- Forces a transition to the named state.
---@param name any
---@return nil
function StateMachine:forceState(name) end

--- Returns the current state name, or nil.
---@return string?
function StateMachine:getCurrentState() end

--- Returns seconds spent in the current state.
---@return number
function StateMachine:getTimeInState() end

--- Sets the initial state.
---@param name any
---@return nil
function StateMachine:setInitialState(name) end

--- Returns the type name of this object.
---@return string
function StateMachine:type() end

--- Returns true if this object is of the given type.
---@param name any
---@return boolean
function StateMachine:typeOf(name) end

--- Lua-side wrapper around a [`SteeringManager`].
---@class SteeringManager
local SteeringManager = {}

--- Returns the number of active behaviors.
---@return integer
function SteeringManager:getBehaviorCount() end

--- Returns the current combination mode.
---@return string
function SteeringManager:getCombineMode() end

--- Returns the last computed steering force.
---@return number
function SteeringManager:getLastSteering() end

--- Sets the force combination mode.
---@param mode any
---@return nil
function SteeringManager:setCombineMode(mode) end

--- Returns the type name of this object.
---@return string
function SteeringManager:type() end

--- Returns true if this object is of the given type.
---@param name any
---@return boolean
function SteeringManager:typeOf(name) end

--- Lua-side wrapper around a [`UtilityAI`].
---@class UtilityAI
local UtilityAI = {}

--- Evaluates all actions and returns the best action name, or nil.
---@return string?
function UtilityAI:evaluate() end

--- Returns the number of registered actions.
---@return integer
function UtilityAI:getActionCount() end

--- Returns the name of the last chosen action, or nil.
---@return string?
function UtilityAI:getLastAction() end

--- Returns the type name of this object.
---@return string
function UtilityAI:type() end

--- Returns true if this object is of the given type.
---@param name any
---@return boolean
function UtilityAI:typeOf(name) end

--- Creates a BT action leaf with a Lua callback.
---@param callback any
---@return BTNode
function lurek.ai.newAction(callback) end

--- Creates a new behavior tree.
---@return BehaviorTree
function lurek.ai.newBehaviorTree() end

--- Creates a new standalone blackboard.
---@return Blackboard
function lurek.ai.newBlackboard() end

--- Creates an RTS-style command queue.
---@return CommandQueue
function lurek.ai.newCommandQueue() end

--- Creates a BT condition leaf with a Lua predicate.
---@param callback any
---@return BTNode
function lurek.ai.newCondition(callback) end

--- Creates a new GOAP planning solver.
---@return GOAPPlanner
function lurek.ai.newGOAPPlanner() end

--- Creates a multi-layer influence map grid.
---@param w any
---@param h any
---@param cs any
---@return InfluenceMap
function lurek.ai.newInfluenceMap(w, h, cs) end

--- Creates a BT inverter decorator.
---@return BTNode
function lurek.ai.newInverter() end

--- Creates a BT parallel node with optional policies.
---@param sp? any (optional)
---@param fp? any (optional)
---@return BTNode
function lurek.ai.newParallel(sp, fp) end

--- Creates a tabular Q-learner.
---@param sc any
---@param ac any
---@return QLearner
function lurek.ai.newQLearner(sc, ac) end

--- Creates a BT repeater decorator.
---@param count? any (optional)
---@return BTNode
function lurek.ai.newRepeater(count) end

--- Creates a BT selector node.
---@return BTNode
function lurek.ai.newSelector() end

--- Creates a BT sequence node.
---@return BTNode
function lurek.ai.newSequence() end

--- Creates a named squad for formation positioning.
---@param name any
---@return Squad
function lurek.ai.newSquad(name) end

--- Creates a new finite state machine.
---@return StateMachine
function lurek.ai.newStateMachine() end

--- Creates a new steering behavior manager.
---@return SteeringManager
function lurek.ai.newSteeringManager() end

--- Creates a BT succeeder decorator.
---@return BTNode
function lurek.ai.newSucceeder() end

--- Creates a new utility AI evaluator.
---@return UtilityAI
function lurek.ai.newUtilityAI() end

--- Creates a new AI world container.
---@return AIWorld
function lurek.ai.newWorld() end

---@class lurek.animation
lurek.animation = {}

--- Lua-side wrapper around an [`Animation`] controller.
---@class Animation
local Animation = {}

--- Adds a single frame to the frame pool by source rectangle.
---@param x any
---@param y any
---@param w any
---@param h any
---@return integer
function Animation:addFrame(x, y, w, h) end

--- Returns the name of the currently playing clip, or nil.
---@return string?
function Animation:getClip() end

--- Returns the number of registered clips.
---@return integer
function Animation:getClipCount() end

--- Returns the current position within the active clip (0-based).
---@return integer
function Animation:getCurrentFrame() end

--- Returns the total number of frames in the frame pool.
---@return integer
function Animation:getFrameCount() end

--- Returns the source quad (x, y, w, h) for the current frame, or nil.
---@return table?
function Animation:getQuad() end

--- Returns the playback speed multiplier.
---@return number
function Animation:getSpeed() end

--- Returns true if the current clip is set to loop.
---@return boolean
function Animation:isLooping() end

--- Returns true if a clip is currently playing.
---@return boolean
function Animation:isPlaying() end

--- Pauses playback at the current frame.
---@return nil
function Animation:pause() end

--- Starts playback of the named clip.
---@param name any
---@return boolean
function Animation:play(name) end

--- Drains and returns all pending animation events as a table.
---@return table
function Animation:pollEvents() end

--- Resumes playback from the current frame.
---@return nil
function Animation:resume() end

--- Sets the playback position within the current clip.
---@param index any
---@return nil
function Animation:setFrame(index) end

--- Sets the playback speed multiplier.
---@param speed any
---@return nil
function Animation:setSpeed(speed) end

--- Stops playback and resets to frame 0.
---@return nil
function Animation:stop() end

--- Advances the animation by dt seconds.
---@param dt any
---@return nil
function Animation:update(dt) end

--- Creates a new, empty Animation controller.
---@return Animation
function lurek.animation.new() end

---@class lurek.audio
lurek.audio = {}

--- Lua-side wrapper for an audio bus resource.
---@class Bus
local Bus = {}

--- Returns the bus name.
---@return string
function Bus:getName() end

--- Returns the bus pitch multiplier.
---@return number
function Bus:getPitch() end

--- Returns the bus volume.
---@return number
function Bus:getVolume() end

--- Returns true if this bus is paused.
---@return boolean
function Bus:isPaused() end

--- Pauses all sources on this bus.
---@return nil
function Bus:pause() end

--- Resumes all sources on this bus.
---@return nil
function Bus:resume() end

--- Sets the pitch multiplier for all sources on this bus.
---@param pitch any
---@return nil
function Bus:setPitch(pitch) end

--- Sets the volume for all sources on this bus.
---@param vol any
---@return nil
function Bus:setVolume(vol) end

--- Returns the type name of this object.
---@return string
function Bus:type() end

--- Returns true if this object is of the given type.
---@param name any
---@return boolean
function Bus:typeOf(name) end

--- Lua-side wrapper for a streaming audio decoder.
---@class Decoder
local Decoder = {}

--- Decodes the next chunk of samples, or nil at EOF.
---@return SoundData
function Decoder:decode() end

--- Returns the bit depth.
---@return integer
function Decoder:getBitDepth() end

--- Returns the number of audio channels.
---@return integer
function Decoder:getChannelCount() end

--- Returns the total duration in seconds.
---@return number
function Decoder:getDuration() end

--- Returns the sample rate in Hz.
---@return integer
function Decoder:getSampleRate() end

--- Returns true if seeking is supported.
---@return boolean
function Decoder:isSeekable() end

--- Releases the decoder (no-op).
---@return nil
function Decoder:release() end

--- Rewinds to the beginning.
---@return nil
function Decoder:rewind() end

--- Seeks to a time offset in seconds.
---@param offset any
---@return nil
function Decoder:seek(offset) end

--- Returns the current position in seconds.
---@return number
function Decoder:tell() end

--- Lua-side wrapper for the MIDI player.
---@class MidiPlayer
local MidiPlayer = {}

--- Returns the assigned bus, or nil.
---@return Bus
function MidiPlayer:getBus() end

--- Returns the number of MIDI channels.
---@return integer
function MidiPlayer:getChannelCount() end

--- Returns the GM instrument for a MIDI channel (1-indexed).
---@param ch any
---@return integer
function MidiPlayer:getChannelInstrument(ch) end

--- Returns the volume for a MIDI channel (1-indexed).
---@param ch any
---@return number
function MidiPlayer:getChannelVolume(ch) end

--- Returns the total MIDI duration in seconds.
---@return number
function MidiPlayer:getDuration() end

--- Returns the file path of the loaded MIDI, or nil.
---@return string
function MidiPlayer:getFilePath() end

--- Returns the total note count in the MIDI sequence.
---@return integer
function MidiPlayer:getNoteCount() end

--- Returns the original MIDI file tempo in BPM.
---@return number
function MidiPlayer:getOriginalTempo() end

--- Returns the SoundFont file path, or nil (stub).
---@return string
function MidiPlayer:getSoundFontPath() end

--- Returns the current tempo in BPM.
---@return number
function MidiPlayer:getTempo() end

--- Returns the current tempo scale factor.
---@return number
function MidiPlayer:getTempoScale() end

--- Returns the PPQ resolution from the MIDI header.
---@return integer
function MidiPlayer:getTicksPerBeat() end

--- Returns the number of tracks in the MIDI sequence.
---@return integer
function MidiPlayer:getTrackCount() end

--- Returns the name of a MIDI track (1-indexed), or nil.
---@param idx any
---@return string
function MidiPlayer:getTrackName(idx) end

--- Returns the current MIDI volume.
---@return number
function MidiPlayer:getVolume() end

--- Returns true if a MIDI channel is muted (1-indexed).
---@param ch any
---@return boolean
function MidiPlayer:isChannelMuted(ch) end

--- Returns true if a MIDI sequence is loaded.
---@return boolean
function MidiPlayer:isLoaded() end

--- Returns true if looping is enabled.
---@return boolean
function MidiPlayer:isLooping() end

--- Returns true if MIDI playback is paused.
---@return boolean
function MidiPlayer:isPaused() end

--- Returns true if MIDI is currently playing.
---@return boolean
function MidiPlayer:isPlaying() end

--- Returns true if a track is muted (1-indexed).
---@param idx any
---@return boolean
function MidiPlayer:isTrackMuted(idx) end

--- Loads a MIDI file from the given path.
---@param path any
---@return boolean
function MidiPlayer:load(path) end

--- Loads MIDI data from a Lua string.
---@param data string
---@return boolean
function MidiPlayer:loadData(data) end

--- Pauses MIDI playback.
---@return nil
function MidiPlayer:pause() end

--- Starts MIDI playback.
---@return nil
function MidiPlayer:play() end

--- Seeks to a time position in seconds.
---@param secs any
---@return nil
function MidiPlayer:seek(secs) end

--- Routes MIDI output through a bus (or nil to clear).
---@param bus_val any
---@return nil
function MidiPlayer:setBus(bus_val) end

--- Mutes or unmutes a MIDI channel (1-indexed).
---@param ch any
---@param muted any
---@return nil
function MidiPlayer:setChannelMuted(ch, muted) end

--- Sets volume for a MIDI channel (1-indexed).
---@param ch any
---@param vol any
---@return nil
function MidiPlayer:setChannelVolume(ch, vol) end

--- Enables or disables looping.
---@param looping any
---@return nil
function MidiPlayer:setLooping(looping) end

--- Registers a playback-end callback (stub).
---@param cb any
---@return nil
function MidiPlayer:setOnEnd(cb) end

--- Registers a note-off callback (stub).
---@param cb any
---@return nil
function MidiPlayer:setOnNoteOff(cb) end

--- Registers a note-on callback (stub).
---@param cb any
---@return nil
function MidiPlayer:setOnNoteOn(cb) end

--- Loads a SoundFont file into this player (stub).
---@param path any
---@return nil
function MidiPlayer:setSoundFont(path) end

--- Sets playback tempo in BPM.
---@param bpm any
---@return nil
function MidiPlayer:setTempo(bpm) end

--- Sets the tempo scale factor (1.0 = original speed).
---@param scale any
---@return nil
function MidiPlayer:setTempoScale(scale) end

--- Mutes or unmutes a track (1-indexed).
---@param idx any
---@param muted any
---@return nil
function MidiPlayer:setTrackMuted(idx, muted) end

--- Sets MIDI playback volume.
---@param vol any
---@return nil
function MidiPlayer:setVolume(vol) end

--- Solos a MIDI channel (1-indexed).
---@param ch any
---@return nil
function MidiPlayer:soloChannel(ch) end

--- Stops MIDI playback.
---@return nil
function MidiPlayer:stop() end

--- Returns the current playback position in seconds.
---@return number
function MidiPlayer:tell() end

--- Returns the type name of this object.
---@return string
function MidiPlayer:type() end

--- Returns true if this object is of the given type.
---@param name any
---@return boolean
function MidiPlayer:typeOf(name) end

--- Clears solo on all channels.
---@return nil
function MidiPlayer:unsoloAll() end

--- Reverts to the built-in default SoundFont (stub).
---@return nil
function MidiPlayer:useDefaultSoundFont() end

--- Lua-side wrapper for an audio source resource.
---@class Source
local Source = {}

--- Removes any active filter from this source.
---@return nil
function Source:clearFilter() end

--- Creates an independent copy of this source.
---@return Source
function Source:clone() end

--- Fades in from silence over the given duration in seconds.
---@param dur any
---@return nil
function Source:fadeIn(dur) end

--- Returns the total duration in seconds.
---@return number
function Source:getDuration() end

--- Returns the current fade-in duration in seconds.
---@return number
function Source:getFadeIn() end

--- Returns the high-pass filter cutoff frequency.
---@return number
function Source:getHighpass() end

--- Returns the low-pass filter cutoff frequency.
---@return number
function Source:getLowpass() end

--- Returns the current stereo panning value.
---@return number
function Source:getPan() end

--- Returns the current pitch multiplier.
---@return number
function Source:getPitch() end

--- Returns the source type ("static" or "stream").
---@return string
function Source:getType() end

--- Returns the current volume multiplier.
---@return number
function Source:getVolume() end

--- Returns true if looping is enabled.
---@return boolean
function Source:isLooping() end

--- Returns true if playback is paused.
---@return boolean
function Source:isPaused() end

--- Returns true if currently playing.
---@return boolean
function Source:isPlaying() end

--- Returns true if playback has stopped.
---@return boolean
function Source:isStopped() end

--- Pauses playback at the current position.
---@return nil
function Source:pause() end

--- Starts or resumes playback.
---@return nil
function Source:play() end

--- Resumes playback from the paused position.
---@return nil
function Source:resume() end

--- Seeks to a time position in seconds.
---@param pos any
---@return nil
function Source:seek(pos) end

--- Applies a high-pass filter at the given cutoff frequency.
---@param cutoff_hz any
---@return nil
function Source:setHighpass(cutoff_hz) end

--- Enables or disables looping playback.
---@param looping any
---@return nil
function Source:setLooping(looping) end

--- Applies a low-pass filter at the given cutoff frequency.
---@param cutoff_hz any
---@return nil
function Source:setLowpass(cutoff_hz) end

--- Sets stereo panning (-1.0 left to 1.0 right).
---@param pan any
---@return nil
function Source:setPan(pan) end

--- Sets the pitch multiplier (1.0 = normal).
---@param pitch any
---@return nil
function Source:setPitch(pitch) end

--- Sets playback volume (0.0 = silent, 1.0 = full).
---@param vol any
---@return nil
function Source:setVolume(vol) end

--- Stops playback and resets seek position.
---@return nil
function Source:stop() end

--- Returns the current playback position in seconds.
---@return number
function Source:tell() end

--- Adds a DSP effect to a bus.
---@param bus_name any
---@param effect_type_str any
---@param params? any (optional)
---@return integer
function lurek.audio.add_effect(bus_name, effect_type_str, params) end

--- Removes any active filter from a source.
---@param id_val any
---@return nil
function lurek.audio.clearFilter(id_val) end

--- Unloads the active SoundFont.
---@return nil
function lurek.audio.clearMidiSoundFont() end

--- Creates an independent copy of a source.
---@param id_val any
---@return Source
function lurek.audio.clone(id_val) end

--- Creates a bus by name (functional style).
---@param name any
---@param parent_name? any (optional)
---@return nil
function lurek.audio.create_bus(name, parent_name) end

--- Fades a source in from silence over the given duration.
---@param id_val any
---@param dur any
---@return nil
function lurek.audio.fadeIn(id_val, dur) end

--- Returns the number of currently playing sources.
---@return integer
function lurek.audio.getActiveSourceCount() end

--- Returns the current distance model name.
---@return string
function lurek.audio.getDistanceModel() end

--- Returns the current Doppler scale.
---@return number
function lurek.audio.getDopplerScale() end

--- Returns the total duration of a source in seconds.
---@param id_val any
---@return number
function lurek.audio.getDuration(id_val) end

--- Returns the fade-in duration of a source.
---@param id_val any
---@return number
function lurek.audio.getFadeIn(id_val) end

--- Returns the free buffer slots in a queueable source.
---@param qsource_id any
---@return integer
function lurek.audio.getFreeBufferCount(qsource_id) end

--- Returns the high-pass filter cutoff of a source.
---@param id_val any
---@return number
function lurek.audio.getHighpass(id_val) end

--- Returns the 3D listener position (x, y, z).
---@return number
function lurek.audio.getListener() end

--- Returns the 2D listener position (x, y).
---@return number
function lurek.audio.getListener2D() end

--- Returns the low-pass filter cutoff of a source.
---@param id_val any
---@return number
function lurek.audio.getLowpass(id_val) end

--- Returns the global master volume.
---@return number
function lurek.audio.getMasterVolume() end

--- Returns the maximum number of simultaneous sources.
---@return integer
function lurek.audio.getMaxSources() end

--- Returns the current peak level (stub).
---@return number
function lurek.audio.getMeter() end

--- Returns the 6-component orientation of a source.
---@param id_val any
---@return number
function lurek.audio.getOrientation(id_val) end

--- Returns the source stereo panning.
---@param id_val any
---@return number
function lurek.audio.getPan(id_val) end

--- Returns the source pitch multiplier.
---@param id_val any
---@return number
function lurek.audio.getPitch(id_val) end

--- Returns the current audio output device name.
---@return string
function lurek.audio.getPlaybackDevice() end

--- Returns a table of available audio output device names.
---@return table
function lurek.audio.getPlaybackDevices() end

--- Returns the 3D position of a source (x, y, z).
---@param id_val any
---@return number
function lurek.audio.getPosition(id_val) end

--- Returns the bus a source is assigned to, or nil.
---@param id_val any
---@return Bus
function lurek.audio.getSourceBus(id_val) end

--- Returns the total number of registered sources.
---@return integer
function lurek.audio.getSourceCount() end

--- Returns the type string ("static" or "stream") of a source.
---@param id_val any
---@return string
function lurek.audio.getSourceType(id_val) end

--- Returns the velocity of a source (x, y, z).
---@param id_val any
---@return number
function lurek.audio.getVelocity(id_val) end

--- Returns the source volume.
---@param id_val any
---@return number
function lurek.audio.getVolume(id_val) end

--- Returns true if a SoundFont is loaded.
---@return boolean
function lurek.audio.hasMidiSoundFont() end

--- Returns true if looping is enabled.
---@param id_val any
---@return boolean
function lurek.audio.isLooping(id_val) end

--- Returns true if the source is paused.
---@param id_val any
---@return boolean
function lurek.audio.isPaused(id_val) end

--- Returns true if the source is playing.
---@param id_val any
---@return boolean
function lurek.audio.isPlaying(id_val) end

--- Returns true if the source is stopped.
---@param id_val any
---@return boolean
function lurek.audio.isStopped(id_val) end

--- Creates a named audio bus for grouping sources.
---@param name any
---@return Bus
function lurek.audio.newBus(name) end

--- Creates a streaming audio decoder.
---@param source any
---@param buffersize? any (optional)
---@return Decoder
function lurek.audio.newDecoder(source, buffersize) end

--- Creates a MIDI player, optionally loading a file.
---@param path? any (optional)
---@return MidiPlayer
function lurek.audio.newMidiPlayer(path) end

--- Creates a queueable source for manual PCM buffering.
---@param sample_rate integer
---@param bit_depth integer
---@param channels integer
---@param buffer_count integer
---@return integer
function lurek.audio.newQueueableSource(sample_rate, bit_depth, channels, buffer_count) end

--- Creates a SoundData from a file or as a silent buffer.
---@param args any
---@return SoundData
function lurek.audio.newSoundData(args) end

--- Loads an audio file and returns a Source handle.
---@param args any
---@return Source
function lurek.audio.newSource(args) end

--- Pauses playback at the current position.
---@param id_val any
---@return nil
function lurek.audio.pause(id_val) end

--- Pauses all currently playing sources.
---@return nil
function lurek.audio.pauseAll() end

--- Plays a source, with optional bus routing via options table.
---@param id_val any
---@param options? any (optional)
---@return integer
function lurek.audio.play(id_val, options) end

--- Plays the source in a continuous loop.
---@param id_val any
---@return nil
function lurek.audio.playLooping(id_val) end

--- Starts playback of a queueable source.
---@param qsource_id any
---@return nil
function lurek.audio.playQueueable(qsource_id) end

--- Pushes a SoundData buffer into a queueable source.
---@param qsource_id any
---@param sd any
---@return nil
function lurek.audio.queueSource(qsource_id, sd) end

--- Releases a source and frees its memory.
---@param id_val any
---@return boolean
function lurek.audio.release(id_val) end

--- Removes a DSP effect from a bus.
---@param bus_name any
---@param effect_id any
---@return boolean
function lurek.audio.remove_effect(bus_name, effect_id) end

--- Resumes playback from pause.
---@param id_val any
---@return nil
function lurek.audio.resume(id_val) end

--- Resumes all paused sources.
---@return nil
function lurek.audio.resumeAll() end

--- Saves a SoundData as a 16-bit PCM WAV file at the given path.
---@param sd_ud any
---@param filename any
---@return nil
function lurek.audio.saveWAV(sd_ud, filename) end

--- Seeks to a time position in seconds.
---@param id_val any
---@param pos any
---@return nil
function lurek.audio.seek(id_val, pos) end

--- Sets the distance attenuation model.
---@param model any
---@return nil
function lurek.audio.setDistanceModel(model) end

--- Sets the global Doppler effect scale.
---@param scale any
---@return nil
function lurek.audio.setDopplerScale(scale) end

--- Applies a high-pass filter to a source.
---@param id_val any
---@param cutoff_hz any
---@return nil
function lurek.audio.setHighpass(id_val, cutoff_hz) end

--- Sets the 3D listener position.
---@param x any
---@param y any
---@param z? any (optional)
---@return nil
function lurek.audio.setListener(x, y, z) end

--- Sets the 2D listener position for spatial audio.
---@param x any
---@param y any
---@return nil
function lurek.audio.setListener2D(x, y) end

--- Enables or disables looping.
---@param id_val any
---@param looping any
---@return nil
function lurek.audio.setLooping(id_val, looping) end

--- Applies a low-pass filter to a source.
---@param id_val any
---@param cutoff_hz any
---@return nil
function lurek.audio.setLowpass(id_val, cutoff_hz) end

--- Sets the global master volume.
---@param vol any
---@return nil
function lurek.audio.setMasterVolume(vol) end

--- Sets the metering scale (stub).
---@param scale any
---@return nil
function lurek.audio.setMeter(scale) end

--- Sets the global SoundFont for MIDI synthesis.
---@param path any
---@return nil
function lurek.audio.setMidiSoundFont(path) end

--- Sets the 6-component orientation of a source.
---@param id_val any
---@param fx any
---@param fy any
---@param fz any
---@param ux any
---@param uy any
---@param uz any
---@return nil
function lurek.audio.setOrientation(id_val, fx, fy, fz, ux, uy, uz) end

--- Sets stereo panning (-1.0 left to 1.0 right).
---@param id_val any
---@param pan any
---@return nil
function lurek.audio.setPan(id_val, pan) end

--- Sets source pitch multiplier.
---@param id_val any
---@param pitch any
---@return nil
function lurek.audio.setPitch(id_val, pitch) end

--- Selects an audio output device by name.
---@param name any
---@return nil
function lurek.audio.setPlaybackDevice(name) end

--- Sets the 3D position of a source.
---@param id_val any
---@param x any
---@param y any
---@param z? any (optional)
---@return nil
function lurek.audio.setPosition(id_val, x, y, z) end

--- Assigns a source to a bus.
---@param id_val any
---@param bus_val any
---@return nil
function lurek.audio.setSourceBus(id_val, bus_val) end

--- Sets the velocity of a source for Doppler.
---@param id_val any
---@param x any
---@param y any
---@param z? any (optional)
---@return nil
function lurek.audio.setVelocity(id_val, x, y, z) end

--- Sets source playback volume.
---@param id_val any
---@param vol any
---@return nil
function lurek.audio.setVolume(id_val, vol) end

--- Sets a bus volume by name.
---@param name any
---@param volume any
---@return nil
function lurek.audio.set_bus_volume(name, volume) end

--- Sets a parameter on a DSP effect.
---@param bus_name any
---@param effect_id any
---@param param_name any
---@param value any
---@return boolean
function lurek.audio.set_effect_param(bus_name, effect_id, param_name, value) end

--- Stops playback and resets seek position.
---@param id_val any
---@return nil
function lurek.audio.stop(id_val) end

--- Stops all currently playing sources.
---@return nil
function lurek.audio.stopAll() end

--- Stops a queueable source and drains its buffers.
---@param qsource_id any
---@return nil
function lurek.audio.stopQueueable(qsource_id) end

--- Returns the current playback position in seconds.
---@param id_val any
---@return number
function lurek.audio.tell(id_val) end

---@class lurek.simulator
lurek.simulator = {}

--- Returns the name of the active script, or nil if idle.
---@return string?
function lurek.simulator.getCurrentScript() end

--- Returns the index of the next step to be dispatched.
---@return integer
function lurek.simulator.getCurrentStep() end

--- Returns seconds elapsed since playback started.
---@return number
function lurek.simulator.getElapsedTime() end

--- Returns an array of all registered script names.
---@return table
function lurek.simulator.getScripts() end

--- Returns the total number of steps in the active script.
---@return integer
function lurek.simulator.getStepCount() end

--- Returns true if a script with the given name is registered.
---@param name any
---@return boolean
function lurek.simulator.hasScript(name) end

--- Returns true if all steps in the active script have been dispatched.
---@return boolean
function lurek.simulator.isComplete() end

--- Returns true if playback is currently paused.
---@return boolean
function lurek.simulator.isPaused() end

--- Returns true if the simulator is actively playing a script.
---@return boolean
function lurek.simulator.isRunning() end

--- Loads a named script from a Lua data table containing a steps array.
---@param name any
---@param data any
---@return nil
function lurek.simulator.load(name, data) end

--- Parses a TOML string and registers it as a named script.
---@param name any
---@param toml_str any
---@return nil
function lurek.simulator.loadFromToml(name, toml_str) end

--- Pauses playback at the current step position.
---@return nil
function lurek.simulator.pause() end

--- Resumes playback from a paused position.
---@return nil
function lurek.simulator.resume() end

--- Starts playback of the named script from the beginning.
---@param name any
---@return nil
function lurek.simulator.start(name) end

--- Stops playback and resets the simulator to idle.
---@return nil
function lurek.simulator.stop() end

--- Removes a loaded script by name, returning true if it existed.
---@param name any
---@return boolean
function lurek.simulator.unload(name) end

--- Advances the playback clock by dt seconds, dispatching due steps.
---@param dt any
---@return nil
function lurek.simulator.update(dt) end

---@class lurek.camera
lurek.camera = {}

--- Lua-side wrapper around a [`Camera2D`] instance.
---@class Camera2D
local Camera2D = {}

--- Clears the follow target so the camera stops tracking.
---@return nil
function Camera2D:clearTarget() end

--- Returns the camera's world-space position as x, y.
---@return number
function Camera2D:getPosition() end

--- Returns the rotation in radians.
---@return number
function Camera2D:getRotation() end

--- Returns the current viewport as x, y, w, h.
---@return number
function Camera2D:getViewport() end

--- Returns the visible world area as x, y, w, h.
---@return number
function Camera2D:getVisibleArea() end

--- Returns the current zoom factor.
---@return number
function Camera2D:getZoom() end

--- Instantly moves the camera to look at the given position.
---@param x any
---@param y any
---@return nil
function Camera2D:lookAt(x, y) end

--- Translates the camera by dx, dy in world space.
---@param dx any
---@param dy any
---@return nil
function Camera2D:move(dx, dy) end

--- Removes previously set world-space bounds.
---@return nil
function Camera2D:removeBounds() end

--- Sets world-space bounds for camera clamping.
---@param x any
---@param y any
---@param w any
---@param h any
---@return nil
function Camera2D:setBounds(x, y, w, h) end

--- Sets the dead zone half-extents for camera follow.
---@param w any
---@param h any
---@return nil
function Camera2D:setDeadZone(w, h) end

--- Sets the follow smooth interpolation speed (0.0 = instant snap).
---@param speed any
---@return nil
function Camera2D:setFollowSmooth(speed) end

--- Sets the look-ahead multiplier for follow prediction.
---@param mul any
---@return nil
function Camera2D:setLookAhead(mul) end

--- Sets the camera's world-space position.
---@param x any
---@param y any
---@return nil
function Camera2D:setPosition(x, y) end

--- Sets the rotation in radians.
---@param r any
---@return nil
function Camera2D:setRotation(r) end

--- Sets the follow target position.
---@param x any
---@param y any
---@return nil
function Camera2D:setTarget(x, y) end

--- Sets the viewport rectangle in screen pixels.
---@param x any
---@param y any
---@param w any
---@param h any
---@return nil
function Camera2D:setViewport(x, y, w, h) end

--- Sets the uniform zoom factor (1.0 = natural size).
---@param zoom any
---@return nil
function Camera2D:setZoom(zoom) end

--- Starts a screen-shake effect.
---@param intensity any
---@param duration any
---@return nil
function Camera2D:shake(intensity, duration) end

--- Converts world coordinates to screen coordinates.
---@param wx any
---@param wy any
---@return number
function Camera2D:toScreen(wx, wy) end

--- Converts screen coordinates to world coordinates.
---@param sx any
---@param sy any
---@return number
function Camera2D:toWorld(sx, sy) end

--- Advances the camera simulation by dt seconds.
---@param dt any
---@return nil
function Camera2D:update(dt) end

--- Creates a new Camera2D with the given viewport dimensions.
---@param vw any
---@param vh any
---@return Camera2D
function lurek.camera.new(vw, vh) end

---@class lurek.compute
lurek.compute = {}

--- Lua-side wrapper around [`NdArray`].
---@class Array
local Array = {}

--- Element-wise absolute value.
---@return Array
function Array:abs() end

--- Returns true if all elements are nonzero.
---@return boolean
function Array:all() end

--- Returns true if any element is nonzero.
---@return boolean
function Array:any() end

--- Returns the 1-based flat index of the maximum element.
---@return integer
function Array:argmax() end

--- Returns the 1-based flat index of the minimum element.
---@return integer
function Array:argmin() end

--- Bitwise AND of two Int32 arrays.
---@param other any
---@return Array
function Array:bitwiseAnd(other) end

--- Bitwise left shift of an Int32 array.
---@param amount any
---@return Array
function Array:bitwiseLShift(amount) end

--- Bitwise NOT of an Int32 array.
---@return Array
function Array:bitwiseNot() end

--- Bitwise OR of two Int32 arrays.
---@param other any
---@return Array
function Array:bitwiseOr(other) end

--- Bitwise right shift of an Int32 array.
---@param amount any
---@return Array
function Array:bitwiseRShift(amount) end

--- Bitwise XOR of two Int32 arrays.
---@param other any
---@return Array
function Array:bitwiseXor(other) end

--- Clamps each element to the given range.
---@param min any
---@param max any
---@return Array
function Array:clamp(min, max) end

--- Returns a deep copy of this array.
---@return Array
function Array:clone() end

--- 2D convolution with zero-padding.
---@param kernel any
---@return Array
function Array:convolve2D(kernel) end

--- Returns the count of nonzero elements.
---@return integer
function Array:countNonZero() end

--- Morphological dilation with a diamond structuring element.
---@param radius any
---@return Array
function Array:dilate(radius) end

--- Dot product of two 1D arrays.
---@param other any
---@return number
function Array:dot(other) end

--- Morphological erosion with a diamond structuring element.
---@param radius any
---@return Array
function Array:erode(radius) end

--- Fills all elements with the given value in-place.
---@param val any
---@return nil
function Array:fill(val) end

--- Returns the element at the given 1-based indices.
---@param args any
---@return number
function Array:get(args) end

--- Returns the element data type name.
---@return string
function Array:getDataType() end

--- Returns the number of dimensions.
---@return integer
function Array:getDimensions() end

--- Returns the shape as a table of dimension sizes.
---@return table
function Array:getShape() end

--- Returns the total number of elements.
---@return integer
function Array:getSize() end

--- Returns false (CPU arrays only).
---@return boolean
function Array:isOnGPU() end

--- Matrix multiplication of two 2D arrays.
---@param other any
---@return Array
function Array:matmul(other) end

--- Maximum of all elements, or along an axis (1-based).
---@param axis? any (optional)
---@return number|Array
function Array:max(axis) end

--- Mean of all elements, or along an axis (1-based).
---@param axis? any (optional)
---@return number|Array
function Array:mean(axis) end

--- Minimum of all elements, or along an axis (1-based).
---@param axis? any (optional)
---@return number|Array
function Array:min(axis) end

--- Element-wise negation.
---@return Array
function Array:neg() end

--- Raises each element to a scalar exponent.
---@param exp any
---@return Array
function Array:pow(exp) end

--- Returns a new array with the given shape and the same data.
---@param shape any
---@return Array
function Array:reshape(shape) end

--- Sets the element at the given 1-based indices to a value.
---@param args any
---@return nil
function Array:set(args) end

--- Element-wise square root.
---@return Array
function Array:sqrt() end

--- Sum of all elements, or along an axis (1-based).
---@param axis? any (optional)
---@return number|Array
function Array:sum(axis) end

--- Returns a mask array with 1.0 where elements >= val, else 0.0.
---@param val any
---@return Array
function Array:threshold(val) end

--- Returns all elements as a flat table of numbers.
---@return table
function Array:toTable() end

--- Returns the transposed 2D array.
---@return Array
function Array:transpose() end

--- Returns the type name "Array".
---@return string
function Array:type() end

--- Returns true when the given name matches "Array" or a parent type.
---@param name any
---@return boolean
function Array:typeOf(name) end

--- Creates an array from a Lua table of numbers with optional shape and dtype.
---@param data any
---@param shape? any (optional)
---@param dtype? any (optional)
---@return Array
function lurek.compute.fromTable(data, shape, dtype) end

--- Creates a zero-initialized array with the given shape and optional dtype.
---@param shape any
---@param dtype? any (optional)
---@return Array
function lurek.compute.newArray(shape, dtype) end

--- Creates a one-filled array with the given shape and optional dtype.
---@param shape any
---@param dtype? any (optional)
---@return Array
function lurek.compute.ones(shape, dtype) end

--- Creates a 1D array from start to stop with optional step and dtype.
---@param start any
---@param stop any
---@param step? any (optional)
---@param dtype? any (optional)
---@return Array
function lurek.compute.range(start, stop, step, dtype) end

--- Creates a zero-filled array with the given shape and optional dtype.
---@param shape any
---@param dtype? any (optional)
---@return Array
function lurek.compute.zeros(shape, dtype) end

---@class lurek.data
lurek.data = {}

---@class DataView
local DataView = {}

--- Reads a 64-bit float at the given offset.
---@param offset any
---@return number
function DataView:getDouble(offset) end

--- Reads a 32-bit float at the given offset.
---@param offset any
---@return number
function DataView:getFloat(offset) end

--- Reads a signed 16-bit integer at the given offset.
---@param offset any
---@return integer
function DataView:getInt16(offset) end

--- Reads a signed 32-bit integer at the given offset.
---@param offset any
---@return integer
function DataView:getInt32(offset) end

--- Reads a signed 8-bit integer at the given offset.
---@param offset any
---@return integer
function DataView:getInt8(offset) end

--- Returns the size of this view in bytes.
---@return integer
function DataView:getSize() end

--- Reads an unsigned 16-bit integer at the given offset.
---@param offset any
---@return integer
function DataView:getUInt16(offset) end

--- Reads an unsigned 32-bit integer at the given offset.
---@param offset any
---@return integer
function DataView:getUInt32(offset) end

--- Reads an unsigned 8-bit integer at the given offset.
---@param offset any
---@return integer
function DataView:getUInt8(offset) end

--- Compresses data using the given algorithm (deflate, gzip, lz4).
---@param format_str any
---@param raw_data any
---@param level? any (optional)
---@return string
function lurek.data.compress(format_str, raw_data, level) end

--- Decodes encoded text back to binary (base64, hex).
---@param format_str any
---@param encoded any
---@return string
function lurek.data.decode(format_str, encoded) end

--- Decompresses data using the given algorithm (deflate, gzip, lz4).
---@param format_str any
---@param compressed any
---@return string
function lurek.data.decompress(format_str, compressed) end

--- Encodes binary data using the given format (base64, hex).
---@param format_str any
---@param raw_data any
---@return string
function lurek.data.encode(format_str, raw_data) end

--- Encodes a Lua table into a TOML string.
---@param tbl any
---@return string
function lurek.data.encodeToml(tbl) end

--- Returns the number of bytes the given format and values would occupy.
---@param fmt any
---@param vals any
---@return integer
function lurek.data.getPackedSize(fmt, vals) end

--- Returns the cryptographic hash of the input (md5, sha1, sha256, sha512).
---@param algo_str any
---@param raw_data any
---@return string
function lurek.data.hash(algo_str, raw_data) end

--- Creates a new mutable byte buffer from a size or string.
---@param value any
---@return ByteData
function lurek.data.newByteData(value) end

--- Creates a read-only windowed view into a byte string.
---@param raw any
---@param offset? any (optional)
---@param size? any (optional)
---@return DataView
function lurek.data.newDataView(raw, offset, size) end

--- Packs values into a binary byte string using the format string.
---@param fmt any
---@param vals any
---@return string
function lurek.data.pack(fmt, vals) end

--- Parses a TOML string into a Lua table.
---@param text any
---@return table
function lurek.data.parseToml(text) end

--- Reads values using the Lurek2D Binary Pack Format.
---@param fmt any
---@param raw any
---@param offset? any (optional)
function lurek.data.read(fmt, raw, offset) end

--- Returns the byte size of a Lurek2D Binary Pack Format string.
---@param fmt any
---@return integer
function lurek.data.size(fmt) end

--- Unpacks values from a binary byte string, returning values followed by next offset.
---@param fmt any
---@param raw any
---@param offset? any (optional)
function lurek.data.unpack(fmt, raw, offset) end

--- Writes values using the Lurek2D Binary Pack Format.
---@param fmt any
---@param vals any
---@return string
function lurek.data.write(fmt, vals) end

---@class lurek.dataframe
lurek.dataframe = {}

--- Lua-side wrapper around a shared [`DataFrame`].
---@class DataFrame
local DataFrame = {}

--- Adds a row from an optional table of name-value pairs, returns 1-based index.
---@param row_tbl? any (optional)
---@return integer
function DataFrame:addRow(row_tbl) end

--- Returns a deep copy of this DataFrame.
---@return DataFrame
function DataFrame:clone() end

--- Returns a table of column names.
---@return table
function DataFrame:columns() end

--- Returns the row count (alias for nrows).
---@return integer
function DataFrame:count() end

--- Counts distinct values in a column, returns a DataFrame with value and count columns.
---@param col any
---@return DataFrame
function DataFrame:countBy(col) end

--- Returns descriptive statistics for all numeric columns.
---@return DataFrame
function DataFrame:describe() end

--- Removes rows where the given column is nil, returns a new DataFrame.
---@param col any
---@return DataFrame
function DataFrame:dropNil(col) end

--- Replaces nil values in a column with the given value.
---@param col any
---@param val any
---@return nil
function DataFrame:fillNil(col, val) end

--- Returns all values in a column as a table.
---@param col any
---@return table
function DataFrame:getColumn(col) end

--- Returns a row as a table of name-value pairs.
---@param row any
---@return table
function DataFrame:getRow(row) end

--- Returns a single cell value.
---@param row any
---@param col any
---@return LuaValue
function DataFrame:getValue(row, col) end

--- Groups rows by column value, returns a table of DataFrames keyed by value.
---@param col any
---@return table
function DataFrame:groupBy(col) end

--- Returns the first n rows (default 5).
---@param n? any (optional)
---@return DataFrame
function DataFrame:head(n) end

--- Returns the maximum numeric value in a column.
---@param col any
---@return number
function DataFrame:max(col) end

--- Returns the mean of numeric values in a column.
---@param col any
---@return number
function DataFrame:mean(col) end

--- Returns the median of numeric values in a column.
---@param col any
---@return number
function DataFrame:median(col) end

--- Appends rows from another DataFrame in-place.
---@param other any
---@return nil
function DataFrame:merge(other) end

--- Returns the minimum numeric value in a column.
---@param col any
---@return number
function DataFrame:min(col) end

--- Returns the number of columns.
---@return integer
function DataFrame:ncols() end

--- Returns the number of rows.
---@return integer
function DataFrame:nrows() end

--- Executes a SQL query against this DataFrame.
---@param sql_str any
---@return DataFrame
function DataFrame:query(sql_str) end

--- Removes a column by name or index.
---@param col any
---@return nil
function DataFrame:removeColumn(col) end

--- Removes a row by 1-based index.
---@param row any
---@return nil
function DataFrame:removeRow(row) end

--- Renames a column.
---@param col any
---@param new_name any
---@return nil
function DataFrame:rename(col, new_name) end

--- Returns a random sample of n rows.
---@param n any
---@param seed? any (optional)
---@return DataFrame
function DataFrame:sample(n, seed) end

--- Selects a subset of columns, returns a new DataFrame.
---@param cols any
---@return DataFrame
function DataFrame:select(cols) end

--- Returns rows from start to end (1-based, inclusive).
---@param start any
---@param end any
---@return DataFrame
function DataFrame:slice(start, end) end

--- Returns the population standard deviation of numeric values in a column.
---@param col any
---@return number
function DataFrame:stddev(col) end

--- Returns the sum of numeric values in a column.
---@param col any
---@return number
function DataFrame:sum(col) end

--- Returns the last n rows (default 5).
---@param n? any (optional)
---@return DataFrame
function DataFrame:tail(n) end

--- Serializes this DataFrame to a binary LVDF string.
---@param lua Lua
---@return string
function DataFrame:toBinary(lua) end

--- Serializes this DataFrame to a CSV string.
---@return string
function DataFrame:toCSV() end

--- Serializes this DataFrame to a JSON string.
---@return string
function DataFrame:toJSON() end

--- Returns a formatted string table representation.
---@return string
function DataFrame:toString() end

--- Converts this DataFrame to a Lua table of row tables.
---@return table
function DataFrame:toTable() end

--- Returns the type name of this object.
---@return string
function DataFrame:type() end

--- Returns true if this object is of the given type.
---@param name any
---@return boolean
function DataFrame:typeOf(name) end

--- Returns unique values in a column as a table.
---@param col any
---@return table
function DataFrame:unique(col) end

--- Returns the population variance of numeric values in a column.
---@param col any
---@return number
function DataFrame:variance(col) end

--- Lua-side wrapper around a shared [`Database`].
---@class Database
local Database = {}

--- Removes all tables.
---@return nil
function Database:clear() end

--- Returns a copy of a table by name, or nil if not found.
---@param name any
---@return DataFrame?
function Database:getTable(name) end

--- Returns true if a table with the given name exists.
---@param name any
---@return boolean
function Database:hasTable(name) end

--- Returns a table of all table names.
---@return table
function Database:listTables() end

--- Merges all tables from another Database into this one.
---@param other any
---@return nil
function Database:merge(other) end

--- Executes a SQL query against the database tables.
---@param sql_str any
---@return DataFrame
function Database:query(sql_str) end

--- Removes a table by name.
---@param name any
---@return nil
function Database:removeTable(name) end

--- Returns the number of tables.
---@return integer
function Database:tableCount() end

--- Serializes all tables to a JSON object string.
---@return string
function Database:toJSON() end

--- Returns the type name of this object.
---@return string
function Database:type() end

--- Returns true if this object is of the given type.
---@param name any
---@return boolean
function Database:typeOf(name) end

--- Deserializes a binary LVDF string into a DataFrame.
---@param s any
---@return DataFrame
function lurek.dataframe.fromBinary(s) end

--- Parses a CSV string into a DataFrame.
---@param s any
---@return DataFrame
function lurek.dataframe.fromCSV(s) end

--- Parses a JSON string into a DataFrame.
---@param s any
---@return DataFrame
function lurek.dataframe.fromJSON(s) end

--- Creates a DataFrame from an array of row tables.
---@param rows any
---@return DataFrame
function lurek.dataframe.fromTable(rows) end

--- Creates a new empty DataFrame.
---@return DataFrame
function lurek.dataframe.newDataFrame() end

--- Creates a new empty Database.
---@return Database
function lurek.dataframe.newDatabase() end

--- Generates a DataFrame with random data from column definitions.
---@param defs_tbl any
---@param n any
---@param seed? any (optional)
---@return DataFrame
function lurek.dataframe.random(defs_tbl, n, seed) end

---@class lurek.debugbridge
lurek.debugbridge = {}

--- Broadcasts a JSON event to all connected clients.
---@param event any
---@param json_data any
function lurek.debugbridge.broadcast(event, json_data) end

--- Captures a print message and broadcasts it to connected clients.
---@param msg any
---@param source? any (optional)
---@param line? any (optional)
function lurek.debugbridge.capturePrint(msg, source, line) end

--- Clears the print history.
function lurek.debugbridge.clearPrintHistory() end

--- Returns the number of connected TCP clients.
---@return integer
function lurek.debugbridge.getClientCount() end

--- Returns performance statistics.
---@return table
function lurek.debugbridge.getPerformance() end

--- Returns the server port (0 if not running).
---@return integer
function lurek.debugbridge.getPort() end

--- Returns the print history.
---@param count? any (optional)
---@return table
function lurek.debugbridge.getPrintHistory(count) end

--- Returns whether the server is currently running.
---@return bool
function lurek.debugbridge.isRunning() end

--- Returns whether a screenshot is currently requested.
---@return bool
function lurek.debugbridge.isScreenshotRequested() end

--- Poll for pending Lua-dependent requests from TCP clients.
function lurek.debugbridge.poll() end

--- Flags a screenshot request for the next frame.
---@param scale? any (optional)
function lurek.debugbridge.requestScreenshot(scale) end

--- Sets the maximum print history size.
---@param max any
function lurek.debugbridge.setMaxPrintHistory(max) end

--- Start the TCP debug server on 127.0.0.1:port.
---@param port? any (optional)
---@return boolean
function lurek.debugbridge.start(port) end

--- Stop the TCP debug server and close all connections.
function lurek.debugbridge.stop() end

---@class lurek.devtools
lurek.devtools = {}

--- Clears all log history.
function lurek.devtools.clearLog() end

--- Clears all watched paths.
function lurek.devtools.clearWatches() end

--- Evaluates a Lua string and returns (success, results...).
---@param code any
---@return any
function lurek.devtools.eval(code) end

--- Registers a named live watch. The getter function is called on demand to sample a value.
---@param name any
---@param getter any
---@param category? any (optional)
---@return integer
function lurek.devtools.exposeWatch(name, getter, category) end

--- Returns the Lua call stack as a table of frames.
---@param max_depth? any (optional)
---@return table
function lurek.devtools.getCallStack(max_depth) end

--- Returns the raw frame-time sample array.
---@return table
function lurek.devtools.getFrameHistory() end

--- Returns the current frame-history buffer capacity.
---@return integer
function lurek.devtools.getFrameHistorySize() end

--- Returns a table of computed frame statistics.
---@return table
function lurek.devtools.getFrameStats() end

--- Returns whether console log output is enabled.
---@return boolean
function lurek.devtools.getLogConsole() end

--- Returns the current log file path.
---@return string
function lurek.devtools.getLogFile() end

--- Returns recent log entries as an array of tables.
---@param count? any (optional)
---@return table
function lurek.devtools.getLogHistory(count) end

--- Returns the current minimum log level.
---@return string
function lurek.devtools.getLogLevel() end

--- Returns zone data table for a specific frame (0 or nil = most recent).
---@param frame? any (optional)
---@return table
function lurek.devtools.getProfileData(frame) end

--- Returns the number of retained profile frames.
---@return integer
function lurek.devtools.getProfileFrameCount() end

--- Returns the file watch poll interval in seconds.
---@return number
function lurek.devtools.getWatchInterval() end

--- Returns an array of all watched paths.
---@return table
function lurek.devtools.getWatchedPaths() end

--- Calls all registered watch getters and returns a table of {name, category, value} records.
---@return table
function lurek.devtools.getWatches() end

--- Returns whether the console is considered open.
---@return boolean
function lurek.devtools.isConsoleOpen() end

--- Returns whether the profiler is enabled.
---@return boolean
function lurek.devtools.isProfilingEnabled() end

--- Logs a message at the given level.
---@param level any
---@param message any
function lurek.devtools.log(level, message) end

--- Opens the console window (updates the console flag; returns true).
---@return boolean
function lurek.devtools.openConsole() end

--- Seals the current frame of profiling data.
function lurek.devtools.profileFrame() end

--- Closes the most recent profiling zone.
function lurek.devtools.profilePop() end

--- Opens a named profiling zone on the stack.
---@param name any
function lurek.devtools.profilePush(name) end

--- Records a frame-time sample (call each frame with delta time in seconds).
---@param dt_val any
function lurek.devtools.recordFrameTime(dt_val) end

--- Removes a watch by the id returned from exposeWatch. Returns true if removed.
---@param id any
---@return boolean
function lurek.devtools.removeWatch(id) end

--- Clears all profiling data and resets the zone stack.
function lurek.devtools.resetProfile() end

--- Polls all watched paths and returns paths whose mtime changed.
---@return table
function lurek.devtools.scan() end

--- Sets the frame-history buffer capacity (clamped 10-10000).
---@param size any
function lurek.devtools.setFrameHistorySize(size) end

--- Enables or disables console log output.
---@param enabled any
function lurek.devtools.setLogConsole(enabled) end

--- Sets the log file path (empty string disables file output).
---@param path any
function lurek.devtools.setLogFile(path) end

--- Sets the minimum log level.
---@param level any
function lurek.devtools.setLogLevel(level) end

--- Enables or disables the profiler.
---@param enabled any
function lurek.devtools.setProfilingEnabled(enabled) end

--- Sets the file watch poll interval in seconds.
---@param interval any
function lurek.devtools.setWatchInterval(interval) end

--- Takes a structured snapshot of all watches + frame stats + last profile frame.
---@return table
function lurek.devtools.snapshot() end

--- Removes a file path from the watch list.
---@param path any
---@return boolean
function lurek.devtools.unwatch(path) end

--- Adds a file path to the watch list. Returns false if already watched.
---@param path any
---@return boolean
function lurek.devtools.watch(path) end

---@class lurek.docs
lurek.docs = {}

--- Wraps a catalog snapshot of API entries for Lua access.
---@class ApiCatalog
local ApiCatalog = {}

--- Returns the number of entries, optionally scoped to a module.
---@param module? any (optional)
---@return integer
function ApiCatalog:entryCount(module) end

--- Returns a new catalog containing only entries for which predicate returns true.
---@param predicate any
---@return any
function ApiCatalog:filter(predicate) end

--- Returns all entries, optionally filtered to a single module.
---@param module? any (optional)
---@return table
function ApiCatalog:getEntries(module) end

--- Returns a single entry by qualified name, or nil.
---@param qualified_name any
---@return any
function ApiCatalog:getEntry(qualified_name) end

--- Returns a sorted list of module names present in the catalog.
---@return table
function ApiCatalog:getModules() end

--- Returns entries that are methods of the given type qualified name.
---@param qualified_name any
---@return table
function ApiCatalog:getTypeMethods(qualified_name) end

--- Returns the names of all entries with kind "type" in the given module.
---@param module_name any
---@return table
function ApiCatalog:getTypes(module_name) end

--- Returns a new catalog that is the union of this and another catalog, with other overriding duplicates.
---@param other any
---@return any
function ApiCatalog:merge(other) end

--- Returns a table of entries whose name, qualified name, or description contains query.
---@param query any
---@return table
function ApiCatalog:search(query) end

--- Serialises the catalog to a pretty-printed JSON string.
---@return string
function ApiCatalog:toJSON() end

--- Converts the catalog to a plain Lua table array.
---@return table
function ApiCatalog:toTable() end

--- Wraps a single doc entry for Lua access.
---@class DocEntry
local DocEntry = {}

--- Returns the deprecation message, or nil.
---@return string?
function DocEntry:getDeprecated() end

--- Returns the description.
---@return string
function DocEntry:getDescription() end

--- Returns the example snippet, or nil.
---@return string?
function DocEntry:getExample() end

--- Returns the kind.
---@return string
function DocEntry:getKind() end

--- Returns the module.
---@return string
function DocEntry:getModule() end

--- Returns the name.
---@return string
function DocEntry:getName() end

--- Returns the parameters as a table of `{name, type, description, optional, default?}` records.
---@return table
function DocEntry:getParameters() end

--- Returns the qualified name.
---@return string
function DocEntry:getQualifiedName() end

--- Returns the return values as a table of `{type, description}` records.
---@return table
function DocEntry:getReturns() end

--- Returns the quality score in [0,1].
---@return number
function DocEntry:getScore() end

--- Returns the since version string, or nil.
---@return string?
function DocEntry:getSince() end

--- Returns true when the entry has a non-empty description.
---@return boolean
function DocEntry:hasDescription() end

--- Returns true when the entry has an example snippet.
---@return boolean
function DocEntry:hasExample() end

--- Returns true when the entry has at least one parameter.
---@return boolean
function DocEntry:hasParameters() end

--- Returns true when the entry declares at least one return type.
---@return boolean
function DocEntry:hasReturnType() end

--- Wraps documentation quality metrics for Lua access.
---@class QualityReport
local QualityReport = {}

--- Returns up to count entries with the highest quality scores.
---@param count? any (optional)
---@return table
function QualityReport:getBest(count) end

--- Returns entries whose grade exactly matches the given letter grade.
---@param grade any
---@return table
function QualityReport:getByGrade(grade) end

--- Returns the letter grade for the overall score.
---@return string
function QualityReport:getGrade() end

--- Returns a table mapping module name to its average quality score.
---@return table
function QualityReport:getModuleScores() end

--- Returns the overall quality score in [0,1].
---@return number
function QualityReport:getOverallScore() end

--- Returns a multi-line human-readable summary of quality by module.
---@return string
function QualityReport:getSummary() end

--- Returns up to count entries with the lowest quality scores.
---@param count? any (optional)
---@return table
function QualityReport:getWorst(count) end

--- Serialises the quality report to a pretty-printed JSON string.
---@return string
function QualityReport:toJSON() end

--- Converts the quality report to a plain Lua table.
---@return table
function QualityReport:toTable() end

--- Lua wrapper for a runtime data-validation schema.
---@class Schema
local Schema = {}

--- Validates data and throws a Lua error on failure with all error messages joined.
---@param data any
function Schema:assert(data) end

--- Returns true when the data passes all schema rules.
---@param data any
---@return boolean
function Schema:check(data) end

--- Returns a table of declared field names.
---@return table
function Schema:getFields() end

--- Returns the schema name.
---@return string
function Schema:getName() end

--- Validates a Lua table against the schema.
---@param data any
---@return boolean
function Schema:validate(data) end

--- Wraps a validation report for Lua access.
---@class ValidationReport
local ValidationReport = {}

--- Returns the list of qualified names whose catalog entry is incomplete.
---@return table
function ValidationReport:getIncomplete() end

--- Returns the list of qualified names present in the live API but missing from the catalog.
---@return table
function ValidationReport:getMissing() end

--- Returns the list of qualified names in the catalog that are not present in the live API.
---@return table
function ValidationReport:getPhantom() end

--- Returns a single-line summary of the validation results.
---@return string
function ValidationReport:getSummary() end

--- Returns the count of incomplete entries.
---@return integer
function ValidationReport:incompleteCount() end

--- Returns true when the report has no missing entries.
---@return boolean
function ValidationReport:isValid() end

--- Returns the count of missing entries.
---@return integer
function ValidationReport:missingCount() end

--- Returns the count of phantom entries.
---@return integer
function ValidationReport:phantomCount() end

--- Serialises the report to a pretty-printed JSON string.
---@return string
function ValidationReport:toJSON() end

--- Converts the report to a plain Lua table.
---@return table
function ValidationReport:toTable() end

--- Compare catalog entries against source files in a directory for staleness.
---@param catalog_ud any
---@param source_dir any
---@return table
function lurek.docs.checkStaleness(catalog_ud, source_dir) end

--- Return (documented_count, total_live_count) coverage tuple.
---@param catalog_ud? any (optional)
---@return any
function lurek.docs.coverage(catalog_ud) end

--- Return (documented_count, total_live_count) for a single module.
---@param module_name any
---@param catalog_ud? any (optional)
---@return any
function lurek.docs.coverageModule(module_name, catalog_ud) end

--- Inject or update a description for a named API entry.
---@param qualified_name any
---@param description any
function lurek.docs.describe(qualified_name, description) end

--- Export completions.json, hover.json, and signatures.json to a directory.
---@param catalog_ud any
---@param output_dir any
function lurek.docs.exportAll(catalog_ud, output_dir) end

--- Export a one-line-per-function plain-text cheatsheet.
---@param catalog_ud any
---@param path any
function lurek.docs.exportCheatsheet(catalog_ud, path) end

--- Export VS Code IntelliSense completions JSON to a file.
---@param catalog_ud any
---@param path any
function lurek.docs.exportCompletions(catalog_ud, path) end

--- Export VS Code hover JSON to a file.
---@param catalog_ud any
---@param path any
function lurek.docs.exportHover(catalog_ud, path) end

--- Export a Markdown API reference file.
---@param catalog_ud any
---@param path any
function lurek.docs.exportMarkdown(catalog_ud, path) end

--- Export VS Code signature-help JSON to a file.
---@param catalog_ud any
---@param path any
function lurek.docs.exportSignatures(catalog_ud, path) end

--- Return the current internal catalog as an ApiCatalog userdata.
function lurek.docs.getCatalog() end

--- Load all .toml files in a directory and merge into a single ApiCatalog.
---@param directory any
---@return any
function lurek.docs.loadAll(directory) end

--- Load a TOML doc file into an ApiCatalog.
---@param path any
---@return any
function lurek.docs.loadToml(path) end

--- Calculate quality metrics for a catalog or the internal catalog.
---@param catalog_ud? any (optional)
---@return any
function lurek.docs.quality(catalog_ud) end

--- Calculate quality metrics for a single module.
---@param module_name any
---@param catalog_ud? any (optional)
---@return any
function lurek.docs.qualityModule(module_name, catalog_ud) end

--- Walks the live lurek.* Lua table and returns a structured reflection of all
---@param ns? any (optional)
---@return table
function lurek.docs.reflectLive(ns) end

--- Reflects any Lua table, returning a structure describing its keys,
---@param tbl any
---@param name? any (optional)
---@return table
function lurek.docs.reflectTable(tbl, name) end

--- Clear all entries from the internal catalog.
function lurek.docs.resetCatalog() end

--- Scan the lurek.* namespace to build an API catalog from live bindings.
---@param opts? any (optional)
---@return any
function lurek.docs.scan(opts) end

--- Scan a single module's bindings.
---@param module_name any
---@return any
function lurek.docs.scanModule(module_name) end

--- Creates a Schema validator from a rules table.
---@param rules any
---@param name? any (optional)
---@return userdata
function lurek.docs.schema(rules, name) end

--- Set the parameter metadata for a catalog entry.
---@param qualified_name any
---@param params any
function lurek.docs.setParamInfo(qualified_name, params) end

--- Set the return type metadata for a catalog entry.
---@param qualified_name any
---@param returns any
function lurek.docs.setReturnInfo(qualified_name, returns) end

--- Validate catalog completeness against the live lurek.* bindings.
---@param catalog_ud? any (optional)
---@return any
function lurek.docs.validate(catalog_ud) end

--- Validate a single module against the live lurek.<module>.* bindings.
---@param module_name any
---@param catalog_ud? any (optional)
---@return any
function lurek.docs.validateModule(module_name, catalog_ud) end

---@class lurek.effect
lurek.effect = {}

--- Lua-side wrapper around [`ImageEffect`].
---@class ImageEffect
local ImageEffect = {}

--- Creates a new effect by type name, appends it, and returns the shared PostFxEffect.
---@param name any
---@return PostFxEffect
function ImageEffect:addEffect(name) end

--- Removes all effects from the chain (alias for clearEffects).
---@return nil
function ImageEffect:clear() end

--- Removes all effects from the chain.
---@return nil
function ImageEffect:clearEffects() end

--- Returns a deep copy of this ImageEffect chain.
---@return ImageEffect
function ImageEffect:clone() end

--- Returns the number of effects in the chain.
---@return integer
function ImageEffect:effectCount() end

--- Returns the effect at the given 1-based index or with the given type name.
---@param key any
---@return PostFxEffect|nil
function ImageEffect:getEffect(key) end

--- Returns the number of effects in the chain (alias for effectCount).
---@return integer
function ImageEffect:getEffectCount() end

--- Removes the effect at the given 0-based index from the chain.
---@param idx any
---@return boolean
function ImageEffect:removeByIndex(idx) end

--- Removes the first effect matching the given type name.
---@param name any
---@return boolean
function ImageEffect:removeByName(name) end

--- Removes the effect at the given 1-based index or with the given type name.
---@param key any
---@return boolean
function ImageEffect:removeEffect(key) end

--- Stub: no-op serialisation placeholder.
---@return boolean
function ImageEffect:save() end

--- Returns the type name "ImageEffect".
---@return string
function ImageEffect:type() end

--- Returns true when the given name matches "ImageEffect" or a parent type.
---@param name any
---@return boolean
function ImageEffect:typeOf(name) end

--- Lua-side wrapper around [`Overlay`].
---@class Overlay
local Overlay = {}

--- Resets all overlay subsystems to their default inactive state.
---@return nil
function Overlay:clear() end

--- Returns the current ambient tint as r, g, b, a components.
---@return number
function Overlay:getAmbientColor() end

--- Returns the current cloud shadow instance count.
---@return integer
function Overlay:getCloudCount() end

--- Returns the current cloud shadow opacity.
---@return number
function Overlay:getCloudOpacity() end

--- Returns the current cloud shadow scale.
---@return number
function Overlay:getCloudScale() end

--- Returns the current cloud shadow scroll speed.
---@return number
function Overlay:getCloudSpeed() end

--- Returns the overlay width and height.
---@return integer
function Overlay:getDimensions() end

--- Returns the current film-grain intensity.
---@return number
function Overlay:getFilmGrainIntensity() end

--- Returns the current flash overlay alpha value.
---@return number
function Overlay:getFlashAlpha() end

--- Returns the current fog tint as r, g, b, a components.
---@return number
function Overlay:getFogColor() end

--- Returns the current fog density.
---@return number
function Overlay:getFogDensity() end

--- Returns the current heat-haze distortion intensity.
---@return number
function Overlay:getHeatHazeIntensity() end

--- Returns the overlay height.
---@return integer
function Overlay:getHeight() end

--- Returns the current lightning overlay alpha value.
---@return number
function Overlay:getLightningAlpha() end

--- Returns the lightning flash tint as r, g, b, a components.
---@return number
function Overlay:getLightningColor() end

--- Returns the current shake displacement as x, y.
---@return number
function Overlay:getShakeOffset() end

--- Returns the current simulated time-of-day (0–24).
---@return number
function Overlay:getTimeOfDay() end

--- Returns the current vignette strength.
---@return number
function Overlay:getVignetteStrength() end

--- Returns the name of the current weather type.
---@return string
function Overlay:getWeather() end

--- Returns the current weather intensity.
---@return number
function Overlay:getWeatherIntensity() end

--- Returns the overlay width.
---@return integer
function Overlay:getWidth() end

--- Returns the current wind direction in radians.
---@return number
function Overlay:getWindDirection() end

--- Returns the current wind speed.
---@return number
function Overlay:getWindSpeed() end

--- Returns true if any overlay subsystem is currently active.
---@return boolean
function Overlay:isActive() end

--- Returns whether the ambient light layer is active.
---@return boolean
function Overlay:isAmbientEnabled() end

--- Returns whether cloud shadows are active.
---@return boolean
function Overlay:isCloudShadowsEnabled() end

--- Returns true while a fade effect is in progress.
---@return boolean
function Overlay:isFading() end

--- Returns whether the film-grain layer is active.
---@return boolean
function Overlay:isFilmGrainEnabled() end

--- Returns true while a flash effect is in progress.
---@return boolean
function Overlay:isFlashing() end

--- Returns whether the fog layer is active.
---@return boolean
function Overlay:isFogEnabled() end

--- Returns whether the heat-haze layer is active.
---@return boolean
function Overlay:isHeatHazeEnabled() end

--- Returns true while a shake effect is in progress.
---@return boolean
function Overlay:isShaking() end

--- Returns whether the vignette layer is active.
---@return boolean
function Overlay:isVignetteEnabled() end

--- Returns whether the weather particle system is active.
---@return boolean
function Overlay:isWeatherEnabled() end

--- No-op placeholder; the overlay is rendered by the engine's render pass.
---@return nil
function Overlay:render() end

--- Resizes the overlay to match new window dimensions.
---@param w any
---@param h any
---@return nil
function Overlay:resize(w, h) end

--- Enables or disables the ambient light layer.
---@param v any
---@return nil
function Overlay:setAmbientEnabled(v) end

--- Sets the number of cloud shadow instances to render.
---@param v any
---@return nil
function Overlay:setCloudCount(v) end

--- Sets the opacity of cloud shadows (0.0 = invisible, 1.0 = fully dark).
---@param v any
---@return nil
function Overlay:setCloudOpacity(v) end

--- Sets the scale multiplier applied to each cloud shadow.
---@param v any
---@return nil
function Overlay:setCloudScale(v) end

--- Enables or disables scrolling cloud-shadow projection.
---@param v any
---@return nil
function Overlay:setCloudShadows(v) end

--- Sets the horizontal scroll speed of cloud shadows in pixels per second.
---@param v any
---@return nil
function Overlay:setCloudSpeed(v) end

--- Enables or disables the film-grain noise layer.
---@param v any
---@return nil
function Overlay:setFilmGrainEnabled(v) end

--- Sets the film-grain noise intensity (0.0–1.0).
---@param v any
---@return nil
function Overlay:setFilmGrainIntensity(v) end

--- Sets the fog density (0.0 = clear, 1.0 = fully opaque).
---@param v any
---@return nil
function Overlay:setFogDensity(v) end

--- Enables or disables the fog layer.
---@param v any
---@return nil
function Overlay:setFogEnabled(v) end

--- Enables or disables the heat-haze distortion layer.
---@param v any
---@return nil
function Overlay:setHeatHazeEnabled(v) end

--- Sets the heat-haze distortion intensity (0.0–1.0).
---@param v any
---@return nil
function Overlay:setHeatHazeIntensity(v) end

--- Sets the simulated time-of-day (0–24) which drives ambient colour.
---@param v any
---@return nil
function Overlay:setTimeOfDay(v) end

--- Enables or disables the screen-edge vignette layer.
---@param v any
---@return nil
function Overlay:setVignetteEnabled(v) end

--- Sets the vignette darkening strength (0.0–1.0).
---@param v any
---@return nil
function Overlay:setVignetteStrength(v) end

--- Sets the active weather type by name ("none", "rain", "snow", "hail", "dust", "leaves", "ash", "pollen").
---@param name any
---@return nil
function Overlay:setWeather(name) end

--- Enables or disables the weather particle system.
---@param v any
---@return nil
function Overlay:setWeatherEnabled(v) end

--- Sets the particle spawn rate multiplier (0.0–1.0).
---@param v any
---@return nil
function Overlay:setWeatherIntensity(v) end

--- Sets the wind direction in radians (0 = right, π/2 = down).
---@param v any
---@return nil
function Overlay:setWindDirection(v) end

--- Sets the wind speed applied to weather particles in units per second.
---@param v any
---@return nil
function Overlay:setWindSpeed(v) end

--- Triggers a camera shake; duration defaults to 0.5 s.
---@param intensity any
---@param dur? any (optional)
---@return nil
function Overlay:shake(intensity, dur) end

--- Triggers a lightning flash effect.
---@return nil
function Overlay:triggerLightning() end

--- Returns the type name of this object ("Overlay").
---@return string
function Overlay:type() end

--- Returns true if this object is of the given type ("Object" or "Overlay").
---@param name any
---@return boolean
function Overlay:typeOf(name) end

--- Advances all overlay subsystems by the given delta time.
---@param dt any
---@return nil
function Overlay:update(dt) end

--- Lua-side wrapper around [`PostFxEffect`].
---@class PostFxEffect
local PostFxEffect = {}

--- Returns the type name of this effect (alias for getTypeName).
---@return string
function PostFxEffect:getEffectType() end

--- Returns a list of all parameter names on this effect.
---@return table
function PostFxEffect:getParameterNames() end

--- Returns the type name of this effect (alias for getTypeName).
---@return string
function PostFxEffect:getType() end

--- Returns the display name of this effect type.
---@return string
function PostFxEffect:getTypeName() end

--- Returns true if the named parameter exists on this effect.
---@param name any
---@return boolean
function PostFxEffect:hasParameter(name) end

--- Returns true if this is a built-in effect, false if custom.
---@return boolean
function PostFxEffect:isBuiltIn() end

--- Returns whether this effect is currently active.
---@return boolean
function PostFxEffect:isEnabled() end

--- Sets the brightness parameter of this effect.
---@param v any
---@return nil
function PostFxEffect:setBrightness(v) end

--- Sets the contrast parameter of this effect.
---@param v any
---@return nil
function PostFxEffect:setContrast(v) end

--- Enables or disables this effect.
---@param enabled any
---@return nil
function PostFxEffect:setEnabled(enabled) end

--- Sets the intensity parameter of this effect.
---@param v any
---@return nil
function PostFxEffect:setIntensity(v) end

--- Sets the offset parameter of this effect.
---@param v any
---@return nil
function PostFxEffect:setOffset(v) end

--- Sets a named float parameter on this effect.
---@param name any
---@param value any
---@return nil
function PostFxEffect:setParameter(name, value) end

--- Sets the radius parameter of this effect.
---@param v any
---@return nil
function PostFxEffect:setRadius(v) end

--- Sets the saturation parameter of this effect.
---@param v any
---@return nil
function PostFxEffect:setSaturation(v) end

--- Sets the scanline strength parameter of this effect.
---@param v any
---@return nil
function PostFxEffect:setScanlineStrength(v) end

--- Sets the strength parameter of this effect.
---@param v any
---@return nil
function PostFxEffect:setStrength(v) end

--- Sets the threshold parameter of this effect.
---@param v any
---@return nil
function PostFxEffect:setThreshold(v) end

--- Returns the type name "PostFxEffect".
---@return string
function PostFxEffect:type() end

--- Returns true when the given name matches "PostFxEffect" or a parent type.
---@param name any
---@return boolean
function PostFxEffect:typeOf(name) end

--- Lua-side wrapper around [`PostFxStack`].
---@class PostFxStack
local PostFxStack = {}

--- Appends a PostFxEffect to the end of the pipeline.
---@param effect_ud any
---@return nil
function PostFxStack:add(effect_ud) end

--- Removes all effects from the pipeline.
---@return nil
function PostFxStack:clear() end

--- Returns width and height of the render target.
---@return integer
function PostFxStack:getDimensions() end

--- Returns the effect at the given 1-based position, or nil.
---@param index any
---@return PostFxEffect?
function PostFxStack:getEffect(index) end

--- Returns the number of effects in the pipeline.
---@return integer
function PostFxStack:getEffectCount() end

--- Returns a list of currently enabled effect objects.
---@return table
function PostFxStack:getEnabledEffects() end

--- Returns the height of the render target.
---@return integer
function PostFxStack:getHeight() end

--- Returns the width of the render target.
---@return integer
function PostFxStack:getWidth() end

--- Returns whether the stack is currently capturing the scene.
---@return boolean
function PostFxStack:isCapturing() end

--- Returns true if the pipeline has no effect slots.
---@return boolean
function PostFxStack:isEmpty() end

--- Returns whether the effect at the given 1-based position is enabled.
---@param position any
---@return boolean
function PostFxStack:isEnabled(position) end

--- Returns the total number of effect slots in the pipeline.
---@return integer
function PostFxStack:len() end

--- Removes the given PostFxEffect from the pipeline.
---@param effect_ud any
---@return boolean
function PostFxStack:remove(effect_ud) end

--- Resizes the render target to the given dimensions.
---@param w any
---@param h any
---@return nil
function PostFxStack:resize(w, h) end

--- Returns the type name "PostFxStack".
---@return string
function PostFxStack:type() end

--- Returns true when the given name matches "PostFxStack" or a parent type.
---@param name any
---@return boolean
function PostFxStack:typeOf(name) end

--- Returns the list of all built-in effect type names.
---@return table
function lurek.effect.getEffectTypes() end

--- Creates a custom shader post-processing effect.
---@param shader_id any
---@return PostFxEffect
function lurek.effect.newCustomEffect(shader_id) end

--- Creates a new built-in post-processing effect by type name.
---@param type_name any
---@return PostFxEffect
function lurek.effect.newEffect(type_name) end

--- Creates a new per-image effect chain. Accepts:
---@param args any
---@return ImageEffect
function lurek.effect.newImageEffect(args) end

--- Creates a new screen overlay controller for weather, flash, shake, and fade effects.
---@param w? any (optional)
---@param h? any (optional)
---@return Overlay
function lurek.effect.newOverlay(w, h) end

--- Creates a custom-shader post-processing effect (alias for newCustomEffect).
---@param shader_id any
---@return PostFxEffect
function lurek.effect.newPass(shader_id) end

--- Creates a new post-processing pipeline stack.
---@param w? any (optional)
---@param h? any (optional)
---@return PostFxStack
function lurek.effect.newStack(w, h) end

---@class lurek.entity
lurek.entity = {}

--- Lua-side wrapper around a [`Universe`] ECS world.
---@class Universe
local Universe = {}

--- Adds a system table to the universe.
---@param system any
---@return nil
function Universe:addSystem(system) end

--- Attaches a string tag to an entity.
---@param id any
---@param tag any
---@return nil
function Universe:addTag(id, tag) end

--- Adds a bitmap tag to an entity.
---@param id any
---@param name any
---@return nil
function Universe:bitmapTag(id, name) end

--- Removes a bitmap tag from an entity.
---@param id any
---@param name any
---@return nil
function Universe:bitmapUntag(id, name) end

--- Removes all entities, components, tags, layers, and systems. Blueprints are preserved.
---@return nil
function Universe:clear() end

--- Defines a bitmap tag name, returning its bit index.
---@param name any
---@return integer
function Universe:defineTag(name) end

--- Calls callback(id, value) for every entity with the named component.
---@param name any
---@param callback any
---@return nil
function Universe:each(name, callback) end

--- Emits a named event to all systems that implement the handler.
---@param args any
---@return nil
function Universe:emit(args) end

--- Returns the component value for an entity, or nil if missing.
---@param id any
---@param name any
---@return table
function Universe:get(id, name) end

--- Returns the bit index for a bitmap tag name, or nil if undefined.
---@param name any
---@return integer?
function Universe:getBitmapTagBit(name) end

--- Returns a deep copy of a blueprint's component table, or nil.
---@param name any
---@return table
function Universe:getBlueprintComponents(name) end

--- Returns all direct child entity IDs.
---@param parent_id any
---@return table
function Universe:getChildren(parent_id) end

--- Returns all component names for an entity.
---@param id any
---@return table
function Universe:getComponents(id) end

--- Returns all alive entity IDs.
---@return table
function Universe:getEntities() end

--- Returns all alive entities on a specific layer.
---@param layer any
---@return table
function Universe:getEntitiesByLayer(layer) end

--- Returns all alive entities with the given string tag.
---@param tag any
---@return table
function Universe:getEntitiesByTag(tag) end

--- Returns all alive entities sorted by layer then ID.
---@return table
function Universe:getEntitiesSorted() end

--- Returns the number of alive entities.
---@return integer
function Universe:getEntityCount() end

--- Returns the layer for an entity, defaulting to zero.
---@param id any
---@return integer
function Universe:getLayer(id) end

--- Returns the parent entity ID, or nil if unparented.
---@param child_id any
---@return integer?
function Universe:getParent(child_id) end

--- Returns the number of registered systems.
---@return integer
function Universe:getSystemCount() end

--- Returns all string tags for an entity.
---@param id any
---@return table
function Universe:getTags(id) end

--- Returns true if the entity has the named component.
---@param id any
---@param name any
---@return boolean
function Universe:has(id, name) end

--- Returns true if the entity has the given bitmap tag.
---@param id any
---@param name any
---@return boolean
function Universe:hasBitmapTag(id, name) end

--- Returns true if a blueprint with the given name exists.
---@param name any
---@return boolean
function Universe:hasBlueprint(name) end

--- Returns true if the entity carries the given tag.
---@param id any
---@param tag any
---@return boolean
function Universe:hasTag(id, tag) end

--- Returns true if the entity ID is currently alive.
---@param id any
---@return boolean
function Universe:isAlive(id) end

--- Destroys the entity with the given ID, freeing its slot for reuse.
---@param id any
---@return nil
function Universe:kill(id) end

--- Kills an entity and all its descendants recursively.
---@param id any
---@return nil
function Universe:killRecursive(id) end

--- Returns all defined blueprint names.
---@return table
function Universe:listBlueprints() end

--- Returns entity IDs that have all listed component names.
---@param args any
---@return table
function Universe:query(args) end

--- Returns all alive entities with all of the listed bitmap tags.
---@param names any
---@return table
function Universe:queryBitmapAll(names) end

--- Returns all alive entities with any of the listed bitmap tags.
---@param names any
---@return table
function Universe:queryBitmapAny(names) end

--- Returns all alive entities with the given bitmap tag.
---@param name any
---@return table
function Universe:queryBitmapTag(name) end

--- Releases all universe state, equivalent to clear.
---@return nil
function Universe:release() end

--- Removes a component from an entity.
---@param id any
---@param name any
---@return nil
function Universe:remove(id, name) end

--- Removes a blueprint definition.
---@param name any
---@return nil
function Universe:removeBlueprint(name) end

--- Removes a system table from the universe.
---@param system any
---@return nil
function Universe:removeSystem(system) end

--- Removes a string tag from an entity.
---@param id any
---@param tag any
---@return nil
function Universe:removeTag(id, tag) end

--- Calls render(system, world) on each registered system.
---@return nil
function Universe:render() end

--- Sets a component value on an entity.
---@param id any
---@param name any
---@param value any
---@return nil
function Universe:set(id, name, value) end

--- Sets the layer for an entity.
---@param id any
---@param layer any
---@return nil
function Universe:setLayer(id, layer) end

--- Creates a new entity and returns its packed ID.
---@return integer
function Universe:spawn() end

--- Calls update(system, world, dt) on each registered system.
---@param dt any
---@return nil
function Universe:update(dt) end

--- Creates a new empty ECS universe.
---@return Universe
function lurek.entity.newUniverse() end

---@class lurek.filesystem
lurek.filesystem = {}

--- Lua-side wrapper around a [`FileData`] buffer.
---@class FileData
local FileData = {}

--- Returns the virtual path this data was loaded from.
---@return string
function FileData:getFilename() end

--- Returns the file size in bytes.
---@return integer
function FileData:getSize() end

--- Returns the file content as a Lua string.
---@return string
function FileData:getString() end

--- Lua-side wrapper around a [`FileHandle`] with interior mutability.
---@class FileHandle
local FileHandle = {}

--- Flushes any pending writes and closes the file handle.
---@return nil
function FileHandle:close() end

--- Flushes all buffered writes to disk without closing the handle.
---@return nil
function FileHandle:flush() end

--- Returns the access mode the file was opened with.
---@return string
function FileHandle:getMode() end

--- Returns the size of the open file in bytes.
---@return integer
function FileHandle:getSize() end

--- Returns whether the read cursor has reached the end of the file.
---@return boolean
function FileHandle:isEOF() end

--- Reads bytes from the file, returning them as a string.
---@param count? any (optional)
---@return string
function FileHandle:read(count) end

--- Reads the next line from the file without the trailing newline.
---@return string?
function FileHandle:readLine() end

--- Seeks the file position to the given byte offset from the start.
---@param pos any
---@return integer
function FileHandle:seek(pos) end

--- Returns the current read/write byte offset from the start of the file.
---@return integer
function FileHandle:tell() end

--- Writes a string to the file and returns the number of bytes written.
---@param data any
---@return integer
function FileHandle:write(data) end

--- Opens the file in append mode and writes the given string at the end.
---@param path any
---@param data any
---@return nil
function lurek.filesystem.append(path, data) end

--- Creates a directory and any missing parent directories in the save area.
---@param path any
---@return nil
function lurek.filesystem.createDirectory(path) end

--- Returns whether the given file or directory exists.
---@param path any
---@return boolean
function lurek.filesystem.exists(path) end

--- Returns a table containing the names of every file and subdirectory in the given path.
---@param path any
---@return table
function lurek.filesystem.getDirectoryItems(path) end

--- Returns the identity string used to locate the game's save directory.
---@return string
function lurek.filesystem.getIdentity() end

--- Returns a table of metadata for a path, or nil if the path does not exist.
---@param path any
---@return table?
function lurek.filesystem.getInfo(path) end

--- Returns the sandboxed save data directory path.
---@return string
function lurek.filesystem.getSaveDirectory() end

--- Returns the absolute path of the directory the game was loaded from.
---@return string
function lurek.filesystem.getSource() end

--- Returns the current user's home directory path.
---@return string
function lurek.filesystem.getUserDirectory() end

--- Returns the current working directory path.
---@return string
function lurek.filesystem.getWorkingDirectory() end

--- Returns whether the given path is a directory.
---@param path any
---@return boolean
function lurek.filesystem.isDirectory(path) end

--- Returns whether the given path is a regular file.
---@param path any
---@return boolean
function lurek.filesystem.isFile(path) end

--- Returns an iterator function over the lines of a text file.
---@param path any
---@return function
function lurek.filesystem.lines(path) end

--- Loads and compiles a Lua file from the VFS, returning it as a callable function.
---@param path any
---@return function
function lurek.filesystem.load(path) end

--- Mounts a directory at a virtual path inside the game filesystem.
---@param src any
---@param mp any
---@return boolean
function lurek.filesystem.mount(src, mp) end

--- Loads a file from the VFS into a FileData buffer.
---@param path any
---@return FileData
function lurek.filesystem.newFileData(path) end

--- Opens a file and returns a readable/writable file handle.
---@param path any
---@param mode any
---@return FileHandle
function lurek.filesystem.openFile(path, mode) end

--- Polls an async load handle, returning status and optional data.
---@param handle_id any
---@return string
function lurek.filesystem.pollAsync(handle_id) end

--- Reads a text file and returns its contents as a string.
---@param path any
---@return string
function lurek.filesystem.read(path) end

--- Starts loading a file in the background and returns an opaque handle.
---@param path any
---@return integer
function lurek.filesystem.readAsync(path) end

--- Permanently deletes a file or empty directory from the save directory.
---@param path any
---@return nil
function lurek.filesystem.remove(path) end

--- Sets the identity string that names the game's sandboxed save-data directory.
---@param name any
---@return nil
function lurek.filesystem.setIdentity(name) end

--- Removes a virtual mount layer by mountpoint.
---@param mp any
---@return boolean
function lurek.filesystem.unmount(mp) end

--- Writes a string to a file in the save directory.
---@param path any
---@param data any
---@return nil
function lurek.filesystem.write(path, data) end

---@class lurek.graph
lurek.graph = {}

--- Lua handle for an edge inside a `Graph`.
---@class Edge
local Edge = {}

--- Adds an item type to the edge allow-list.
---@param t any
---@return nil
function Edge:addAllowedType(t) end

--- Clears the edge allow-list so all item types are permitted.
---@return nil
function Edge:clearAllowedTypes() end

--- Returns the edge capacity (-1 = unlimited).
---@return integer
function Edge:getCapacity() end

--- Returns the cooldown duration in seconds.
---@return number
function Edge:getCooldown() end

--- Returns the source node handle.
---@return Node
function Edge:getFrom() end

--- Returns a table of GraphItem handles currently in transit on this edge.
---@return table
function Edge:getItemsInTransit() end

--- Returns the speed modifier applied to items in transit.
---@return number
function Edge:getSpeedModifier() end

--- Returns items per second this edge can transfer.
---@return number
function Edge:getThroughput() end

--- Returns the destination node handle.
---@return Node
function Edge:getTo() end

--- Returns the travel time in seconds for items on this edge.
---@return number
function Edge:getTravelTime() end

--- Returns the edge type string.
---@return string
function Edge:getType() end

--- Returns the pathfinding weight of this edge.
---@return number
function Edge:getWeight() end

--- Returns true if the edge is active.
---@return boolean
function Edge:isActive() end

--- Returns true if items can travel the edge in either direction.
---@return boolean
function Edge:isBidirectional() end

--- Returns true if the given item type is allowed on this edge.
---@param t any
---@return boolean
function Edge:isItemTypeAllowed(t) end

--- Returns true if the edge is currently on cooldown.
---@return boolean
function Edge:isOnCooldown() end

--- Removes an item type from the edge allow-list.
---@param t any
---@return boolean
function Edge:removeAllowedType(t) end

--- Sets the active state of this edge.
---@param a any
---@return nil
function Edge:setActive(a) end

--- Sets whether items can travel the edge in either direction.
---@param b any
---@return nil
function Edge:setBidirectional(b) end

--- Sets the edge capacity (-1 = unlimited).
---@param c any
---@return nil
function Edge:setCapacity(c) end

--- Sets the cooldown duration in seconds.
---@param c any
---@return nil
function Edge:setCooldown(c) end

--- Sets the speed modifier applied to items in transit.
---@param m any
---@return nil
function Edge:setSpeedModifier(m) end

--- Sets items per second this edge can transfer.
---@param t any
---@return nil
function Edge:setThroughput(t) end

--- Sets the travel time in seconds for items on this edge.
---@param t any
---@return nil
function Edge:setTravelTime(t) end

--- Sets the edge type string.
---@param t any
---@return nil
function Edge:setType(t) end

--- Sets the pathfinding weight of this edge.
---@param w any
---@return nil
function Edge:setWeight(w) end

--- Returns the type name "GraphEdge".
---@return string
function Edge:type() end

--- Returns true when the given name matches "GraphEdge" or a parent type.
---@param name any
---@return boolean
function Edge:typeOf(name) end

--- Lua wrapper around a directed `Graph` with event callback registry.
---@class Graph
local Graph = {}

--- Returns weakly connected components as a table of tables of Node handles.
---@return table
function Graph:getComponents() end

--- Returns the number of edges in the graph.
---@return integer
function Graph:getEdgeCount() end

--- Returns a table of all Edge handles.
---@return table
function Graph:getEdges() end

--- Returns the number of items in the graph.
---@return integer
function Graph:getItemCount() end

--- Returns a table of all GraphItem handles.
---@return table
function Graph:getItems() end

--- Returns a table of direct neighbor Node handles.
---@param node_ud any
---@return table
function Graph:getNeighbors(node_ud) end

--- Returns the number of nodes in the graph.
---@return integer
function Graph:getNodeCount() end

--- Returns a table of all Node handles.
---@return table
function Graph:getNodes() end

--- Returns a statistics snapshot table.
---@return table
function Graph:getStats() end

--- Returns true if the graph contains a directed cycle.
---@return boolean
function Graph:hasCycle() end

--- Returns true if the edge exists in the graph.
---@param edge_ud any
---@return boolean
function Graph:hasEdge(edge_ud) end

--- Returns true if the item exists in the graph.
---@param item_ud any
---@return boolean
function Graph:hasItem(item_ud) end

--- Returns true if the node exists in the graph.
---@param node_ud any
---@return boolean
function Graph:hasNode(node_ud) end

--- Processes all supply/demand declarations and fires event callbacks.
---@return nil
function Graph:processDemand() end

--- Removes an edge from the graph.
---@param edge_ud any
---@return boolean
function Graph:removeEdge(edge_ud) end

--- Removes an item from the graph entirely.
---@param item_ud any
---@return boolean
function Graph:removeItem(item_ud) end

--- Removes a node from the graph.
---@param node_ud any
---@return boolean
function Graph:removeNode(node_ud) end

--- Runs one discrete simulation step and fires event callbacks.
---@return nil
function Graph:step() end

--- Returns a topologically sorted table of Node handles, or nil if a cycle exists.
---@return table?
function Graph:topologicalSort() end

--- Returns the type name of this object.
---@return string
function Graph:type() end

--- Returns true if this object is of the given type.
---@param name any
---@return boolean
function Graph:typeOf(name) end

--- Advances simulation by dt seconds and fires event callbacks.
---@param dt any
---@return nil
function Graph:update(dt) end

--- Lua handle for an item inside a `Graph`.
---@class GraphItem
local GraphItem = {}

--- Returns the decay time in seconds (-1 = immortal).
---@return number
function GraphItem:getDecayTime() end

--- Returns the item position: node userdata if at a node, (edge, progress)
---@return Node|Edge|nil
function GraphItem:getPosition() end

--- Returns the item priority.
---@return integer
function GraphItem:getPriority() end

--- Returns the remaining life in seconds.
---@return number
function GraphItem:getRemainingLife() end

--- Returns the item type string.
---@return string
function GraphItem:getType() end

--- Returns true if the item is alive.
---@return boolean
function GraphItem:isAlive() end

--- Marks the item as dead.
---@return nil
function GraphItem:kill() end

--- Sets the decay time in seconds (-1 = immortal).
---@param t any
---@return nil
function GraphItem:setDecayTime(t) end

--- Sets the item priority.
---@param p any
---@return nil
function GraphItem:setPriority(p) end

--- Sets the item type string.
---@param t any
---@return nil
function GraphItem:setType(t) end

--- Returns the type name of this object.
---@return string
function GraphItem:type() end

--- Returns true if this object is of the given type.
---@param name any
---@return boolean
function GraphItem:typeOf(name) end

--- Lua handle for a node inside a `Graph`.
---@class Node
local Node = {}

--- Adds a tag to this node.
---@param tag any
---@return nil
function Node:addTag(tag) end

--- Removes all conversion rules from this node.
---@return nil
function Node:clearAllConversions() end

--- Removes the conversion rule for the given input type.
---@param in_type any
---@return nil
function Node:clearConversion(in_type) end

--- Removes all demand declarations from this node.
---@return nil
function Node:clearDemands() end

--- Removes all supply declarations from this node.
---@return nil
function Node:clearSupplies() end

--- Removes all tags from this node.
---@return nil
function Node:clearTags() end

--- Pops the next item from the node queue, or nil if empty.
---@return GraphItem?
function Node:dequeue() end

--- Pushes an item into the node queue.
---@param item_ud any
---@return boolean
function Node:enqueue(item_ud) end

--- Returns the node capacity (-1 = unlimited).
---@return integer
function Node:getCapacity() end

--- Returns a table of Edge handles connected to this node.
---@param dir? any (optional)
---@return table
function Node:getEdges(dir) end

--- Returns the flow mode as a string.
---@return string
function Node:getFlowMode() end

--- Returns the number of items currently at this node.
---@return integer
function Node:getItemCount() end

--- Returns a table of GraphItem handles at this node.
---@return table
function Node:getItems() end

--- Returns the overflow policy as a string.
---@return string
function Node:getOverflowPolicy() end

--- Returns the processing time in seconds.
---@return number
function Node:getProcessTime() end

--- Returns the pull filter string, or nil if unset.
---@return string?
function Node:getPullFilter() end

--- Returns items per second this node pulls.
---@return number
function Node:getPullRate() end

--- Returns the push filter string, or nil if unset.
---@return string?
function Node:getPushFilter() end

--- Returns items per second this node pushes.
---@return number
function Node:getPushRate() end

--- Returns the queue capacity (-1 = unlimited).
---@return integer
function Node:getQueueCapacity() end

--- Returns the number of items currently in the queue.
---@return integer
function Node:getQueueSize() end

--- Returns a table of tag strings on this node.
---@return table
function Node:getTags() end

--- Returns the node type string.
---@return string
function Node:getType() end

--- Returns true if this node has the given tag.
---@param tag any
---@return boolean
function Node:hasTag(tag) end

--- Returns true if the node is active.
---@return boolean
function Node:isActive() end

--- Returns true if the node has reached its capacity.
---@return boolean
function Node:isFull() end

--- Returns true if the node queue is enabled.
---@return boolean
function Node:isQueueEnabled() end

--- Removes the demand declaration for the given item type.
---@param item_type any
---@return boolean
function Node:removeDemand(item_type) end

--- Removes the supply declaration for the given item type.
---@param item_type any
---@return boolean
function Node:removeSupply(item_type) end

--- Removes a tag from this node.
---@param tag any
---@return boolean
function Node:removeTag(tag) end

--- Sets the active state of this node.
---@param a any
---@return nil
function Node:setActive(a) end

--- Sets the node capacity (-1 = unlimited).
---@param c any
---@return nil
function Node:setCapacity(c) end

--- Sets the flow mode from a string.
---@param m any
---@return nil
function Node:setFlowMode(m) end

--- Sets the overflow policy from a string.
---@param p any
---@return nil
function Node:setOverflowPolicy(p) end

--- Sets the processing time in seconds.
---@param t any
---@return nil
function Node:setProcessTime(t) end

--- Sets the pull filter string, or nil to clear.
---@param f? any (optional)
---@return nil
function Node:setPullFilter(f) end

--- Sets items per second this node pulls.
---@param r any
---@return nil
function Node:setPullRate(r) end

--- Sets the push filter string, or nil to clear.
---@param f? any (optional)
---@return nil
function Node:setPushFilter(f) end

--- Sets items per second this node pushes.
---@param r any
---@return nil
function Node:setPushRate(r) end

--- Sets the queue capacity (-1 = unlimited).
---@param c any
---@return nil
function Node:setQueueCapacity(c) end

--- Enables or disables the node queue.
---@param e any
---@return nil
function Node:setQueueEnabled(e) end

--- Sets the node type string.
---@param t any
---@return nil
function Node:setType(t) end

--- Returns the type name "GraphNode".
---@return string
function Node:type() end

--- Returns true when the given name matches "GraphNode" or a parent type.
---@param name any
---@return boolean
function Node:typeOf(name) end

--- Creates a new empty directed graph for item flow simulation.
---@return Graph
function lurek.graph.newGraph() end

---@class lurek.graphic
lurek.graphic = {}

--- Lua-side handle to an off-screen render target stored in SharedState.
---@class Canvas
local Canvas = {}

--- Returns width and height of this canvas.
---@return integer
function Canvas:getDimensions() end

--- Returns the height of this canvas in pixels.
---@return integer
function Canvas:getHeight() end

--- Returns the width of this canvas in pixels.
---@return integer
function Canvas:getWidth() end

--- Releases GPU framebuffer memory for this canvas.
---@return boolean
function Canvas:release() end

--- Returns the type name of this object.
---@return string
function Canvas:type() end

--- Returns the type name of this object.
---@return string
function Canvas:typeOf() end

--- Lua-side z-ordered draw queue. Callbacks are sorted by z and called on `flush()`.
---@class DrawLayer
local DrawLayer = {}

--- Removes all queued callbacks without calling them.
---@return void
function DrawLayer:clear() end

--- Sorts and calls all queued callbacks, then empties the queue.
function DrawLayer:flush() end

--- Returns the number of queued callbacks.
---@return number
function DrawLayer:getCount() end

--- Queues a draw callback at the given z-order.
---@param z any
---@param f any
function DrawLayer:queue(z, f) end

--- Returns the type name.
---@return string
function DrawLayer:type() end

--- Returns true if this object is an instance of the given type name.
---@param name any
---@return boolean
function DrawLayer:typeOf(name) end

--- Lua-side handle to a loaded font stored in SharedState.
---@class Font
local Font = {}

--- Returns the ascent of this font in pixels.
---@return number
function Font:getAscent() end

--- Returns the descent of this font in pixels.
---@return number
function Font:getDescent() end

--- Returns the line height of this font.
---@return number
function Font:getHeight() end

--- Returns the line height multiplier of this font.
---@return number
function Font:getLineHeight() end

--- Returns the rendered width of the given text string.
---@param text any
---@return number
function Font:getWidth(text) end

--- Wraps text to the given width and returns the lines.
---@param text any
---@param limit any
---@return table
function Font:getWrap(text, limit) end

--- Releases this font and frees its atlas memory.
---@return boolean
function Font:release() end

--- Sets the line height multiplier for this font.
---@param height any
---@return nil
function Font:setLineHeight(height) end

--- Returns the type name of this object.
---@return string
function Font:type() end

--- Returns the type name of this object.
---@return string
function Font:typeOf() end

--- Lua-side handle to a loaded GPU texture stored in the engine's texture pool.
---@class Image
local Image = {}

--- Returns width and height of this image.
---@return integer
function Image:getDimensions() end

--- Returns the height of this image in pixels.
---@return integer
function Image:getHeight() end

--- Returns the width of this image in pixels.
---@return integer
function Image:getWidth() end

--- Releases the GPU texture memory for this image.
---@return boolean
function Image:release() end

--- Returns the type name of this object.
---@return string
function Image:type() end

--- Returns the type name of this object.
---@return string
function Image:typeOf() end

--- Lua-side handle to a loaded texture stored in SharedState.
---@class ImageData
local ImageData = {}

--- Returns the pixel height of this image buffer.
---@return integer
function ImageData:getHeight() end

--- Returns the pixel width of this image buffer.
---@return integer
function ImageData:getWidth() end

--- Returns the type name "ImageData".
---@return string
function ImageData:type() end

--- Returns true when the given name matches "ImageData" or a parent type.
---@param name any
---@return boolean
function ImageData:typeOf(name) end

--- Lua-side handle to a mesh stored in SharedState.
---@class Mesh
local Mesh = {}

--- Returns vertex data at the given 1-based index.
---@param index any
---@return number
function Mesh:getVertex(index) end

--- Returns the number of vertices in this mesh.
---@return integer
function Mesh:getVertexCount() end

--- Releases this mesh.
---@return boolean
function Mesh:release() end

--- Assigns a texture to this mesh.
---@param ud? any (optional)
---@return nil
function Mesh:setTexture(ud) end

--- Sets vertex data at the given 1-based index.
---@param index any
---@param data any
---@return nil
function Mesh:setVertex(index, data) end

--- Returns the type name of this object.
---@return string
function Mesh:type() end

--- Returns the type name of this object.
---@return string
function Mesh:typeOf() end

--- Lua-side 9-slice descriptor.
---@class NineSlice
local NineSlice = {}

--- Returns the four inset values as (top, right, bottom, left).
---@return number
function NineSlice:getInsets() end

--- Returns the width and height of the source texture.
---@return integer
function NineSlice:getTextureSize() end

--- Returns the type name "NineSlice".
---@return string
function NineSlice:type() end

--- Returns true when the given name matches "NineSlice" or a parent type.
---@param name any
---@return boolean
function NineSlice:typeOf(name) end

--- Lua-side quad viewport into a texture.
---@class Quad
local Quad = {}

--- Returns the reference texture dimensions.
---@return number
function Quad:getTextureDimensions() end

--- Returns the quad viewport rectangle.
---@return number
function Quad:getViewport() end

--- Returns the type name of this object.
---@return string
function Quad:type() end

--- Returns the type name of this object.
---@return string
function Quad:typeOf() end

--- Lua-side handle to a compiled shader stored in SharedState.
---@class Shader
local Shader = {}

--- Returns whether this shader has a uniform with the given name.
---@param name any
---@return boolean
function Shader:hasUniform(name) end

--- Releases this shader.
---@return boolean
function Shader:release() end

--- Sends a uniform value to this shader.
---@param name any
---@param value any
---@return nil
function Shader:send(name, value) end

--- Returns the type name of this object.
---@return string
function Shader:type() end

--- Returns the type name of this object.
---@return string
function Shader:typeOf() end

--- Lua-side handle to a [`CompoundShape`] stored in [`SharedState::shapes`].
---@class Shape
local Shape = {}

--- Removes all commands and resets the shape to empty.
function Shape:clear() end

--- Returns the number of drawing commands currently stored.
---@return integer
function Shape:getCommandCount() end

--- Queues a line segment command.
---@param x1 any
---@param y1 any
---@param x2 any
---@param y2 any
function Shape:line(x1, y1, x2, y2) end

--- Queues a polyline command from variadic (x, y) coordinate pairs.
function Shape:polyline() end

--- Sets the stroke width for subsequent outlined primitives.
---@param w any
function Shape:setLineWidth(w) end

--- Returns the type name of this object.
---@return string
function Shape:type() end

--- Returns true if the given type name matches this object's type or any parent type.
---@param name any
---@return boolean
function Shape:typeOf(name) end

--- Lua-side handle to a sprite batch stored in SharedState.
---@class SpriteBatch
local SpriteBatch = {}

--- Removes all sprites from this batch.
---@return nil
function SpriteBatch:clear() end

--- Returns the maximum capacity of this batch.
---@return integer
function SpriteBatch:getBufferSize() end

--- Returns the number of sprites in this batch.
---@return integer
function SpriteBatch:getCount() end

--- Releases this sprite batch.
---@return boolean
function SpriteBatch:release() end

--- Returns the type name of this object.
---@return string
function SpriteBatch:type() end

--- Returns the type name of this object.
---@return string
function SpriteBatch:typeOf() end

--- Applies an affine transform matrix.
---@param mat any
function lurek.graphic.applyTransform(mat) end

--- Draws a partial circle arc at the given position with specified radius and angle range.
---@param mode string
---@param x number
---@param y number
---@param radius number
---@param angle1 number
---@param angle2 number
---@param segments? integer? (optional)
function lurek.graphic.arc(mode, x, y, radius, angle1, angle2, segments) end

--- Calls the given callback with an ImageData captured from the current frame (stub: creates blank).
---@param callback any
---@return nil
function lurek.graphic.captureScreenshot(callback) end

--- Draws a circle.
---@param mode any
---@param x any
---@param y any
---@param radius any
function lurek.graphic.circle(mode, x, y, radius) end

--- Clears the draw command queue (resets the screen).
---@param r? any (optional)
---@param g? any (optional)
---@param b? any (optional)
function lurek.graphic.clear(r, g, b) end

--- Resets the stencil mode to the default (keep / always / 0).
---@return nil
function lurek.graphic.clearStencil() end

--- Draws a drawable (Image, Canvas, SpriteBatch, Mesh) at the given position.
---@param args any
function lurek.graphic.draw(args) end

--- Queues a 9-slice draw call inside lurek.render / lurek.render_ui.
---@param slice any
---@param x any
---@param y any
---@param w any
---@param h any
---@return nil
function lurek.graphic.drawNineSlice(slice, x, y, w, h) end

--- Draws a portion of an image defined by a Quad.
---@param image Image
---@param quad Quad
---@param x? number? (optional)
---@param y? number? (optional)
---@param r? number? (optional)
---@param sx? number? (optional)
---@param sy? number? (optional)
---@param ox? number? (optional)
---@param oy? number? (optional)
function lurek.graphic.drawq(image, quad, x, y, r, sx, sy, ox, oy) end

--- Draws an ellipse.
---@param mode any
---@param x any
---@param y any
---@param rx any
---@param ry any
function lurek.graphic.ellipse(mode, x, y, rx, ry) end

--- Returns the current background color.
---@return number
function lurek.graphic.getBackgroundColor() end

--- Returns the current blend mode as a string.
---@return string
function lurek.graphic.getBlendMode() end

--- Returns the current canvas, or nil if drawing to screen.
---@return Canvas?
function lurek.graphic.getCanvas() end

--- Returns the dimensions of a canvas.
---@param ud any
---@return integer
function lurek.graphic.getCanvasSize(ud) end

--- Returns the current drawing color.
---@return number
function lurek.graphic.getColor() end

--- Returns the current color mask.
---@return boolean
function lurek.graphic.getColorMask() end

--- Returns the default texture filter mode.
---@return string
function lurek.graphic.getDefaultFilter() end

--- Returns the current depth mode as (mode, write).
---@return string
function lurek.graphic.getDepthMode() end

--- Returns window width and height.
---@return integer
function lurek.graphic.getDimensions() end

--- Returns the currently active font, or nil.
---@return Font?
function lurek.graphic.getFont() end

--- Returns the ascent of the given font.
---@param ud any
---@return number
function lurek.graphic.getFontAscent(ud) end

--- Returns the descent of the given font.
---@param ud any
---@return number
function lurek.graphic.getFontDescent(ud) end

--- Returns the line height of the given font.
---@param ud any
---@return number
function lurek.graphic.getFontHeight(ud) end

--- Returns the line height of the given font (alias for getFontHeight).
---@param ud any
---@return number
function lurek.graphic.getFontLineHeight(ud) end

--- Returns the pixel width of text in the given font.
---@param ud any
---@param text any
---@return number
function lurek.graphic.getFontWidth(ud, text) end

--- Returns wrapped lines and the maximum line width.
---@param text any
---@param limit any
---@return table
function lurek.graphic.getFontWrap(text, limit) end

--- Returns the window height in pixels.
---@return integer
function lurek.graphic.getHeight() end

--- Returns the current line width.
---@return number
function lurek.graphic.getLineWidth() end

--- Returns the current point size.
---@return number
function lurek.graphic.getPointSize() end

--- Returns the active scissor rectangle, or nothing.
---@return number?
function lurek.graphic.getScissor() end

--- Returns the active shader, or nil.
---@return Shader?
function lurek.graphic.getShader() end

--- Returns a table of renderer statistics.
---@return table
function lurek.graphic.getStats() end

--- Returns the current stencil mode as (action, compare, value).
---@return string
function lurek.graphic.getStencilMode() end

--- Returns the window width in pixels.
---@return integer
function lurek.graphic.getWidth() end

--- Intersects the current scissor with a new rectangle.
---@param x any
---@param y any
---@param w any
---@param h any
function lurek.graphic.intersectScissor(x, y, w, h) end

--- Returns whether wireframe mode is active.
---@return boolean
function lurek.graphic.isWireframe() end

--- Draws a line between two points.
---@param args any
function lurek.graphic.line(args) end

--- Creates an off-screen render canvas.
---@param width any
---@param height any
---@return Canvas
function lurek.graphic.newCanvas(width, height) end

--- Creates a new z-ordered draw-call queue.
---@return DrawLayer
function lurek.graphic.newDrawLayer() end

--- Loads a TTF/OTF font from a file.
---@param path any
---@param size? any (optional)
---@return Font
function lurek.graphic.newFont(path, size) end

--- Loads an image from a file path or creates one from ImageData.
---@param arg any
---@return Image
function lurek.graphic.newImage(arg) end

--- Creates a custom mesh from vertex data.
---@param verts any
---@param mode? any (optional)
---@return Mesh
function lurek.graphic.newMesh(verts, mode) end

--- Creates a 9-slice descriptor from a texture and inset values.
---@param image any
---@param top any
---@param right any
---@param bottom any
---@param left any
---@return NineSlice
function lurek.graphic.newNineSlice(image, top, right, bottom, left) end

--- Creates a new Quad viewport into a texture.
---@param x any
---@param y any
---@param w any
---@param h any
---@param sw any
---@param sh any
---@return Quad
function lurek.graphic.newQuad(x, y, w, h, sw, sh) end

--- Compiles a custom WGSL shader and returns its handle.
---@param code any
---@return Shader
function lurek.graphic.newShader(code) end

--- Creates a new empty [`CompoundShape`] stored in the resource pool.
---@return Shape
function lurek.graphic.newShape() end

--- Creates a new sprite batch for the given image.
---@param ud any
---@param max? any (optional)
---@return SpriteBatch
function lurek.graphic.newSpriteBatch(ud, max) end

--- Resets the transform to the identity.
function lurek.graphic.origin() end

--- Draws a list of points.
---@param args any
function lurek.graphic.points(args) end

--- Draws a polygon from a list of vertices.
---@param args any
function lurek.graphic.polygon(args) end

--- Pops the transform from the stack.
function lurek.graphic.pop() end

--- Draws text at the given position.
---@param text any
---@param x? any (optional)
---@param y? any (optional)
---@param scale? any (optional)
function lurek.graphic.print(text, x, y, scale) end

--- Draws word-wrapped text within a given width.
---@param text any
---@param x any
---@param y any
---@param limit any
---@param align? any (optional)
function lurek.graphic.printf(text, x, y, limit, align) end

--- Pushes the current transform onto the stack.
function lurek.graphic.push() end

--- Draws a rectangle.
---@param mode string
---@param x number
---@param y number
---@param w number
---@param h number
---@param rx? number? (optional)
---@param ry? number? (optional)
function lurek.graphic.rectangle(mode, x, y, w, h, rx, ry) end

--- Rotates the coordinate system.
---@param angle any
function lurek.graphic.rotate(angle) end

--- Queues a screenshot to be saved after the current frame.
---@param path any
function lurek.graphic.saveScreenshot(path) end

--- Scales the coordinate system.
---@param sx any
---@param sy? any (optional)
function lurek.graphic.scale(sx, sy) end

--- Sets the background clear color.
---@param r any
---@param g any
---@param b any
function lurek.graphic.setBackgroundColor(r, g, b) end

--- Sets the blend mode for drawing.
---@param mode any
function lurek.graphic.setBlendMode(mode) end

--- Sets the active render target to a Canvas, or back to the screen.
---@param ud? any (optional)
function lurek.graphic.setCanvas(ud) end

--- Sets the current drawing color.
---@param r any
---@param g any
---@param b any
---@param a? any (optional)
function lurek.graphic.setColor(r, g, b, a) end

--- Sets which RGBA channels are written. Reset with no args.
---@param args any
function lurek.graphic.setColorMask(args) end

--- Sets the default texture filter mode.
---@param min any
---@param mag any
---@param anisotropy? any (optional)
function lurek.graphic.setDefaultFilter(min, mag, anisotropy) end

--- Sets the depth test comparison and write enable.
---@param mode any
---@param write? any (optional)
function lurek.graphic.setDepthMode(mode, write) end

--- Sets the active font for print calls.
---@param ud any
function lurek.graphic.setFont(ud) end

--- Sets the line height of the given font (stub — returns nil; fonts are immutable in headless mode).
---@param font any
---@param lh any
---@return nil
function lurek.graphic.setFontLineHeight(font, lh) end

--- Sets the line width for outline drawing.
---@param w any
function lurek.graphic.setLineWidth(w) end

--- Sets the point diameter in pixels.
---@param size any
function lurek.graphic.setPointSize(size) end

--- Restricts drawing to a rectangle, or clears scissor if no args.
---@param args any
function lurek.graphic.setScissor(args) end

--- Sets the active shader, or clears it.
---@param ud? any (optional)
function lurek.graphic.setShader(ud) end

--- Sets the stencil buffer write/test mode.
---@param action any
---@param compare? any (optional)
---@param value? any (optional)
function lurek.graphic.setStencilMode(action, compare, value) end

--- Sets the stencil comparison test, or disables stencil testing.
---@param compare? any (optional)
---@param value? any (optional)
function lurek.graphic.setStencilTest(compare, value) end

--- Enables or disables wireframe rendering.
---@param enabled any
function lurek.graphic.setWireframe(enabled) end

--- Shears the coordinate system.
---@param kx any
---@param ky any
function lurek.graphic.shear(kx, ky) end

--- Begins stencil writing with the given action and value.
---@param action? any (optional)
---@param value? any (optional)
function lurek.graphic.stencil(action, value) end

--- Translates the coordinate system.
---@param x any
---@param y any
function lurek.graphic.translate(x, y) end

--- Draws a triangle.
---@param mode any
---@param x1 any
---@param y1 any
---@param x2 any
---@param y2 any
---@param x3 any
---@param y3 any
function lurek.graphic.triangle(mode, x1, y1, x2, y2, x3, y3) end

---@class lurek.image
lurek.image = {}

--- Lua-side wrapper around [`CompressedImageData`].
---@class CompressedImageData
local CompressedImageData = {}

--- Returns the width and height of the base mip level.
---@return integer
function CompressedImageData:getDimensions() end

--- Returns the compressed format name string.
---@return string
function CompressedImageData:getFormat() end

--- Returns the height of the base mip level in pixels.
---@return integer
function CompressedImageData:getHeight() end

--- Returns the number of mipmap levels stored.
---@return integer
function CompressedImageData:getMipmapCount() end

--- Returns the width of the base mip level in pixels.
---@return integer
function CompressedImageData:getWidth() end

--- Lua-side wrapper around [`LayeredImage`].
---@class LayeredImage
local LayeredImage = {}

--- Appends a new blank transparent layer on top and returns its 1-based index.
---@param name? any (optional)
---@return integer
function LayeredImage:addLayer(name) end

--- Returns the canvas height shared by all layers.
---@return integer
function LayeredImage:getHeight() end

--- Returns a copy of the layer's pixel buffer as an ImageData.
---@param index any
---@return ImageData
function LayeredImage:getLayer(index) end

--- Returns the name of a layer.
---@param index any
---@return string
function LayeredImage:getName(index) end

--- Returns the opacity of a layer in [0.0, 1.0].
---@param index any
---@return number
function LayeredImage:getOpacity(index) end

--- Returns the canvas width shared by all layers.
---@return integer
function LayeredImage:getWidth() end

--- Returns whether a layer is visible.
---@param index any
---@return boolean
function LayeredImage:isVisible(index) end

--- Returns the number of layers in the stack.
---@return integer
function LayeredImage:layerCount() end

--- Flattens all visible layers into a single ImageData using Porter-Duff "over" compositing.
---@return ImageData
function LayeredImage:merge() end

--- Removes the layer at the given 1-based index. Returns true on success.
---@param index any
---@return boolean
function LayeredImage:removeLayer(index) end

--- Saves the layered image to a LIMG binary file at the given path.
---@param path any
---@return nil
function LayeredImage:save(path) end

--- Renames a layer.
---@param index any
---@param name any
---@return boolean
function LayeredImage:setName(index, name) end

--- Sets the opacity of a layer. Value is clamped to [0.0, 1.0].
---@param index any
---@param opacity any
---@return boolean
function LayeredImage:setOpacity(index, opacity) end

--- Shows or hides a layer during compositing.
---@param index any
---@param visible any
---@return boolean
function LayeredImage:setVisible(index, visible) end

--- Swaps two layers by their 1-based indices, changing their compositing order.
---@param a any
---@param b any
---@return boolean
function LayeredImage:swapLayers(a, b) end

--- Returns true if the file at the given path is a DDS file.
---@param filename any
---@return boolean
function lurek.image.isCompressed(filename) end

--- Loads an ImageData from a LIMG binary file.
---@param filename any
---@return ImageData
function lurek.image.loadImage(filename) end

--- Loads a LayeredImage from a LIMG binary file.
---@param filename any
---@return LayeredImage
function lurek.image.loadLayered(filename) end

--- Loads compressed texture data from a DDS file.
---@param filename any
---@return CompressedImageData
function lurek.image.newCompressedData(filename) end

--- Creates a new blank ImageData or loads one from a file.
---@param args any
---@return ImageData
function lurek.image.newImageData(args) end

--- Creates a new empty LayeredImage canvas with no layers.
---@param width any
---@param height any
---@return LayeredImage
function lurek.image.newLayeredImage(width, height) end

--- Saves a flat ImageData to a LIMG binary file at the given path.
---@param img_ud any
---@param filename any
---@return nil
function lurek.image.saveImage(img_ud, filename) end

--- Saves a flat ImageData as a PNG file at the given path.
---@param img_ud any
---@param filename any
---@return nil
function lurek.image.savePNG(img_ud, filename) end

---@class lurek.input
lurek.input = {}

--- Lua-side wrapper around a mouse cursor handle.
---@class Cursor
local Cursor = {}

--- Returns the cursor type as "system" or "custom".
---@return string
function Cursor:getType() end

--- Releases the cursor resource (no-op on desktop).
---@return nil
function Cursor:release() end

--- Returns the current value (-1 to 1) of a gamepad analog axis.
---@param id any
---@param axis any
---@return number
function lurek.input.getAxis(id, axis) end

--- Returns the total number of analog axes on the gamepad.
---@param id any
---@return integer
function lurek.input.getAxisCount(id) end

--- Returns whether background gamepad events are enabled.
---@return boolean
function lurek.input.getBackgroundEvents() end

--- Returns the total number of buttons on the gamepad.
---@param id any
---@return integer
function lurek.input.getButtonCount(id) end

--- Returns the number of connected gamepads.
---@return integer
function lurek.input.getCount() end

--- Returns the name of the currently active system cursor.
---@return string
function lurek.input.getCursor() end

--- Returns the hardware GUID string of the gamepad.
---@param id any
---@return string
function lurek.input.getGUID(id) end

--- Returns the stored mapping string for the given GUID, or nil.
---@param guid any
---@return string?
function lurek.input.getGamepadMappingString(guid) end

--- Returns the direction string of a hat switch on the gamepad.
---@param id any
---@param hat any
---@return string
function lurek.input.getHat(id, hat) end

--- Returns the number of tracked gamepad slots.
---@return integer
function lurek.input.getJoystickCount() end

--- Returns a list of connected gamepad IDs.
---@return table
function lurek.input.getJoysticks() end

--- Returns the key name for the given hardware scancode.
---@param scancode any
---@return string?
function lurek.input.getKeyFromScancode(scancode) end

--- Returns the human-readable name of a gamepad.
---@param id any
---@return string
function lurek.input.getName(id) end

--- Returns the current cursor position as (x, y).
---@return number
function lurek.input.getPosition() end

--- Returns the position (x, y) of the touch with the given ID.
---@param id any
---@return number
function lurek.input.getPosition(id) end

--- Returns the pressure (0-1) of the touch with the given ID.
---@param id any
---@return number
function lurek.input.getPressure(id) end

--- Returns whether relative mouse mode is active.
---@return boolean
function lurek.input.getRelativeMode() end

--- Returns the hardware scancode for the given key name.
---@param key any
---@return string?
function lurek.input.getScancodeFromKey(key) end

--- Returns a system cursor object for the named cursor shape.
---@param name any
---@return Cursor
function lurek.input.getSystemCursor(name) end

--- Returns the number of currently active touch points.
---@return integer
function lurek.input.getTouchCount() end

--- Returns a table of active touch points with id, x, y, and pressure fields.
---@return table
function lurek.input.getTouches() end

--- Returns the mouse scroll wheel delta (dx, dy) since last frame.
---@return number
function lurek.input.getWheelDelta() end

--- Returns the current mouse X position in window coordinates.
---@return number
function lurek.input.getX() end

--- Returns the current mouse Y position in window coordinates.
---@return number
function lurek.input.getY() end

--- Returns whether key-repeat is currently enabled.
---@return boolean
function lurek.input.hasKeyRepeat() end

--- Returns whether text input mode is currently active.
---@return boolean
function lurek.input.hasTextInput() end

--- Returns whether the gamepad with the given ID is connected.
---@param id any
---@return boolean
function lurek.input.isConnected(id) end

--- Returns whether cursor customisation is supported on this platform.
---@return boolean
function lurek.input.isCursorSupported() end

--- Returns true if any of the given keys is currently held down.
---@param args any
---@return boolean
function lurek.input.isDown(args) end

--- Returns whether the given mouse button is currently held down.
---@param button any
---@return boolean
function lurek.input.isDown(button) end

--- Returns whether the given button on the gamepad is currently held.
---@param id any
---@param button any
---@return boolean
function lurek.input.isDown(id, button) end

--- Returns whether the joystick at the given slot is a recognized gamepad.
---@param id any
---@return boolean
function lurek.input.isGamepad(id) end

--- Returns whether the mouse cursor is locked to the window.
---@return boolean
function lurek.input.isGrabbed() end

--- Returns whether the named modifier key is currently held.
---@param modifier any
---@return boolean
function lurek.input.isModifierActive(modifier) end

--- Returns whether the key with the given scancode is held.
---@param scancode any
---@return boolean
function lurek.input.isScancodeDown(scancode) end

--- Returns whether the gamepad supports haptic vibration.
---@param id any
---@return boolean
function lurek.input.isVibrationSupported(id) end

--- Returns whether the mouse cursor is currently visible.
---@return boolean
function lurek.input.isVisible() end

--- Loads SDL2 GameControllerDB-format mappings from a file.
---@param path any
---@return integer
function lurek.input.loadGamepadMappings(path) end

--- Creates a custom mouse cursor from RGBA pixel data.
---@param pixels table
---@param width integer
---@param height integer
---@param hotx? integer? (optional)
---@param hoty? integer? (optional)
---@return Cursor
function lurek.input.newCursor(pixels, width, height, hotx, hoty) end

--- Saves all stored gamepad mappings to a plain-text file.
---@param path any
---@return nil
function lurek.input.saveGamepadMappings(path) end

--- Enable or disable receiving gamepad events when the window is not focused.
---@param enable any
---@return nil
function lurek.input.setBackgroundEvents(enable) end

--- Sets the active mouse cursor from a Cursor handle, name string, or nil to reset.
---@param cursor_val any
---@return nil
function lurek.input.setCursor(cursor_val) end

--- Stores or replaces the SDL2 GameControllerDB mapping string for the given GUID.
---@param guid any
---@param mapping any
---@return nil
function lurek.input.setGamepadMapping(guid, mapping) end

--- Locks or unlocks the mouse cursor to the window.
---@param grabbed any
---@return nil
function lurek.input.setGrabbed(grabbed) end

--- Enables or disables key-repeat events.
---@param enabled any
---@return nil
function lurek.input.setKeyRepeat(enabled) end

--- Moves the mouse cursor to the given window-space position.
---@param x any
---@param y any
---@return nil
function lurek.input.setPosition(x, y) end

--- Enables or disables raw relative mouse motion mode.
---@param relative any
---@return nil
function lurek.input.setRelativeMode(relative) end

--- Enables or disables Unicode text input mode.
---@param enabled any
---@return nil
function lurek.input.setTextInput(enabled) end

--- Triggers haptic rumble (currently a no-op stub).
---@param args any
---@return boolean
function lurek.input.setVibration(args) end

--- Shows or hides the operating-system mouse cursor.
---@param visible any
---@return nil
function lurek.input.setVisible(visible) end

---@class lurek.light
lurek.light = {}

--- Lua-side handle to a light resource stored in [`LightWorld`].
---@class Light
local Light = {}

--- Returns the custom attenuation coefficients as (constant, linear, quadratic).
---@return number
function Light:getAttenuation() end

--- Returns the blend mode as a string.
---@return string
function Light:getBlendMode() end

--- Returns the light's tint color as (r, g, b, a).
---@return number
function Light:getColor() end

--- Returns the direction angle in radians.
---@return number
function Light:getDirection() end

--- Returns the energy scaling factor.
---@return number
function Light:getEnergy() end

--- Returns the falloff mode as a string.
---@return string
function Light:getFalloff() end

--- Returns the flicker effect speed and strength.
---@return number
function Light:getFlicker() end

--- Returns the group identifier.
---@return integer
function Light:getGroupId() end

--- Returns the inner cone angle in radians.
---@return number
function Light:getInnerAngle() end

--- Returns the brightness multiplier.
---@return number
function Light:getIntensity() end

--- Returns the light interaction bitmask.
---@return integer
function Light:getLightMask() end

--- Returns the geometric light type as a string.
---@return string
function Light:getLightType() end

--- Returns the outer cone angle in radians.
---@return number
function Light:getOuterAngle() end

--- Returns the light's world-space position.
---@return number
function Light:getPosition() end

--- Returns the light's influence radius.
---@return number
function Light:getRadius() end

--- Returns the shadow region color as (r, g, b, a).
---@return number
function Light:getShadowColor() end

--- Returns the shadow edge filter as a string.
---@return string
function Light:getShadowFilter() end

--- Returns the shadow casting bitmask.
---@return integer
function Light:getShadowMask() end

--- Returns the shadow edge smoothing factor.
---@return number
function Light:getShadowSmooth() end

--- Returns whether this light is active.
---@return boolean
function Light:isEnabled() end

--- Returns whether the flicker effect is active.
---@return boolean
function Light:isFlickerEnabled() end

--- Returns whether this light casts shadows.
---@return boolean
function Light:isShadowEnabled() end

--- Returns whether this light handle is still valid.
---@return boolean
function Light:isValid() end

--- Returns whether this light hints at volumetric scattering.
---@return boolean
function Light:isVolumetric() end

--- Removes this light from the world.
---@return nil
function Light:remove() end

--- Sets the custom attenuation coefficients (constant, linear, quadratic).
---@param c any
---@param l any
---@param q any
---@return nil
function Light:setAttenuation(c, l, q) end

--- Sets the blend mode ('add', 'sub', or 'mix').
---@param mode any
---@return nil
function Light:setBlendMode(mode) end

--- Sets the light's tint color.
---@param r any
---@param g any
---@param b any
---@param a? any (optional)
---@return nil
function Light:setColor(r, g, b, a) end

--- Sets the direction angle in radians.
---@param dir any
---@return nil
function Light:setDirection(dir) end

--- Sets whether this light is active.
---@param b any
---@return nil
function Light:setEnabled(b) end

--- Sets the energy scaling factor.
---@param e any
---@return nil
function Light:setEnergy(e) end

--- Sets the falloff mode ('linear', 'smooth', or 'constant').
---@param mode any
---@return nil
function Light:setFalloff(mode) end

--- Sets the flicker effect speed and strength (enables flicker).
---@param speed any
---@param strength any
---@return nil
function Light:setFlicker(speed, strength) end

--- Sets whether the flicker effect is active.
---@param b any
---@return nil
function Light:setFlickerEnabled(b) end

--- Sets the group identifier for batch operations.
---@param id any
---@return nil
function Light:setGroupId(id) end

--- Sets the inner cone angle in radians for spot lights.
---@param a any
---@return nil
function Light:setInnerAngle(a) end

--- Sets the brightness multiplier.
---@param i any
---@return nil
function Light:setIntensity(i) end

--- Sets the light interaction bitmask.
---@param mask any
---@return nil
function Light:setLightMask(mask) end

--- Sets the geometric light type ('point', 'directional', or 'spot').
---@param t any
---@return nil
function Light:setLightType(t) end

--- Sets the outer cone angle in radians for spot lights.
---@param a any
---@return nil
function Light:setOuterAngle(a) end

--- Sets the light's world-space position.
---@param x any
---@param y any
---@return nil
function Light:setPosition(x, y) end

--- Sets the light's influence radius.
---@param r any
---@return nil
function Light:setRadius(r) end

--- Sets whether this light casts shadows.
---@param b any
---@return nil
function Light:setShadowEnabled(b) end

--- Sets the shadow edge filter ('none', 'pcf5', or 'pcf13').
---@param filter any
---@return nil
function Light:setShadowFilter(filter) end

--- Sets the shadow casting bitmask.
---@param mask any
---@return nil
function Light:setShadowMask(mask) end

--- Sets the shadow edge smoothing factor.
---@param s any
---@return nil
function Light:setShadowSmooth(s) end

--- Sets whether this light hints at volumetric scattering.
---@param b any
---@return nil
function Light:setVolumetric(b) end

--- Lua-side handle to an occluder resource stored in [`LightWorld`].
---@class Occluder
local Occluder = {}

--- Returns the light interaction bitmask.
---@return integer
function Occluder:getLightMask() end

--- Returns the shadow opacity.
---@return number
function Occluder:getOpacity() end

--- Returns the translation offset as (x, y).
---@return number
function Occluder:getPosition() end

--- Returns the polygon vertices as a flat table {x1,y1,x2,y2,...}.
---@return table
function Occluder:getVertices() end

--- Returns whether this occluder is active.
---@return boolean
function Occluder:isEnabled() end

--- Returns whether this occluder handle is still valid.
---@return boolean
function Occluder:isValid() end

--- Removes this occluder from the world.
---@return nil
function Occluder:remove() end

--- Sets whether this occluder is active.
---@param b any
---@return nil
function Occluder:setEnabled(b) end

--- Sets the light interaction bitmask.
---@param mask any
---@return nil
function Occluder:setLightMask(mask) end

--- Sets the shadow opacity (0.0–1.0).
---@param o any
---@return nil
function Occluder:setOpacity(o) end

--- Sets the translation offset applied to all vertices.
---@param x any
---@param y any
---@return nil
function Occluder:setPosition(x, y) end

--- Replaces the polygon vertices from a flat table {x1,y1,x2,y2,...}.
---@param tbl any
---@return nil
function Occluder:setVertices(tbl) end

--- Advances flicker phase for all lights with flicker enabled.
---@param dt any
---@return nil
function lurek.light.advanceFlickers(dt) end

--- Removes all lights and occluders, resets ambient to default.
---@return nil
function lurek.light.clear() end

--- Returns the global ambient light color as (r, g, b, a).
---@return number
function lurek.light.getAmbient() end

--- Returns the number of lights in the given group.
---@param group_id any
---@return integer
function lurek.light.getGroupCount(group_id) end

--- Returns the number of lights in the world.
---@return integer
function lurek.light.getLightCount() end

--- Returns the maximum number of lights processed per frame.
---@return integer
function lurek.light.getMaxLights() end

--- Returns the number of occluders in the world.
---@return integer
function lurek.light.getOccluderCount() end

--- Returns whether the lighting system is active.
---@return boolean
function lurek.light.isEnabled() end

--- Creates a new light at (x, y) with the given radius and optional settings.
---@param x any
---@param y any
---@param radius any
---@param opts? any (optional)
---@return Light
function lurek.light.newLight(x, y, radius, opts) end

--- Creates a new shadow occluder from a vertex table and optional settings.
---@param vtbl any
---@param opts? any (optional)
---@return Occluder
function lurek.light.newOccluder(vtbl, opts) end

--- Sets the global ambient light color.
---@param r any
---@param g any
---@param b any
---@param a? any (optional)
---@return nil
function lurek.light.setAmbient(r, g, b, a) end

--- Sets whether the lighting system is active.
---@param enabled any
---@return nil
function lurek.light.setEnabled(enabled) end

--- Sets the color for all lights in the given group.
---@param group_id any
---@param r any
---@param g any
---@param b any
---@param a? any (optional)
---@return nil
function lurek.light.setGroupColor(group_id, r, g, b, a) end

--- Sets the enabled state for all lights in the given group.
---@param group_id any
---@param enabled any
---@return nil
function lurek.light.setGroupEnabled(group_id, enabled) end

--- Sets the intensity for all lights in the given group.
---@param group_id any
---@param intensity any
---@return nil
function lurek.light.setGroupIntensity(group_id, intensity) end

--- Sets the maximum number of lights processed per frame (clamped 1–256).
---@param n any
---@return nil
function lurek.light.setMaxLights(n) end

---@class lurek.localization
lurek.localization = {}

--- Builds an inverted word index for the active locale. Returns index as {word → {keys}}.
---@return table
function lurek.localization.buildIndex() end

--- Returns unique first-path-segment category prefixes for all active locale keys.
---@return table
function lurek.localization.categories() end

--- Returns all loaded locale codes (alias for getLanguages).
---@return table
function lurek.localization.getAvailableLanguages() end

--- Returns the base/fallback language.
---@return string
function lurek.localization.getBase() end

--- Returns the current fallback locale array.
---@return table
function lurek.localization.getFallbacks() end

--- Returns all known keys for the active locale.
---@return table
function lurek.localization.getKeys() end

--- Returns the currently active locale code, or nil if unset.
---@return string?
function lurek.localization.getLanguage() end

--- Returns all loaded locale codes.
---@return table
function lurek.localization.getLanguages() end

--- Returns whether a key exists in the active locale.
---@param key any
---@return boolean
function lurek.localization.hasKey(key) end

--- Returns whether a locale has been loaded.
---@param locale any
---@return boolean
function lurek.localization.hasLanguage(locale) end

--- Interpolates {name} placeholders in a template string.
---@param template any
---@param vars any
---@return string
function lurek.localization.interpolate(template, vars) end

--- Returns the number of keys loaded in the active locale.
---@return integer
function lurek.localization.keyCount() end

--- Returns all keys in the active locale whose first path segment matches category.
---@param category any
---@return table
function lurek.localization.keysInCategory(category) end

--- Loads a language table under the given locale code.
---@param locale any
---@param tbl any
function lurek.localization.loadTable(locale, tbl) end

--- Merges a flat key→value table into an existing locale without replacing the whole table.
---@param locale any
---@param entries any
function lurek.localization.mergeLocale(locale, entries) end

--- Unregisters all onChange callbacks.
function lurek.localization.offChange() end

--- Registers a callback invoked when setLanguage() is called (alias: onChange).
---@param cb any
function lurek.localization.onChange(cb) end

--- Registers a callback invoked when setLanguage() is called.
---@param cb any
function lurek.localization.onLanguageChange(cb) end

--- Returns the CLDR plural category for a number ("one" or "other", etc.).
---@param n any
---@return string
function lurek.localization.pluralFor(n) end

--- Searches active locale values for a substring query (case-insensitive). Returns {key, value} pairs.
---@param query any
---@param limit? any (optional)
---@return table
function lurek.localization.search(query, limit) end

--- Searches the provided pre-built index for entries matching all words in query.
---@param index any
---@param query any
---@param limit? any (optional)
---@return table
function lurek.localization.searchIndexed(index, query, limit) end

--- Sets the base/fallback language (adds it as first fallback).
---@param locale any
function lurek.localization.setBase(locale) end

--- Sets the ordered list of fallback locale codes tried when a key is missing.
---@param locales any
function lurek.localization.setFallbacks(locales) end

--- Inserts or overwrites a single key in the given locale.
---@param locale any
---@param key any
---@param value any
function lurek.localization.setKey(locale, key, value) end

--- Sets the active translation language.
---@param locale any
function lurek.localization.setLanguage(locale) end

--- Translates a key against the active locale with optional variable
---@param key any
---@param vars? any (optional)
---@param count? any (optional)
---@return string
function lurek.localization.t(key, vars, count) end

--- Unloads a locale from the catalog.
---@param locale any
---@return boolean
function lurek.localization.unloadTable(locale) end

---@class lurek.log
lurek.log = {}

--- Registers a new output sink. Returns its numeric id.
---@param config any
---@return integer
function lurek.log.addSink(config) end

--- Removes all registered sinks (the default stderr channel is unaffected).
function lurek.log.clearSinks() end

--- Emits a debug-severity log message. Also dispatches to configured sinks.
---@param message any
---@param tag? any (optional)
function lurek.log.debug(message, tag) end

--- Emits an error-severity log message. Also dispatches to configured sinks.
---@param message any
---@param tag? any (optional)
function lurek.log.error(message, tag) end

--- Flushes the OS write buffer for a file sink.
---@param id any
function lurek.log.flushFile(id) end

--- Returns the name of the currently active minimum log level.
---@return string
function lurek.log.getLevel() end

--- Emits an info-severity log message. Also dispatches to configured sinks.
---@param message any
---@param tag? any (optional)
function lurek.log.info(message, tag) end

--- Returns a table describing all registered sinks.
---@return table
function lurek.log.listSinks() end

--- Emits a log message at the specified level. Also dispatches to sinks.
---@param level any
---@param message any
---@param tag? any (optional)
function lurek.log.print(level, message, tag) end

--- Reads entries from a memory sink. If drain=true the buffer is cleared.
---@param id any
---@param drain? any (optional)
---@return table?
function lurek.log.readMemory(id, drain) end

--- Removes a sink by id. Returns true if one was removed.
---@param id any
---@return boolean
function lurek.log.removeSink(id) end

--- Sets the minimum severity level for the default log channel.
---@param level any
function lurek.log.setLevel(level) end

--- Emits a warn-severity log message. Also dispatches to configured sinks.
---@param message any
---@param tag? any (optional)
function lurek.log.warn(message, tag) end

---@class lurek.math
lurek.math = {}

--- Lua-side wrapper around a [`BezierCurve`].
---@class BezierCurve
local BezierCurve = {}

--- Evaluates the curve at parameter t, returning (x, y).
---@param t any
---@return number
function BezierCurve:evaluate(t) end

--- Returns the control point at 1-based index as (x, y), or nil.
---@param index any
---@return number?
function BezierCurve:getControlPoint(index) end

--- Returns the number of control points.
---@return integer
function BezierCurve:getControlPointCount() end

--- Returns a new BezierCurve representing the first derivative.
---@return BezierCurve
function BezierCurve:getDerivative() end

--- Returns the approximate arc length of the curve.
---@return number
function BezierCurve:length() end

--- Removes a control point at 1-based index.
---@param index any
---@return boolean
function BezierCurve:removeControlPoint(index) end

--- Renders the curve as a polyline with the given number of segments.
---@param segments any
---@return table
function BezierCurve:render(segments) end

--- Rotates all control points around a pivot by angle radians.
---@param angle any
---@param ox any
---@param oy any
---@return nil
function BezierCurve:rotate(angle, ox, oy) end

--- Scales all control points around a pivot by factor s.
---@param s any
---@param ox any
---@param oy any
---@return nil
function BezierCurve:scale(s, ox, oy) end

--- Translates all control points by (dx, dy).
---@param dx any
---@param dy any
---@return nil
function BezierCurve:translate(dx, dy) end

--- Lua-side wrapper around a [`NoiseGenerator`].
---@class NoiseGenerator
local NoiseGenerator = {}

--- Returns the current seed.
---@return integer
function NoiseGenerator:getSeed() end

--- Returns 1D Perlin noise at x.
---@param x any
---@return number
function NoiseGenerator:perlin1d(x) end

--- Returns 2D Perlin noise at (x, y).
---@param x any
---@param y any
---@return number
function NoiseGenerator:perlin2d(x, y) end

--- Returns 3D Perlin noise at (x, y, z).
---@param x any
---@param y any
---@param z any
---@return number
function NoiseGenerator:perlin3d(x, y, z) end

--- Returns 4D Perlin noise at (x, y, z, w).
---@param x any
---@param y any
---@param z any
---@param w any
---@return number
function NoiseGenerator:perlin4d(x, y, z, w) end

--- Sets the seed and rebuilds the permutation table.
---@param seed any
---@return nil
function NoiseGenerator:setSeed(seed) end

--- Returns 1D Simplex noise at x.
---@param x any
---@return number
function NoiseGenerator:simplex1d(x) end

--- Returns 2D Simplex noise at (x, y).
---@param x any
---@param y any
---@return number
function NoiseGenerator:simplex2d(x, y) end

--- Returns 3D Simplex noise at (x, y, z).
---@param x any
---@param y any
---@param z any
---@return number
function NoiseGenerator:simplex3d(x, y, z) end

--- Lua-side wrapper around a [`RandomGenerator`].
---@class RandomGenerator
local RandomGenerator = {}

--- Returns the seed used to initialise this generator.
---@return integer
function RandomGenerator:getSeed() end

--- Serialises the generator state as a string for later restoration.
---@return string
function RandomGenerator:getState() end

--- Returns a uniform random number in [0, 1).
---@return number
function RandomGenerator:random() end

--- Returns a uniform random float in [min, max).
---@param min any
---@param max any
---@return number
function RandomGenerator:randomFloat(min, max) end

--- Returns a uniform random integer in [min, max].
---@param min any
---@param max any
---@return integer
function RandomGenerator:randomInt(min, max) end

--- Sets the seed, fully resetting the generator state.
---@param seed any
---@return nil
function RandomGenerator:setSeed(seed) end

--- Restores the generator state from a previously serialised string.
---@param state any
---@return nil
function RandomGenerator:setState(state) end

--- Lua-side wrapper around a [`SpatialHash`].
---@class SpatialHash
local SpatialHash = {}

--- Removes all items.
---@return nil
function SpatialHash:clear() end

--- Returns the cell size.
---@return number
function SpatialHash:getCellSize() end

--- Returns the number of items in the hash.
---@return integer
function SpatialHash:getItemCount() end

--- Removes an item by its ID.
---@param id any
---@return nil
function SpatialHash:remove(id) end

--- Lua-side wrapper around a [`Transform`].
---@class Transform
local Transform = {}

--- Returns a copy of this transform.
---@return Transform
function Transform:clone() end

--- Returns the 3x3 matrix as a flat table of 9 numbers (row-major).
---@return table
function Transform:getMatrix() end

--- Returns a new Transform that undoes this transform.
---@return Transform
function Transform:inverse() end

--- Transforms a point from world space back to local space.
---@param x any
---@param y any
---@return number
function Transform:inverseTransformPoint(x, y) end

--- Resets the transform to identity.
---@return nil
function Transform:reset() end

--- Applies a rotation in radians.
---@param angle any
---@return nil
function Transform:rotate(angle) end

--- Applies non-uniform scaling.
---@param sx any
---@param sy? any (optional)
---@return nil
function Transform:scale(sx, sy) end

--- Applies shear factors.
---@param kx any
---@param ky any
---@return nil
function Transform:shear(kx, ky) end

--- Transforms a point from local space to world space.
---@param x any
---@param y any
---@return number
function Transform:transformPoint(x, y) end

--- Applies translation to the transform.
---@param dx any
---@param dy any
---@return nil
function Transform:translate(dx, dy) end

--- Lua-side wrapper around a [`Tween`].
---@class Tween
local Tween = {}

--- Adds a start/target value pair. Returns the 1-based index.
---@param start any
---@param target any
---@return integer
function Tween:addValue(start, target) end

--- Returns all interpolated values as a table.
---@return table
function Tween:getAllValues() end

--- Alias for getTime(). Returns the current clock time.
---@return number
function Tween:getClock() end

--- Returns the tween duration in seconds.
---@return number
function Tween:getDuration() end

--- Returns the easing function name.
---@return string
function Tween:getEasingName() end

--- Returns the current clock time.
---@return number
function Tween:getTime() end

--- Returns the interpolated value at 1-based index, or all values as a
---@param index? any (optional)
---@return number
function Tween:getValue(index) end

--- Returns the number of values in this tween.
---@return integer
function Tween:getValueCount() end

--- Returns true if the tween has finished.
---@return boolean
function Tween:isComplete() end

--- Resets the clock to 0.
---@return nil
function Tween:reset() end

--- Alias for setTime(). Sets the clock to t, clamped to [0, duration].
---@param t any
---@return nil
function Tween:set(t) end

--- Sets the clock to a specific time, clamped to [0, duration].
---@param t any
---@return nil
function Tween:setTime(t) end

--- Advances the clock by dt seconds. Returns true when complete.
---@param dt any
---@return boolean
function Tween:update(dt) end

--- Returns the absolute value of x.
---@param x any
---@return number
function lurek.math.abs(x) end

--- Returns the arccosine of x, in radians.
---@param x any
---@return number
function lurek.math.acos(x) end

--- Returns the angle in radians from (x1, y1) to (x2, y2).
---@param x1 any
---@param y1 any
---@param x2 any
---@param y2 any
---@return number
function lurek.math.angleBetween(x1, y1, x2, y2) end

--- Applies a named easing function to progress value t.
---@param name any
---@param t any
---@return number
function lurek.math.applyEasing(name, t) end

--- Returns the arcsine of x, in radians.
---@param x any
---@return number
function lurek.math.asin(x) end

--- Returns the arctangent of x (or atan2(y, x) when two args given).
---@param y any
---@param x? any (optional)
---@return number
function lurek.math.atan(y, x) end

--- Returns atan(y/x) using the signs of both args to determine the quadrant.
---@param y any
---@param x any
---@return number
function lurek.math.atan2(y, x) end

--- Rasterizes a line from (x1,y1) to (x2,y2) using Bresenham's algorithm. Returns a table of {x,y} tables.
---@param x1 any
---@param y1 any
---@param x2 any
---@param y2 any
---@return table
function lurek.math.bresenham(x1, y1, x2, y2) end

--- Returns the smallest integer ≥ x.
---@param x any
---@return number
function lurek.math.ceil(x) end

--- Returns true if the point (px, py) lies inside the circle.
---@param cx any
---@param cy any
---@param r any
---@param px any
---@param py any
---@return boolean
function lurek.math.circleContainsPoint(cx, cy, r, px, py) end

--- Returns true if two circles overlap.
---@param x1 any
---@param y1 any
---@param r1 any
---@param x2 any
---@param y2 any
---@param r2 any
---@return boolean
function lurek.math.circleIntersectsCircle(x1, y1, r1, x2, y2, r2) end

--- Tests an infinite line against a circle. Returns hit, then two optional hit-point pairs.
---@param cx any
---@param cy any
---@param r any
---@param lx1 any
---@param ly1 any
---@param lx2 any
---@param ly2 any
---@return boolean
function lurek.math.circleIntersectsLine(cx, cy, r, lx1, ly1, lx2, ly2) end

--- Tests a line segment against a circle. Returns hit, then two optional hit-point pairs.
---@param cx any
---@param cy any
---@param r any
---@param sx1 any
---@param sy1 any
---@param sx2 any
---@param sy2 any
---@return boolean
function lurek.math.circleIntersectsSegment(cx, cy, r, sx1, sy1, sx2, sy2) end

--- Returns x clamped to [lo, hi].
---@param x any
---@param lo any
---@param hi any
---@return number
function lurek.math.clamp(x, lo, hi) end

--- Returns the closest point on segment (x1,y1)-(x2,y2) to point (px,py).
---@param px any
---@param py any
---@param x1 any
---@param y1 any
---@param x2 any
---@param y2 any
---@return number
function lurek.math.closestPointOnSegment(px, py, x1, y1, x2, y2) end

--- Computes the convex hull of a flat {x1,y1,...} point list. Returns a flat table.
---@param pts any
---@return table
function lurek.math.convexHull(pts) end

--- Returns the cosine of x (radians).
---@param x any
---@return number
function lurek.math.cos(x) end

--- Converts radians to degrees.
---@param rad any
---@return number
function lurek.math.deg(rad) end

--- Delaunay triangulation of a flat {x1,y1,...} point list. Returns a table of flat 6-number triangle tables.
---@param pts any
---@return table
function lurek.math.delaunayTriangulate(pts) end

--- Returns the Euclidean distance between (x1,y1) and (x2,y2).
---@param x1 any
---@param y1 any
---@param x2 any
---@param y2 any
---@return number
function lurek.math.distance(x1, y1, x2, y2) end

--- Returns the squared Euclidean distance between (x1,y1) and (x2,y2) (avoids sqrt).
---@param x1 any
---@param y1 any
---@param x2 any
---@param y2 any
---@return number
function lurek.math.distanceSq(x1, y1, x2, y2) end

--- Returns e raised to the power x.
---@param x any
---@return number
function lurek.math.exp(x) end

--- Returns fractal Brownian motion noise at (x, y).
---@param x number
---@param y number
---@param seed? integer? (optional)
---@param octaves? integer? (optional)
---@param lacunarity? number? (optional)
---@param gain? number? (optional)
---@return number
function lurek.math.fbm(x, y, seed, octaves, lacunarity, gain) end

--- Returns the largest integer ≤ x.
---@param x any
---@return number
function lurek.math.floor(x) end

--- Returns the remainder of x / y (fmod).
---@param x any
---@param y any
---@return number
function lurek.math.fmod(x, y) end

--- Converts a gamma-encoded sRGB value to linear space.
---@param c any
---@return number
function lurek.math.gammaToLinear(c) end

--- Back ease-in — overshoots slightly before settling at the target.
---@param t any
---@return number
function lurek.math.inBack(t) end

--- Bounce ease-in.
---@param t any
---@return number
function lurek.math.inBounce(t) end

--- Cubic ease-in — acceleration starts slowly then increases sharply.
---@param t any
---@return number
function lurek.math.inCubic(t) end

--- Elastic ease-in.
---@param t any
---@return number
function lurek.math.inElastic(t) end

--- Exponential ease-in.
---@param t any
---@return number
function lurek.math.inExpo(t) end

--- Cubic ease-in-out.
---@param t any
---@return number
function lurek.math.inOutCubic(t) end

--- Exponential ease-in-out.
---@param t any
---@return number
function lurek.math.inOutExpo(t) end

--- Quadratic ease-in-out.
---@param t any
---@return number
function lurek.math.inOutQuad(t) end

--- Quartic ease-in-out.
---@param t any
---@return number
function lurek.math.inOutQuart(t) end

--- Sinusoidal ease-in-out.
---@param t any
---@return number
function lurek.math.inOutSine(t) end

--- Quadratic ease-in.
---@param t any
---@return number
function lurek.math.inQuad(t) end

--- Quartic ease-in.
---@param t any
---@return number
function lurek.math.inQuart(t) end

--- Sinusoidal ease-in.
---@param t any
---@return number
function lurek.math.inSine(t) end

--- Returns true if the polygon (flat table {x1,y1,...}) is convex.
---@param pts any
---@return boolean
function lurek.math.isConvex(pts) end

--- Linear interpolation between a and b by fraction t.
---@param a any
---@param b any
---@param t any
---@return number
function lurek.math.lerp(a, b, t) end

--- Infinite line intersection. Returns (x, y) or (nil, nil) if lines are parallel.
---@param x1 any
---@param y1 any
---@param x2 any
---@param y2 any
---@param x3 any
---@param y3 any
---@param x4 any
---@param y4 any
---@return number?
function lurek.math.lineIntersect(x1, y1, x2, y2, x3, y3, x4, y4) end

--- Linear easing (identity).
---@param t any
---@return number
function lurek.math.linear(t) end

--- Converts a linear-space value to gamma-encoded sRGB.
---@param c any
---@return number
function lurek.math.linearToGamma(c) end

--- Returns the natural log of x, or log base b if b is supplied.
---@param x any
---@param b? any (optional)
---@return number
function lurek.math.log(x, b) end

--- Returns the largest of the supplied numbers.
---@return number
function lurek.math.max() end

--- Returns the smallest of the supplied numbers.
---@return number
function lurek.math.min() end

--- Creates a new BezierCurve from a flat table of coordinates {x1,y1, x2,y2, ...}.
---@param points any
---@return BezierCurve
function lurek.math.newBezierCurve(points) end

--- Creates a new seeded noise generator.
---@param seed? any (optional)
---@return NoiseGenerator
function lurek.math.newNoiseGenerator(seed) end

--- Creates a new random number generator with an optional seed.
---@param seed? any (optional)
---@return RandomGenerator
function lurek.math.newRandomGenerator(seed) end

--- Creates a new SpatialHash with the given cell size.
---@param cell_size any
---@return SpatialHash
function lurek.math.newSpatialHash(cell_size) end

--- Creates a new Transform, optionally initialised from full parameters.
---@param x? number? (optional)
---@param y? number? (optional)
---@param angle? number? (optional)
---@param sx? number? (optional)
---@param sy? number? (optional)
---@param ox? number? (optional)
---@param oy? number? (optional)
---@param kx? number? (optional)
---@param ky? number? (optional)
---@return Transform
function lurek.math.newTransform(x, y, angle, sx, sy, ox, oy, kx, ky) end

--- Creates a new Tween with the given duration and easing name.
---@param duration any
---@param easing_name? any (optional)
---@return Tween
function lurek.math.newTween(duration, easing_name) end

--- Back ease-out — overshoots the target then snaps back into place.
---@param t any
---@return number
function lurek.math.outBack(t) end

--- Bounce ease-out.
---@param t any
---@return number
function lurek.math.outBounce(t) end

--- Cubic ease-out.
---@param t any
---@return number
function lurek.math.outCubic(t) end

--- Elastic ease-out.
---@param t any
---@return number
function lurek.math.outElastic(t) end

--- Exponential ease-out.
---@param t any
---@return number
function lurek.math.outExpo(t) end

--- Quadratic ease-out.
---@param t any
---@return number
function lurek.math.outQuad(t) end

--- Quartic ease-out.
---@param t any
---@return number
function lurek.math.outQuart(t) end

--- Sinusoidal ease-out.
---@param t any
---@return number
function lurek.math.outSine(t) end

--- Returns 2D Perlin noise at (x, y) with the given seed.
---@param x any
---@param y any
---@param seed? any (optional)
---@return number
function lurek.math.perlin2d(x, y, seed) end

--- Returns 3D Perlin noise at (x, y, z) with the given seed.
---@param x any
---@param y any
---@param z any
---@param seed? any (optional)
---@return number
function lurek.math.perlin3d(x, y, z, seed) end

--- Returns true if (px, py) is inside the polygon given as a flat {x1,y1,...} table.
---@param pts any
---@param px any
---@param py any
---@return boolean
function lurek.math.pointInPolygon(pts, px, py) end

--- Returns the signed area of a polygon given as a flat {x1,y1,...} table.
---@param pts any
---@return number
function lurek.math.polygonArea(pts) end

--- Returns the centroid (cx, cy) of a polygon given as a flat {x1,y1,...} table.
---@param pts any
---@return number
function lurek.math.polygonCentroid(pts) end

--- Returns x raised to the power y.
---@param x any
---@param y any
---@return number
function lurek.math.pow(x, y) end

--- Converts degrees to radians.
---@param deg any
---@return number
function lurek.math.rad(deg) end

--- Returns a pseudo-random number in [0,1) with no args,
---@param a? any (optional)
---@param b? any (optional)
---@return number
function lurek.math.random(a, b) end

--- Returns a pseudo-random integer in [lo, hi] (inclusive).
---@param lo any
---@param hi any
---@return integer
function lurek.math.randomInt(lo, hi) end

--- Returns x rounded to the nearest integer (half-up).
---@param x any
---@return number
function lurek.math.round(x) end

--- Tests if two line segments intersect. Returns (hit, ix?, iy?).
---@param x1 any
---@param y1 any
---@param x2 any
---@param y2 any
---@param x3 any
---@param y3 any
---@param x4 any
---@param y4 any
---@return boolean
function lurek.math.segmentIntersectsSegment(x1, y1, x2, y2, x3, y3, x4, y4) end

--- Returns -1, 0, or 1 depending on the sign of x.
---@param x any
---@return number
function lurek.math.sign(x) end

--- Returns 2D Simplex noise at (x, y) with the given seed.
---@param x any
---@param y any
---@param seed? any (optional)
---@return number
function lurek.math.simplex2d(x, y, seed) end

--- Returns a simplex noise value in [-1, 1] for 2D or 3D coordinates.
---@param x any
---@param y any
---@param z? any (optional)
---@return number
function lurek.math.simplexNoise(x, y, z) end

--- Returns the sine of x (radians).
---@param x any
---@return number
function lurek.math.sin(x) end

--- Returns the square root of x.
---@param x any
---@return number
function lurek.math.sqrt(x) end

--- Returns the tangent of x (radians).
---@param x any
---@return number
function lurek.math.tan(x) end

--- Triangulates a simple polygon given as a flat table {x1,y1, x2,y2, ...}.
---@param pts any
---@return table
function lurek.math.triangulate(pts) end

---@class lurek.minimap
lurek.minimap = {}

--- Lua-side wrapper around a [`Minimap`].
---@class Minimap
local Minimap = {}

--- Removes all tracked objects.
---@return nil
function Minimap:clearObjects() end

--- Clears the viewport rectangle overlay.
---@return nil
function Minimap:clearViewportRect() end

--- Returns the center coordinates as x, y.
---@return number
function Minimap:getCenter() end

--- Returns the center X coordinate.
---@return number
function Minimap:getCenterX() end

--- Returns the center Y coordinate.
---@return number
function Minimap:getCenterY() end

--- Returns the current color mode as a string.
---@return string
function Minimap:getColorMode() end

--- Returns the display height in pixels.
---@return integer
function Minimap:getDisplayHeight() end

--- Returns the display width and height as two values.
---@return integer
function Minimap:getDisplaySize() end

--- Returns the display width in pixels.
---@return integer
function Minimap:getDisplayWidth() end

--- Returns the fog overlay color as r, g, b, a.
---@return number
function Minimap:getFogColor() end

--- Returns the fog level at a 1-based grid position (0=hidden, 1=explored, 2=visible).
---@param x any
---@param y any
---@return integer
function Minimap:getFogLevel(x, y) end

--- Returns the grid height in cells.
---@return integer
function Minimap:getGridHeight() end

--- Returns the grid width and height as two values.
---@return integer
function Minimap:getGridSize() end

--- Returns the grid width in cells.
---@return integer
function Minimap:getGridWidth() end

--- Returns the number of markers.
---@return integer
function Minimap:getMarkerCount() end

--- Returns the description of a marker, or nil.
---@param id any
---@return string?
function Minimap:getMarkerDescription(id) end

--- Returns the number of tracked objects.
---@return integer
function Minimap:getObjectCount() end

--- Returns the number of registered object types.
---@return integer
function Minimap:getObjectTypeCount() end

--- Returns the display color for an owner/faction as r, g, b, a.
---@param owner any
---@return number
function Minimap:getOwnerColor(owner) end

--- Returns the number of active pings.
---@return integer
function Minimap:getPingCount() end

--- Returns the terrain type at a 1-based grid position.
---@param x any
---@param y any
---@return integer
function Minimap:getTerrain(x, y) end

--- Returns the display color for a terrain type as r, g, b, a.
---@param terrain_type any
---@return number
function Minimap:getTerrainColor(terrain_type) end

--- Returns the hover tooltip string for a terrain type ID, or nil.
---@param type_id any
---@return string?
function Minimap:getTileDescription(type_id) end

--- Returns the viewport rectangle color as r, g, b, a.
---@return number
function Minimap:getViewportColor() end

--- Returns the viewport rectangle as x, y, w, h or nil if not set.
---@return number?
function Minimap:getViewportRect() end

--- Returns the current zoom level.
---@return number
function Minimap:getZoom() end

--- Returns whether a marker with the given ID exists.
---@param id any
---@return boolean
function Minimap:hasMarker(id) end

--- Returns whether anti-aliasing is enabled.
---@return boolean
function Minimap:isAntiAlias() end

--- Returns whether this minimap responds to click hit-testing.
---@return boolean
function Minimap:isClickable() end

--- Returns whether fog of war is enabled.
---@return boolean
function Minimap:isFogEnabled() end

--- Returns whether an object type (1-based index) is visible.
---@param type_idx any
---@return boolean
function Minimap:isObjectTypeVisible(type_idx) end

--- Returns whether the viewport rectangle is visible.
---@return boolean
function Minimap:isViewportVisible() end

--- Removes a marker by ID.
---@param id any
---@return boolean
function Minimap:removeMarker(id) end

--- Removes a tracked object by ID.
---@param id any
---@return boolean
function Minimap:removeObject(id) end

--- Sets whether anti-aliasing is enabled.
---@param enabled any
---@return nil
function Minimap:setAntiAlias(enabled) end

--- Sets the center of the minimap view in grid coordinates.
---@param x any
---@param y any
---@return nil
function Minimap:setCenter(x, y) end

--- Sets whether this minimap responds to click hit-testing.
---@param enabled any
---@return nil
function Minimap:setClickable(enabled) end

--- Sets the color mode ("terrain" or "political").
---@param mode any
---@return nil
function Minimap:setColorMode(mode) end

--- Sets the display size in pixels.
---@param w any
---@param h any
---@return nil
function Minimap:setDisplaySize(w, h) end

--- Sets the entire fog grid from a flat 1-based table (0=hidden, 1=explored, 2=visible).
---@param data any
---@return nil
function Minimap:setFogData(data) end

--- Enables or disables fog of war.
---@param enabled any
---@return nil
function Minimap:setFogEnabled(enabled) end

--- Sets the fog level at a 1-based grid position (0=hidden, 1=explored, 2=visible).
---@param x any
---@param y any
---@param level any
---@return nil
function Minimap:setFogLevel(x, y, level) end

--- Sets terrain types from a flat 1-based Lua table of integers (row-major).
---@param data any
---@return nil
function Minimap:setTerrainData(data) end

--- Sets whether the viewport rectangle is visible.
---@param visible any
---@return nil
function Minimap:setViewportVisible(visible) end

--- Sets the zoom level (minimum 0.1).
---@param zoom any
---@return nil
function Minimap:setZoom(zoom) end

--- Returns the type name of this object.
---@return string
function Minimap:type() end

--- Returns true if this object is of the given type.
---@param name any
---@return boolean
function Minimap:typeOf(name) end

--- Advances time-based effects by dt seconds (expires pings).
---@param dt any
---@return nil
function Minimap:update(dt) end

--- Creates a new grid-based minimap.
---@param grid_w any
---@param grid_h any
---@param display_w? any (optional)
---@param display_h? any (optional)
---@return Minimap
function lurek.minimap.newMinimap(grid_w, grid_h, display_w, display_h) end

---@class lurek.modding
lurek.modding = {}

--- Lua-side wrapper around [`ModInfo`] with per-mod hook and config storage.
---@class Mod
local Mod = {}

--- Returns the author name.
---@return string
function Mod:getAuthor() end

--- Returns the stored config value, or nil.
---@return table?
function Mod:getConfig() end

--- Returns the list of required mod IDs.
---@return table
function Mod:getDependencies() end

--- Returns the mod description.
---@return string
function Mod:getDescription() end

--- Returns the hook function for the given name, or nil.
---@param name any
---@return function?
function Mod:getHook(name) end

--- Returns an array of registered hook names.
---@return table
function Mod:getHookNames() end

--- Returns the unique mod identifier.
---@return string
function Mod:getId() end

--- Returns the display name.
---@return string
function Mod:getName() end

--- Returns the load-order priority.
---@return integer
function Mod:getPriority() end

--- Returns the version string.
---@return string
function Mod:getVersion() end

--- Returns whether a hook with the given name exists.
---@param name any
---@return boolean
function Mod:hasHook(name) end

--- Returns whether the mod is enabled.
---@return boolean
function Mod:isEnabled() end

--- Returns whether the mod has been loaded.
---@return boolean
function Mod:isLoaded() end

--- Releases all hook and config registry references.
---@return nil
function Mod:releaseRefs() end

--- Stores an arbitrary config value for this mod.
---@param value any
---@return nil
function Mod:setConfig(value) end

--- Sets the enabled state.
---@param enabled any
---@return nil
function Mod:setEnabled(enabled) end

--- Lua-side wrapper around [`ModManager`].
---@class ModManager
local ModManager = {}

--- Clears the custom load order, reverting to priority-based sorting.
---@return nil
function ModManager:clearLoadOrder() end

--- Clears the reload queue without reloading.
---@return nil
function ModManager:clearReloadQueue() end

--- Returns an array of info tables for all registered mods.
---@return table
function ModManager:getAllMods() end

--- Returns an array of info tables in effective load order.
---@return table
function ModManager:getLoadOrder() end

--- Returns the number of registered mods.
---@return integer
function ModManager:getModCount() end

--- Returns the filesystem path of a registered mod, or nil.
---@param mod_id any
---@return string?
function ModManager:getModPath(mod_id) end

--- Returns the array of mod IDs pending hot-reload.
---@return table
function ModManager:getReloadQueue() end

--- Returns whether any circular dependency cycles exist.
---@return boolean
function ModManager:hasCircularDependencies() end

--- Returns whether a mod with the given ID is registered.
---@param mod_id any
---@return boolean
function ModManager:hasMod(mod_id) end

--- Marks a registered mod for hot-reload.
---@param mod_id any
---@return boolean
function ModManager:markForReload(mod_id) end

--- Registers a mod from its Mod userdata.
---@param ud any
---@return nil
function ModManager:registerMod(ud) end

--- Scans a directory for mods with mod.toml and registers them.
---@param path any
---@return table
function ModManager:scanFolder(path) end

--- Sets an explicit load order from an array of mod ID strings.
---@param order_table any
---@return nil
function ModManager:setLoadOrder(order_table) end

--- Removes a mod by ID and returns whether it was found.
---@param mod_id any
---@return boolean
function ModManager:unregisterMod(mod_id) end

--- Returns an array of mod IDs with missing dependencies.
---@return table
function ModManager:validateDependencies() end

--- Creates a new Mod from an info table with at least an `id` field.
---@param info any
---@return Mod
function lurek.modding.newMod(info) end

--- Creates a new empty ModManager.
---@return ModManager
function lurek.modding.newModManager() end

---@class lurek.network
lurek.network = {}

--- Lua-side wrapper around [`NetworkHost`].
---@class NetworkHost
local NetworkHost = {}

--- Destroys the host, closing the underlying socket.
---@return nil
function NetworkHost:destroy() end

--- Gracefully disconnects a peer.
---@param peer_id any
---@param data? any (optional)
---@return nil
function NetworkHost:disconnect(peer_id, data) end

--- Immediately disconnects a peer without handshake.
---@param peer_id any
---@param data? any (optional)
---@return nil
function NetworkHost:disconnectNow(peer_id, data) end

--- Flushes all pending sends immediately.
---@return nil
function NetworkHost:flush() end

--- Returns the local bind address as a string.
---@return string
function NetworkHost:getAddress() end

--- Returns the bandwidth limits as a table with incoming and outgoing fields.
---@return table
function NetworkHost:getBandwidthLimit() end

--- Returns the maximum number of channels per connection.
---@return integer
function NetworkHost:getChannelLimit() end

--- Returns the number of currently connected peers.
---@return integer
function NetworkHost:getConnectedPeerCount() end

--- Returns a table of connected peer IDs.
---@return table
function NetworkHost:getConnectedPeerIds() end

--- Returns the remote address of a peer, or nil if unavailable.
---@param peer_id any
---@return string?
function NetworkHost:getPeerAddress(peer_id) end

--- Returns the maximum number of peer slots.
---@return integer
function NetworkHost:getPeerLimit() end

--- Returns the connection state of a peer as a string.
---@param peer_id any
---@return string
function NetworkHost:getPeerState(peer_id) end

--- Returns a statistics table for a peer.
---@param peer_id any
---@return table
function NetworkHost:getPeerStats(peer_id) end

--- Returns the round-trip time estimate for a peer in milliseconds.
---@param peer_id any
---@return number
function NetworkHost:getRoundTripTime(peer_id) end

--- Returns true if the host has been destroyed.
---@return boolean
function NetworkHost:isDestroyed() end

--- Sends a ping to a peer to measure round-trip time.
---@param peer_id any
---@return nil
function NetworkHost:ping(peer_id) end

--- Resets a peer connection immediately without notifying the remote side.
---@param peer_id any
---@return nil
function NetworkHost:resetPeer(peer_id) end

--- Polls the network for one event, returning an event table or nil.
---@return table?
function NetworkHost:service() end

--- Sets the channel limit for future connections.
---@param limit any
---@return nil
function NetworkHost:setChannelLimit(limit) end

--- Creates a new network host bound to the given address.
---@param opts any
---@return NetworkHost
function lurek.network.newHost(opts) end

---@class lurek.parallax
lurek.parallax = {}

--- Lua-side handle to a single parallax background layer.
---@class ParallaxLayer
local ParallaxLayer = {}

--- Removes scroll clamping so the layer scrolls freely.
function ParallaxLayer:clearClamp() end

--- Returns the autoscroll velocity as `(vx, vy)`.
---@return number
function ParallaxLayer:getAutoscroll() end

--- Returns the current blend mode as a string.
---@return string
function ParallaxLayer:getBlendMode() end

--- Returns the static offset as `(x, y)`.
---@return number
function ParallaxLayer:getOffset() end

--- Returns the current opacity.
---@return number
function ParallaxLayer:getOpacity() end

--- Returns the scroll factor as `(x, y)`.
---@return number
function ParallaxLayer:getScrollFactor() end

--- Returns the current tint as `(r, g, b, a)`.
---@return number
function ParallaxLayer:getTint() end

--- Returns the draw-order depth.
---@return integer
function ParallaxLayer:getZ() end

--- Returns `true` if the layer is currently visible.
---@return boolean
function ParallaxLayer:isVisible() end

--- Draws the layer using an explicit camera world position.
---@param cam_x any
---@param cam_y any
function ParallaxLayer:render(cam_x, cam_y) end

--- Draws the layer using the engine active camera position automatically.
function ParallaxLayer:renderAuto() end

--- Resets the autonomous scroll accumulator to zero.
function ParallaxLayer:resetAutoscroll() end

--- Sets the autonomous scroll velocity in world-pixels per second.
---@param vx any
---@param vy any
function ParallaxLayer:setAutoscroll(vx, vy) end

--- Sets the GPU blend mode for this layer.
---@param mode any
function ParallaxLayer:setBlendMode(mode) end

--- Sets the static world-pixel position bias added on top of camera scroll.
---@param x any
---@param y any
function ParallaxLayer:setOffset(x, y) end

--- Sets the layer-wide opacity override in `[0.0, 1.0]`.
---@param a any
function ParallaxLayer:setOpacity(a) end

--- Sets whether the layer tiles on the X and Y axes.
---@param rx any
---@param ry any
function ParallaxLayer:setRepeat(rx, ry) end

--- Sets the texture display scale factor on each axis.
---@param sx any
---@param sy any
function ParallaxLayer:setScale(sx, sy) end

--- Sets the scroll factor relative to camera movement on each axis.
---@param x any
---@param y any
function ParallaxLayer:setScrollFactor(x, y) end

--- Sets the multiplicative RGBA tint applied to all pixels of this layer.
---@param r any
---@param g any
---@param b any
---@param a any
function ParallaxLayer:setTint(r, g, b, a) end

--- Shows or hides this layer.
---@param v any
function ParallaxLayer:setVisible(v) end

--- Sets the draw-order depth. Lower values render first (further back).
---@param z any
function ParallaxLayer:setZ(z) end

--- Returns the type name of this object.
---@return string
function ParallaxLayer:type() end

--- Advances the autonomous scroll accumulator by `dt` seconds.
---@param dt any
function ParallaxLayer:update(dt) end

--- Lua-side container that groups `LuaParallaxLayer` objects for scene-level management.
---@class ParallaxSet
local ParallaxSet = {}

--- Adds a layer to this set.
---@param layer any
function ParallaxSet:addLayer(layer) end

--- Returns the name of this set.
---@return string
function ParallaxSet:getName() end

--- Returns `true` if the set is currently visible.
---@return boolean
function ParallaxSet:isVisible() end

--- Returns the number of layers in this set.
---@return integer
function ParallaxSet:layerCount() end

--- Removes the layer at the given 1-based index.
---@param index any
---@return boolean
function ParallaxSet:removeLayerAt(index) end

--- Draws all visible layers in ascending `z` order using an explicit camera position.
---@param cam_x any
---@param cam_y any
function ParallaxSet:render(cam_x, cam_y) end

--- Draws all visible layers using the engine active camera position.
function ParallaxSet:renderAuto() end

--- Sets the name of this set.
---@param name any
function ParallaxSet:setName(name) end

--- Shows or hides all layers in this set.
---@param v any
function ParallaxSet:setVisible(v) end

--- Re-sorts all layers by ascending `z` value.
function ParallaxSet:sortByZ() end

--- Returns the type name of this object.
---@return string
function ParallaxSet:type() end

--- Advances the autoscroll accumulator of every layer by `dt` seconds.
---@param dt any
function ParallaxSet:update(dt) end

--- Creates a new parallax background layer from an options table.
---@param opts any
---@return LuaParallaxLayer
function lurek.parallax.newLayer(opts) end

--- Creates a new empty parallax set with the given name.
---@param name any
---@return LuaParallaxSet
function lurek.parallax.newSet(name) end

---@class lurek.particle
lurek.particle = {}

--- Lua-side handle to a particle system stored in SharedState.
---@class ParticleSystem
local ParticleSystem = {}

--- Creates a copy of this particle system (config only, no live particles).
---@return ParticleSystem
function ParticleSystem:clone() end

--- Returns the number of living particles.
---@return integer
function ParticleSystem:count() end

--- Emits a burst of the given number of particles.
---@param count any
---@return nil
function ParticleSystem:emit(count) end

--- Returns the maximum particle count.
---@return integer
function ParticleSystem:getBufferSize() end

--- Returns color keyframes as a table of {r,g,b,a} tables.
---@return table
function ParticleSystem:getColors() end

--- Returns the number of living particles (alias for count).
---@return integer
function ParticleSystem:getCount() end

--- Returns emission direction in radians.
---@return number
function ParticleSystem:getDirection() end

--- Returns emission area: dist-string, w, h.
---@return string
function ParticleSystem:getEmissionArea() end

--- Returns particles emitted per second.
---@return number
function ParticleSystem:getEmissionRate() end

--- Returns the emitter lifetime.
---@return number
function ParticleSystem:getEmitterLifetime() end

--- Returns gravity (x, y).
---@return number
function ParticleSystem:getGravity() end

--- Returns the insert mode as a string.
---@return string
function ParticleSystem:getInsertMode() end

--- Returns linear acceleration range.
---@return number
function ParticleSystem:getLinearAcceleration() end

--- Returns linear damping range.
---@return number
function ParticleSystem:getLinearDamping() end

--- Returns the render origin offset.
---@return number
function ParticleSystem:getOffset() end

--- Returns min and max particle lifetime.
---@return number
function ParticleSystem:getParticleLifetime() end

--- Returns the emitter world position.
---@return number
function ParticleSystem:getPosition() end

--- Returns radial acceleration range.
---@return number
function ParticleSystem:getRadialAcceleration() end

--- Returns initial rotation range.
---@return number
function ParticleSystem:getRotation() end

--- Returns the particle draw shape as a string.
---@return string
function ParticleSystem:getShape() end

--- Returns size variation.
---@return number
function ParticleSystem:getSizeVariation() end

--- Returns size keyframes as a Lua table.
---@return table
function ParticleSystem:getSizes() end

--- Returns min/max initial speed.
---@return number
function ParticleSystem:getSpeed() end

--- Returns angular velocity range.
---@return number
function ParticleSystem:getSpin() end

--- Returns spin variation.
---@return number
function ParticleSystem:getSpinVariation() end

--- Returns emission spread.
---@return number
function ParticleSystem:getSpread() end

--- Returns tangential acceleration range.
---@return number
function ParticleSystem:getTangentialAcceleration() end

--- Returns whether relative rotation is enabled.
---@return boolean
function ParticleSystem:hasRelativeRotation() end

--- Returns true if the emitter is currently emitting or has live particles.
---@return boolean
function ParticleSystem:isActive() end

--- Returns true if there are no live particles.
---@return boolean
function ParticleSystem:isEmpty() end

--- Returns true if the system has reached max_particles.
---@return boolean
function ParticleSystem:isFull() end

--- Returns true if the emitter is paused.
---@return boolean
function ParticleSystem:isPaused() end

--- Returns true if the emitter is stopped.
---@return boolean
function ParticleSystem:isStopped() end

--- Moves the emitter to the given world position.
---@param x any
---@param y any
---@return nil
function ParticleSystem:moveTo(x, y) end

--- Pauses the emitter.
---@return nil
function ParticleSystem:pause() end

--- Removes the particle system from the engine, freeing its slot.
---@return nil
function ParticleSystem:release() end

--- Removes all particles and resets the emitter.
---@return nil
function ParticleSystem:reset() end

--- Resumes a paused emitter.
---@return nil
function ParticleSystem:resume() end

--- Sets the maximum number of particles (resizes the pool).
---@param n any
function ParticleSystem:setBufferSize(n) end

--- Sets color keyframes. Each arg is a table {r, g, b, a}.
---@param colors any
function ParticleSystem:setColors(colors) end

--- Sets emission direction in radians.
---@param dir any
function ParticleSystem:setDirection(dir) end

--- Sets emission area distribution and size.
---@param dist any
---@param w any
---@param h any
---@param angle? any (optional)
---@param dir_rel? any (optional)
function ParticleSystem:setEmissionArea(dist, w, h, angle, dir_rel) end

--- Sets particles emitted per second.
---@param rate any
function ParticleSystem:setEmissionRate(rate) end

--- Sets how long the emitter runs before auto-stopping. Negative = infinite.
---@param t any
function ParticleSystem:setEmitterLifetime(t) end

--- Sets gravity (x, y).
---@param gx any
---@param gy any
function ParticleSystem:setGravity(gx, gy) end

--- Sets the insert mode: "top", "bottom", or "random".
---@param mode any
function ParticleSystem:setInsertMode(mode) end

--- Sets linear acceleration range.
---@param xmin any
---@param ymin any
---@param xmax any
---@param ymax any
function ParticleSystem:setLinearAcceleration(xmin, ymin, xmax, ymax) end

--- Sets linear damping range.
---@param min any
---@param max any
function ParticleSystem:setLinearDamping(min, max) end

--- Sets the render origin offset.
---@param ox any
---@param oy any
function ParticleSystem:setOffset(ox, oy) end

--- Sets min and max particle lifetime in seconds.
---@param min any
---@param max any
function ParticleSystem:setParticleLifetime(min, max) end

--- Sets the emitter world position.
---@param x any
---@param y any
function ParticleSystem:setPosition(x, y) end

--- Sets radial acceleration range.
---@param min any
---@param max any
function ParticleSystem:setRadialAcceleration(min, max) end

--- Sets whether particle rotation follows velocity direction.
---@param v any
function ParticleSystem:setRelativeRotation(v) end

--- Sets initial rotation range in radians.
---@param min any
---@param max any
function ParticleSystem:setRotation(min, max) end

--- Sets the particle draw shape.
---@param shape any
function ParticleSystem:setShape(shape) end

--- Sets size variation (0–1).
---@param v any
function ParticleSystem:setSizeVariation(v) end

--- Sets size keyframes (varargs: each number is one keyframe).
---@param sizes any
function ParticleSystem:setSizes(sizes) end

--- Sets min/max initial speed.
---@param min any
---@param max any
function ParticleSystem:setSpeed(min, max) end

--- Sets angular velocity range.
---@param min any
---@param max any
function ParticleSystem:setSpin(min, max) end

--- Sets spin variation (0–1).
---@param v any
function ParticleSystem:setSpinVariation(v) end

--- Sets emission spread (half-angle cone) in radians.
---@param spread any
function ParticleSystem:setSpread(spread) end

--- Sets tangential acceleration range.
---@param min any
---@param max any
function ParticleSystem:setTangentialAcceleration(min, max) end

--- Starts or restarts particle emission.
---@return nil
function ParticleSystem:start() end

--- Stops particle emission immediately.
---@return nil
function ParticleSystem:stop() end

--- Returns the type name "ParticleSystem".
---@return string
function ParticleSystem:type() end

--- Returns true if this matches the given type name.
---@param name any
---@return boolean
function ParticleSystem:typeOf(name) end

--- Advances the particle simulation by dt seconds.
---@param dt any
---@return nil
function ParticleSystem:update(dt) end

--- Lua-side wrapper around a [`Trail`] ribbon effect.
---@class Trail
local Trail = {}

--- Removes all trail points.
---@return nil
function Trail:clear() end

--- Returns the trail point lifetime in seconds.
---@return number
function Trail:getLifetime() end

--- Returns the number of active trail points.
---@return integer
function Trail:getPointCount() end

--- Returns the start and end width.
---@return number
function Trail:getWidth() end

--- Appends a new point to the trail head.
---@param x any
---@param y any
---@return nil
function Trail:pushPoint(x, y) end

--- Sets how long each trail point persists in seconds.
---@param lifetime any
---@return nil
function Trail:setLifetime(lifetime) end

--- Sets the minimum distance between trail points.
---@param distance any
---@return nil
function Trail:setMinDistance(distance) end

--- Sets the start and end width of the trail ribbon.
---@param start any
---@param end? any (optional)
---@return nil
function Trail:setWidth(start, end) end

--- Ages trail points and removes expired ones.
---@param dt any
---@return nil
function Trail:update(dt) end

--- Creates a new particle system and stores it in the engine pool.
---@param config? any (optional)
---@return ParticleSystem
function lurek.particle.newSystem(config) end

--- Creates a new trail ribbon effect.
---@param lifetime any
---@param start_width any
---@return Trail
function lurek.particle.newTrail(lifetime, start_width) end

---@class lurek.pathfinding
lurek.pathfinding = {}

--- Lua-side wrapper around a PathGrid-based [`AiFlowField`].
---@class AiFlowField
local AiFlowField = {}

--- Returns the normalised direction toward the goal (1-based coordinates).
---@param x any
---@param y any
---@return number
function AiFlowField:getDirection(x, y) end

--- Returns the BFS distance to the goal (1-based coordinates).
---@param x any
---@param y any
---@return number
function AiFlowField:getDistance(x, y) end

--- Returns the grid height.
---@return integer
function AiFlowField:getHeight() end

--- Returns the grid width.
---@return integer
function AiFlowField:getWidth() end

--- Returns true if a goal has been set.
---@return boolean
function AiFlowField:hasGoal() end

--- Sets the goal cell and triggers BFS recomputation (1-based coordinates).
---@param x any
---@param y any
---@return nil
function AiFlowField:setGoal(x, y) end

--- Returns the type name of this object.
---@return string
function AiFlowField:type() end

--- Returns true if this object is of the given type.
---@param name any
---@return boolean
function AiFlowField:typeOf(name) end

--- Lua-side wrapper around a [`FlowField`].
---@class FlowField
local FlowField = {}

--- Returns the integrated cost to the nearest target (1-based coordinates).
---@param x any
---@param y any
---@return number
function FlowField:getCostToTarget(x, y) end

--- Returns the normalised direction vector at a cell (1-based coordinates).
---@param x any
---@param y any
---@return number
function FlowField:getDirection(x, y) end

--- Returns the flow direction as an angle in radians (1-based coordinates).
---@param x any
---@param y any
---@return number
function FlowField:getDirectionAngle(x, y) end

--- Returns the target cells from the most recent computation (1-based coordinates).
---@return table
function FlowField:getTargets() end

--- Returns true if the flow field has been computed at least once.
---@return boolean
function FlowField:isCalculated() end

--- Returns the type name of this object.
---@return string
function FlowField:type() end

--- Returns true if this object is of the given type.
---@param name any
---@return boolean
function FlowField:typeOf(name) end

--- Lua-side wrapper around a [`NavGrid`] with optional HPA★ abstract graph.
---@class NavGrid
local NavGrid = {}

--- Clears all pending dirty rectangles.
---@return nil
function NavGrid:clearDirty() end

--- Sets every cell to the given cost.
---@param cost any
---@return nil
function NavGrid:fill(cost) end

--- Returns the current HPA★ chunk size.
---@return integer
function NavGrid:getChunkSize() end

--- Returns the traversal cost of a cell (1-based coordinates).
---@param x any
---@param y any
---@return integer
function NavGrid:getCost(x, y) end

--- Returns the current diagonal movement mode as a string.
---@return string
function NavGrid:getDiagonalMode() end

--- Returns the grid dimensions as width, height.
---@return integer
function NavGrid:getDimensions() end

--- Returns the grid height in cells.
---@return integer
function NavGrid:getHeight() end

--- Returns the grid width in cells.
---@return integer
function NavGrid:getWidth() end

--- Returns true if the cell is blocked (1-based coordinates).
---@param x any
---@param y any
---@return boolean
function NavGrid:isBlocked(x, y) end

--- Overwrites the grid from a raw byte string (row-major, one byte per cell).
---@param data any
---@return nil
function NavGrid:loadFromString(data) end

--- Rebuilds the HPA★ abstract graph from the current grid state.
---@return nil
function NavGrid:rebuildAbstract() end

--- Exports the cost grid as a byte string (row-major, one byte per cell).
---@return string
function NavGrid:saveToString() end

--- Sets the HPA★ chunk size.
---@param size any
---@return nil
function NavGrid:setChunkSize(size) end

--- Sets the traversal cost of a cell (1-based coordinates).
---@param x any
---@param y any
---@param cost any
---@return nil
function NavGrid:setCost(x, y, cost) end

--- Sets the diagonal movement mode.
---@param mode any
---@return nil
function NavGrid:setDiagonalMode(mode) end

--- Records a dirty rectangle for incremental HPA★ updates (1-based coordinates).
---@param x any
---@param y any
---@param w any
---@param h any
---@return nil
function NavGrid:setDirty(x, y, w, h) end

--- Returns the type name of this object.
---@return string
function NavGrid:type() end

--- Returns true if this object is of the given type.
---@param name any
---@return boolean
function NavGrid:typeOf(name) end

--- Lua-side wrapper around a [`PathGrid`] (A★ weighted grid with per-cell cost).
---@class PathGrid
local PathGrid = {}

--- Returns the world-space size of each cell.
---@return number
function PathGrid:getCellSize() end

--- Returns the cost multiplier for a cell (1-based coordinates).
---@param x any
---@param y any
---@return number
function PathGrid:getCost(x, y) end

--- Returns the grid height in cells.
---@return integer
function PathGrid:getHeight() end

--- Returns the grid width in cells.
---@return integer
function PathGrid:getWidth() end

--- Returns true if a cell is walkable (1-based coordinates).
---@param x any
---@param y any
---@return boolean
function PathGrid:isWalkable(x, y) end

--- Sets the cost multiplier for a cell (1-based coordinates).
---@param x any
---@param y any
---@param cost any
---@return nil
function PathGrid:setCost(x, y, cost) end

--- Sets the walkability of a cell (1-based coordinates).
---@param x any
---@param y any
---@param w any
---@return nil
function PathGrid:setWalkable(x, y, w) end

--- Returns the type name of this object.
---@return string
function PathGrid:type() end

--- Returns true if this object is of the given type.
---@param name any
---@return boolean
function PathGrid:typeOf(name) end

--- Lua-side wrapper around a [`UnitPathfinder`].
---@class UnitPathfinder
local UnitPathfinder = {}

--- Removes all cached path results.
---@return nil
function UnitPathfinder:clearCache() end

--- Returns the number of entries in the path cache.
---@return integer
function UnitPathfinder:getCacheSize() end

--- Returns the sum of grid traversal costs along a path.
---@param path any
---@return number
function UnitPathfinder:getPathCost(path) end

--- Returns the euclidean length of a path table.
---@param path any
---@return number
function UnitPathfinder:getPathLength(path) end

--- Returns true if path result caching is enabled.
---@return boolean
function UnitPathfinder:isCacheEnabled() end

--- Enables or disables path result caching.
---@param enabled any
---@return nil
function UnitPathfinder:setCacheEnabled(enabled) end

--- Sets the maximum number of cached path entries.
---@param n any
---@return nil
function UnitPathfinder:setCacheMaxSize(n) end

--- Returns the type name of this object.
---@return string
function UnitPathfinder:type() end

--- Returns true if this object is of the given type.
---@param name any
---@return boolean
function UnitPathfinder:typeOf(name) end

--- Returns the background pathfinding thread count (currently always 0).
---@return integer
function lurek.pathfinding.getThreadCount() end

--- Creates a new FlowField backed by a NavGrid.
---@param grid_ud any
---@return FlowField
function lurek.pathfinding.newFlowField(grid_ud) end

--- Creates a new NavGrid with all cells walkable.
---@param width any
---@param height any
---@return NavGrid
function lurek.pathfinding.newNavGrid(width, height) end

--- Builds a NavGrid from a TileMap layer, treating specified GIDs as blocked (unwalkable).
---@param tm_ud any
---@param layer_index any
---@param blocked_table any
---@return NavGrid
function lurek.pathfinding.newNavGridFromTileMap(tm_ud, layer_index, blocked_table) end

--- Creates a new BFS flow field from a PathGrid.
---@param grid_ud any
---@return AiFlowField
function lurek.pathfinding.newPathFlowField(grid_ud) end

--- Creates a new PathGrid with per-cell cost and walkability.
---@param w any
---@param h any
---@param cell_size any
---@return PathGrid
function lurek.pathfinding.newPathGrid(w, h, cell_size) end

--- Creates a new UnitPathfinder backed by a NavGrid.
---@param grid_ud any
---@return UnitPathfinder
function lurek.pathfinding.newPathfinder(grid_ud) end

--- Sets the background pathfinding thread count (currently a no-op).
---@param count any
---@return nil
function lurek.pathfinding.setThreadCount(count) end

---@class lurek.patterns
lurek.patterns = {}

--- Lua wrapper for the Blackboard pattern.
---@class Blackboard
local Blackboard = {}

--- Removes a fact from the blackboard.
---@param key any
function Blackboard:clear(key) end

--- Clears all facts from the blackboard.
function Blackboard:clearAll() end

--- Gets a fact from the blackboard. Returns nil if not set.
---@param key any
---@return any
function Blackboard:get(key) end

--- Returns the monotonic revision counter (incremented on every write).
---@return integer
function Blackboard:getRevision() end

--- Returns true when the key has a non-nil value.
---@param key any
---@return boolean
function Blackboard:has(key) end

--- Returns all set fact keys as a table.
---@return table
function Blackboard:keys() end

--- Sets a fact on the blackboard. Accepts boolean, number, or string values.
---@param key any
---@param value any
function Blackboard:set(key, value) end

--- Returns all facts as a flat key→value table.
---@return table
function Blackboard:snapshot() end

--- Removes a watcher subscription by id.
---@param id any
function Blackboard:unwatch(id) end

--- Subscribes to changes on a specific key (or "*" for all changes).
---@param key any
---@param callback any
---@return integer
function Blackboard:watch(key, callback) end

--- Lua wrapper for the CommandStack pattern.
---@class CommandStack
local CommandStack = {}

--- Returns true if there is a command available to redo.
---@return boolean
function CommandStack:canRedo() end

--- Returns true if the most recent command can be undone.
---@return boolean
function CommandStack:canUndo() end

--- Clears all command history, releasing Lua registry values.
function CommandStack:clearAll() end

--- Executes a named command and records it in undo/redo history.
---@param name any
---@param exec_fn any
---@param undo_fn? any (optional)
function CommandStack:execute(name, exec_fn, undo_fn) end

--- Returns the name of the most recently executed command, or nil.
---@return string?
function CommandStack:getCurrentName() end

--- Returns the total number of recorded commands (undo + redo).
---@return integer
function CommandStack:getHistorySize() end

--- Re-executes the next undone command. Returns true if successful.
---@return boolean
function CommandStack:redo() end

--- Undoes the most recent command. Returns true if successful.
---@return boolean
function CommandStack:undo() end

--- Lua wrapper for the Debounce pattern.
---@class Debounce
local Debounce = {}

--- Cancels the pending trigger without firing.
function Debounce:cancel() end

--- Returns the total number of times this debounce has fired.
---@return integer
function Debounce:getFireCount() end

--- Returns true when a trigger is pending.
---@return boolean
function Debounce:isPending() end

--- Sets the callback invoked when the debounce fires.
---@param f any
function Debounce:onFire(f) end

--- Records an input event, resetting the idle timer.
function Debounce:trigger() end

--- Advances the idle timer by dt seconds; fires the callback if idle wait expired.
---@param dt any
---@return boolean
function Debounce:update(dt) end

--- Lua wrapper for the EventBus pattern.
---@class EventBus
local EventBus = {}

--- Removes all listeners for a specific event.
---@param event any
function EventBus:clear(event) end

--- Removes all listeners on this EventBus.
function EventBus:clearAll() end

--- Dispatches an event, calling all registered listeners in priority order.
---@param args any
function EventBus:emit(args) end

--- Returns all event names that have at least one listener.
---@return table
function EventBus:getEvents() end

--- Returns the number of listeners registered for an event.
---@param event any
---@return integer
function EventBus:getListenerCount(event) end

--- Removes a previously registered event listener by subscription ID.
---@param id any
function EventBus:off(id) end

--- Registers a listener callback for an event.
---@param event any
---@param callback any
---@param priority? any (optional)
---@return integer
function EventBus:on(event, callback, priority) end

--- Lua wrapper for the Factory pattern.
---@class Factory
local Factory = {}

--- Registers an alias pointing to an existing canonical type name.
---@param alias any
---@param canonical any
function Factory:alias(alias, canonical) end

--- Removes all registered type constructors and aliases.
function Factory:clearAll() end

--- Creates an instance of the named type by invoking its constructor.
---@param args any
---@return any
function Factory:create(args) end

--- Returns a table of all registered type names.
---@return table
function Factory:getTypes() end

--- Returns true if the named type (or alias) is registered.
---@param type_name any
---@return boolean
function Factory:has(type_name) end

--- Registers a named type constructor function.
---@param type_name any
---@param ctor any
function Factory:register(type_name, ctor) end

--- Unregisters a type constructor (and any aliases pointing to it).
---@param type_name any
function Factory:remove(type_name) end

--- Lua wrapper for the Funnel (event aggregator) pattern.
---@class Funnel
local Funnel = {}

--- Discards all buffered entries without flushing.
function Funnel:discard() end

--- Manually flushes all pending entries, invoking the onFlush callback.
function Funnel:flush() end

--- Returns the total number of flushes performed.
---@return integer
function Funnel:getFlushCount() end

--- Sets a callback invoked when the funnel flushes. Receives a table of {tag, value} entries.
---@param f any
function Funnel:onFlush(f) end

--- Returns the number of buffered entries not yet flushed.
---@return integer
function Funnel:pendingCount() end

--- Adds an event to the funnel. Immediately flushes if max_entries reached or window is 0.
---@param tag any
---@param value? any (optional)
function Funnel:push(tag, value) end

--- Advances the window timer by dt seconds; flushes when window expires.
---@param dt any
---@return boolean
function Funnel:update(dt) end

--- Lua wrapper for the ObjectPool pattern.
---@class ObjectPool
local ObjectPool = {}

--- Acquires an available object from the pool; returns nil if empty.
---@return any
function ObjectPool:acquire() end

--- Inserts a pre-built object into the available pool.
---@param value any
function ObjectPool:add(value) end

--- Clears all objects from the pool, releasing Lua registry values.
function ObjectPool:clearAll() end

--- Returns the number of currently active (acquired) objects.
---@return integer
function ObjectPool:getActiveCount() end

--- Returns the number of available (idle) objects in the pool.
---@return integer
function ObjectPool:getAvailableCount() end

--- Returns the total number of tracked objects (active + available).
---@return integer
function ObjectPool:getTotalCount() end

--- Returns an object to the available pool.
---@param value any
function ObjectPool:release(value) end

--- Lua wrapper for the Observer pattern.
---@class Observer
local Observer = {}

--- Gets a property value, or nil if not set.
---@param key any
---@return any
function Observer:get(key) end

--- Returns the total number of active subscriptions.
---@return integer
function Observer:getCount() end

--- Sets a property value and fires subscribed watchers.
---@param key any
---@param new_val any
function Observer:set(key, new_val) end

--- Subscribes to changes on a property key (or "*" for all).
---@param key any
---@param callback any
---@param once? any (optional)
---@return integer
function Observer:subscribe(key, callback, once) end

--- Removes a subscription by id.
---@param id any
function Observer:unsubscribe(id) end

--- Lua wrapper for the PriorityQueue pattern.
---@class PriorityQueue
local PriorityQueue = {}

--- Removes all items from the queue.
function PriorityQueue:clearAll() end

--- Returns true when the queue has no items.
---@return boolean
function PriorityQueue:isEmpty() end

--- Returns the number of items in the queue.
---@return integer
function PriorityQueue:len() end

--- Returns the highest-priority item without removing it, or nil if empty.
---@return any
function PriorityQueue:peek() end

--- Removes and returns the highest-priority item, or nil if empty.
---@return any
function PriorityQueue:pop() end

--- Inserts an item with a priority. Higher priorities are dequeued first.
---@param priority any
---@param value any
---@param label? any (optional)
---@return integer
function PriorityQueue:push(priority, value, label) end

--- Lua wrapper for the Ring (circular buffer) pattern.
---@class Ring
local Ring = {}

--- Returns the average of all numeric values, or 0 if empty.
---@return number
function Ring:average() end

--- Removes all entries from the ring.
function Ring:clear() end

--- Returns true when the ring is at capacity.
---@return boolean
function Ring:isFull() end

--- Returns the most recently pushed entry, or nil.
---@return table?
function Ring:latest() end

--- Returns the number of entries currently in the ring.
---@return integer
function Ring:len() end

--- Pushes a value (number or string) with an optional tag. Overwrites oldest on overflow.
---@param value any
---@param tag? any (optional)
---@return integer
function Ring:push(value, tag) end

--- Returns the sum of all numeric values in the ring.
---@return number
function Ring:sum() end

--- Returns all entries (oldest first) as an array of {id, tag, value?, text?} tables.
---@return table
function Ring:toArray() end

--- Lua wrapper for the ServiceLocator pattern.
---@class ServiceLocator
local ServiceLocator = {}

--- Removes all registered services.
function ServiceLocator:clearAll() end

--- Returns a table of all registered service names.
---@return table
function ServiceLocator:getServices() end

--- Returns true if a service with the given name is registered.
---@param name any
---@return boolean
function ServiceLocator:has(name) end

--- Retrieves a registered service by name; returns nil if not found.
---@param name any
---@return any
function ServiceLocator:locate(name) end

--- Registers a named service with an associated Lua value.
---@param name any
---@param value any
function ServiceLocator:provide(name, value) end

--- Unregisters and removes a named service.
---@param name any
function ServiceLocator:remove(name) end

--- Lua wrapper for the SimpleState finite state machine pattern.
---@class SimpleState
local SimpleState = {}

--- Registers a named state with optional enter, exit, and update callbacks.
---@param name any
---@param callbacks? any (optional)
function SimpleState:addState(name, callbacks) end

--- Removes all states and callbacks from this state machine.
function SimpleState:clearAll() end

--- Returns the name of the current state, or nil if none is active.
---@return string?
function SimpleState:getCurrent() end

--- Returns a table of all registered state names.
---@return table
function SimpleState:getStates() end

--- Returns true if a state with the given name is registered.
---@param name any
---@return boolean
function SimpleState:hasState(name) end

--- Transitions to a named state, calling exit/enter callbacks as needed.
---@param name any
---@return boolean
function SimpleState:transitionTo(name) end

--- Calls the update callback of the current state with the given delta time.
---@param dt any
function SimpleState:update(dt) end

--- Lua wrapper for the Throttle pattern.
---@class Throttle
local Throttle = {}

--- Returns the total number of times this throttle has fired.
---@return integer
function Throttle:getFireCount() end

--- Returns the normalised progress through the current interval [0, 1].
---@return number
function Throttle:getProgress() end

--- Sets the callback invoked when the throttle fires.
---@param f any
function Throttle:onFire(f) end

--- Resets the elapsed counter without firing.
function Throttle:reset() end

--- Enables or disables the throttle.
---@param v any
function Throttle:setEnabled(v) end

--- Advances the timer by dt seconds; fires the callback if the interval elapsed.
---@param dt any
---@return boolean
function Throttle:update(dt) end

--- Creates a new Blackboard shared key-value store.
---@param name? any (optional)
---@return any
function lurek.patterns.newBlackboard(name) end

--- Creates a new CommandStack instance.
---@param max_size? any (optional)
---@return any
function lurek.patterns.newCommandStack(max_size) end

--- Creates a trailing-edge debounce that fires after the input stream is idle for wait seconds.
---@param wait any
---@return any
function lurek.patterns.newDebounce(wait) end

--- Creates a new EventBus instance.
---@param name? any (optional)
---@return any
function lurek.patterns.newEventBus(name) end

--- Creates a new Factory instance.
---@return any
function lurek.patterns.newFactory() end

--- Creates a time-windowed event aggregator. window=0 means flush on every push.
---@param window any
---@param max_entries? any (optional)
---@param name? any (optional)
---@return any
function lurek.patterns.newFunnel(window, max_entries, name) end

--- Creates a new ObjectPool instance.
---@return any
function lurek.patterns.newObjectPool() end

--- Creates a new reactive property Observer.
---@param name? any (optional)
---@return any
function lurek.patterns.newObserver(name) end

--- Creates a stable priority-ordered task queue.
---@param name? any (optional)
---@return any
function lurek.patterns.newPriorityQueue(name) end

--- Creates a fixed-capacity circular history buffer.
---@param capacity any
---@param name? any (optional)
---@return any
function lurek.patterns.newRing(capacity, name) end

--- Creates a new ServiceLocator instance.
---@return any
function lurek.patterns.newServiceLocator() end

--- Creates a new SimpleState finite state machine instance.
---@return any
function lurek.patterns.newSimpleState() end

--- Creates a leading-edge rate limiter that fires at most once per interval seconds.
---@param interval any
---@return any
function lurek.patterns.newThrottle(interval) end

---@class lurek.physics
lurek.physics = {}

--- Lua-side handle to a physics body accessed through its world.
---@class Body
local Body = {}

--- Applies an angular impulse.
---@param impulse any
---@return nil
function Body:applyAngularImpulse(impulse) end

--- Applies a continuous force to the body.
---@param fx any
---@param fy any
---@return nil
function Body:applyForce(fx, fy) end

--- Applies a linear impulse to the body.
---@param ix any
---@param iy any
---@return nil
function Body:applyImpulse(ix, iy) end

--- Applies a torque (rotational force).
---@param torque any
---@return nil
function Body:applyTorque(torque) end

--- Removes this body from the world.
---@return nil
function Body:destroy() end

--- Returns the body angle in radians.
---@return number
function Body:getAngle() end

--- Returns the angular damping coefficient.
---@return number
function Body:getAngularDamping() end

--- Returns the angular velocity in radians/s.
---@return number
function Body:getAngularVelocity() end

--- Returns the body friction coefficient.
---@return number
function Body:getFriction() end

--- Returns the per-body gravity multiplier.
---@return number
function Body:getGravityScale() end

--- Returns the body height.
---@return number
function Body:getHeight() end

--- Returns the body's integer ID.
---@return integer
function Body:getId() end

--- Returns the collision layer bitmask.
---@return integer
function Body:getLayer() end

--- Returns the linear damping coefficient.
---@return number
function Body:getLinearDamping() end

--- Returns the collision mask bitmask.
---@return integer
function Body:getMask() end

--- Returns the body mass.
---@return number
function Body:getMass() end

--- Returns the body position (x, y).
---@return number
function Body:getPosition() end

--- Returns the body restitution (bounciness).
---@return number
function Body:getRestitution() end

--- Returns the body type as a string.
---@return string
function Body:getType() end

--- Returns the body velocity (vx, vy).
---@return number
function Body:getVelocity() end

--- Returns the body width.
---@return number
function Body:getWidth() end

--- Returns the body X position.
---@return number
function Body:getX() end

--- Returns the body Y position.
---@return number
function Body:getY() end

--- Returns whether CCD is enabled.
---@return boolean
function Body:isBullet() end

--- Returns whether rotation is locked.
---@return boolean
function Body:isFixedRotation() end

--- Returns whether the body can sleep.
---@return boolean
function Body:isSleepingAllowed() end

--- Sets the body angle in radians.
---@param angle any
---@return nil
function Body:setAngle(angle) end

--- Sets the angular damping coefficient.
---@param damping any
---@return nil
function Body:setAngularDamping(damping) end

--- Sets the angular velocity.
---@param omega any
---@return nil
function Body:setAngularVelocity(omega) end

--- Enables or disables CCD.
---@param bullet any
---@return nil
function Body:setBullet(bullet) end

--- Locks or unlocks rotation.
---@param fixed any
---@return nil
function Body:setFixedRotation(fixed) end

--- Sets the body friction coefficient.
---@param friction any
---@return nil
function Body:setFriction(friction) end

--- Sets the per-body gravity multiplier.
---@param scale any
---@return nil
function Body:setGravityScale(scale) end

--- Sets the collision layer bitmask.
---@param layer any
---@return nil
function Body:setLayer(layer) end

--- Sets the linear damping coefficient.
---@param damping any
---@return nil
function Body:setLinearDamping(damping) end

--- Sets the collision mask bitmask.
---@param mask any
---@return nil
function Body:setMask(mask) end

--- Sets the body mass.
---@param mass any
---@return nil
function Body:setMass(mass) end

--- Sets the body position.
---@param x any
---@param y any
---@return nil
function Body:setPosition(x, y) end

--- Sets the body restitution (bounciness).
---@param restitution any
---@return nil
function Body:setRestitution(restitution) end

--- Sets whether the body can sleep.
---@param allowed any
---@return nil
function Body:setSleepingAllowed(allowed) end

--- Sets the body type.
---@param bt any
---@return nil
function Body:setType(bt) end

--- Sets the body velocity.
---@param vx any
---@param vy any
---@return nil
function Body:setVelocity(vx, vy) end

--- Lua-side standalone shape object (circle, rectangle, edge, polygon, chain).
---@class PhysicsShape
local PhysicsShape = {}

--- Releases this shape handle (GC handles cleanup).
---@return nil
function PhysicsShape:destroy() end

--- Returns the axis-aligned bounding box (x1, y1, x2, y2).
---@return number
function PhysicsShape:getBoundingBox() end

--- Returns the radius. Only valid for circle shapes.
---@return number
function PhysicsShape:getRadius() end

--- Returns the shape type string: "circle", "rectangle", "polygon", "edge", or "chain".
---@return string
function PhysicsShape:getType() end

--- Sets the density for this shape (used when attaching to a body).
---@param density any
---@return nil
function PhysicsShape:setDensity(density) end

--- Sets the friction coefficient.
---@param friction any
---@return nil
function PhysicsShape:setFriction(friction) end

--- Sets the restitution (bounciness) coefficient.
---@param restitution any
---@return nil
function PhysicsShape:setRestitution(restitution) end

--- Sets whether this shape is a sensor (non-colliding trigger).
---@param sensor any
---@return nil
function PhysicsShape:setSensor(sensor) end

--- Lua-side handle wrapping a physics World.
---@class World
local World = {}

--- Resets the world, removing all bodies and joints.
---@return nil
function World:clear() end

--- Removes a body from the world.
---@param id any
---@return nil
function World:destroyBody(id) end

--- Removes a joint from the world.
---@param jid any
---@return nil
function World:destroyJoint(jid) end

--- Returns the number of fixtures on a body.
---@param body_id any
---@return integer
function World:fixtureCount(body_id) end

--- Returns begin-contact events from the last step.
---@return table
function World:getBeginContactEvents() end

--- Returns the body ID at a world-space point, or nil.
---@param x any
---@param y any
---@return integer|nil
function World:getBodyAtPoint(x, y) end

--- Returns contacts involving a specific body.
---@param body_id any
---@return table
function World:getBodyContacts(body_id) end

--- Returns the total number of bodies in the world.
---@return integer
function World:getBodyCount() end

--- Returns all body IDs in the world.
---@return table
function World:getBodyIds() end

--- Returns the body type as a string.
---@param id any
---@return string
function World:getBodyType(id) end

--- Returns collision events from the last step.
---@return table
function World:getCollisionEvents() end

--- Returns all contact pairs from the narrow phase.
---@return table
function World:getContacts() end

--- Returns end-contact events from the last step.
---@return table
function World:getEndContactEvents() end

--- Returns the gravity vector (gx, gy).
---@return number
function World:getGravity() end

--- Returns the two body IDs connected by a joint.
---@param jid any
---@return integer
function World:getJointBodies(jid) end

--- Returns all joint IDs.
---@return table
function World:getJointIds() end

--- Returns the angular limits on a joint.
---@param jid any
---@return number
function World:getJointLimits(jid) end

--- Returns the motor speed on a joint's angular axis.
---@param jid any
---@return number
function World:getJointMotorSpeed(jid) end

--- Returns the type name of a joint.
---@param jid any
---@return string
function World:getJointType(jid) end

--- Returns the pixels-per-meter scaling factor.
---@return number
function World:getMeter() end

--- Returns the total number of joints.
---@return integer
function World:jointCount() end

--- Sets the gravity vector.
---@param gx any
---@param gy any
---@return nil
function World:setGravity(gx, gy) end

--- Sets the pixels-per-meter scaling factor.
---@param ppm any
---@return nil
function World:setMeter(ppm) end

--- Advances the physics simulation by dt seconds.
---@param dt any
---@return nil
function World:step(dt) end

--- Converts a pixel value to physics units.
---@param px any
---@return number
function World:toPhysics(px) end

--- Converts a physics-unit value to pixels.
---@param m any
---@return number
function World:toPixels(m) end

--- Attaches a standalone shape to a body as an additional fixture.
---@param body_ud any
---@param shape_ud any
---@return nil
function lurek.physics.attachShape(body_ud, shape_ud) end

--- Marks a physics world for destruction. Subsequent operations on the world
---@param world_ud any
---@return nil
function lurek.physics.destroyWorld(world_ud) end

--- Returns the position and velocity of a body (x, y, vx, vy).
---@param world_ud any
---@param body_ud any
---@return number
function lurek.physics.getBody(world_ud, body_ud) end

--- Returns all collision events from the last simulation step.
---@param world_ud any
---@return table
function lurek.physics.getCollisions(world_ud) end

--- Returns whether the body is allowed to sleep.
---@param world_ud any
---@param body_ud any
---@return boolean
function lurek.physics.isSleepingAllowed(world_ud, body_ud) end

--- Creates a new rectangular body in the given world.
---@param world_ud any
---@param x any
---@param y any
---@param bt any
---@return Body
function lurek.physics.newBody(world_ud, x, y, bt) end

--- Creates a chain shape userdata from flat variadic vertex pairs.
---@param closed any
---@param coords any
---@return Shape
function lurek.physics.newChainShape(closed, coords) end

--- Creates a circle shape userdata.
---@param r any
---@return Shape
function lurek.physics.newCircleShape(r) end

--- Creates an edge (line segment) shape userdata.
---@param x1 any
---@param y1 any
---@param x2 any
---@param y2 any
---@return Shape
function lurek.physics.newEdgeShape(x1, y1, x2, y2) end

--- Creates a convex polygon shape userdata from flat variadic vertex pairs.
---@return Shape
function lurek.physics.newPolygonShape() end

--- Creates a rectangle shape userdata.
---@param w any
---@param h any
---@return Shape
function lurek.physics.newRectangleShape(w, h) end

--- Creates a new physics world with the given gravity vector.
---@param gx any
---@param gy any
---@return World
function lurek.physics.newWorld(gx, gy) end

--- Sets the velocity of a body.
---@param world_ud any
---@param body_ud any
---@param vx any
---@param vy any
---@return nil
function lurek.physics.setBodyVelocity(world_ud, body_ud, vx, vy) end

--- Sets whether the body is allowed to sleep.
---@param world_ud any
---@param body_ud any
---@param allowed any
---@return nil
function lurek.physics.setSleepingAllowed(world_ud, body_ud, allowed) end

--- Advances the physics world by dt seconds.
---@param world_ud any
---@param dt any
---@return nil
function lurek.physics.step(world_ud, dt) end

---@class lurek.pipeline
lurek.pipeline = {}

--- Lua-side wrapper around a [`Pipeline`] DAG with scheduler and Lua callback registry.
---@class Pipeline
local Pipeline = {}

--- Adds a step to the pipeline. Returns self for chaining.
---@param step_ud any
---@return Pipeline
function Pipeline:addStep(step_ud) end

--- Cancels all pending and waiting steps.
---@return nil
function Pipeline:cancel() end

--- Clears all steps from the pipeline.
---@return nil
function Pipeline:clear() end

--- Returns the stored async context table, or nil.
---@return table?
function Pipeline:getContext() end

--- Returns the current error mode as a string.
---@return string
function Pipeline:getErrorMode() end

--- Returns the topological execution order as an array of step names.
---@return table?
function Pipeline:getExecutionOrder() end

--- Returns the pipeline's name.
---@return string
function Pipeline:getName() end

--- Returns parallel execution groups as a nested array of step name arrays.
---@return table?
function Pipeline:getParallelGroups() end

--- Returns the current result table built from step states, or nil.
---@return table?
function Pipeline:getResult() end

--- Returns the LuaStep wrapper for the named step, or nil.
---@param name any
---@return PipelineStep?
function Pipeline:getStep(name) end

--- Returns the total number of steps.
---@return integer
function Pipeline:getStepCount() end

--- Returns a Lua array of all step wrappers in the pipeline.
---@return table
function Pipeline:getSteps() end

--- Returns a Lua array of all steps whose tag matches the given string.
---@param tag any
---@return table
function Pipeline:getStepsByTag(tag) end

--- Returns true if all steps have reached a terminal state.
---@return boolean
function Pipeline:isComplete() end

--- Returns true if the pipeline is currently running asynchronously.
---@return boolean
function Pipeline:isRunning() end

--- Removes a step from the pipeline by name.
---@param name any
---@return nil
function Pipeline:removeStep(name) end

--- Resets all step states and clears the async context.
---@return nil
function Pipeline:reset() end

--- Executes the pipeline synchronously in topological order.
---@param context? any (optional)
---@return table
function Pipeline:run(context) end

--- Starts an async pipeline run. Steps are executed one-per-frame via update(dt).
---@param context? any (optional)
---@return nil
function Pipeline:runAsync(context) end

--- Sets the pipeline error mode: "abort" or "continue".
---@param mode any
---@return nil
function Pipeline:setErrorMode(mode) end

--- Sets the pipeline's name.
---@param name any
---@return nil
function Pipeline:setName(name) end

--- Sets the callback to invoke when the pipeline completes.
---@param cb? any (optional)
---@return nil
function Pipeline:setOnComplete(cb) end

--- Sets the callback to invoke each time a step fails.
---@param cb? any (optional)
---@return nil
function Pipeline:setOnStepError(cb) end

--- Serialises the pipeline definition to a Lua table (no callbacks).
---@return table
function Pipeline:toTable() end

--- Returns the type name of this object.
---@return string
function Pipeline:type() end

--- Returns true if this object is of the given type.
---@param name any
---@return boolean
function Pipeline:typeOf(name) end

--- Advances the async pipeline by one tick. Returns true when all steps are done.
---@param dt any
---@return boolean
function Pipeline:update(dt) end

--- Validates the pipeline DAG. Returns (ok, error_array).
---@return boolean
function Pipeline:validate() end

--- Lua-side wrapper around a single [`PipelineStep`], plus Lua callback registry keys.
---@class Step
local Step = {}

--- Adds a dependency on another step by name or PipelineStep. Returns self for chaining.
---@param dep any
---@return PipelineStep
function Step:dependsOn(dep) end

--- Returns the number of execution attempts so far.
---@return integer
function Step:getAttempt() end

--- Retrieves a metadata value by key, returning nil if not found.
---@param key any
---@return string?
function Step:getData(key) end

--- Returns the configured delay in seconds.
---@return number
function Step:getDelay() end

--- Returns the list of dependency step names.
---@return table
function Step:getDependencies() end

--- Returns the number of declared dependencies.
---@return integer
function Step:getDependencyCount() end

--- Returns total seconds spent executing this step.
---@return number
function Step:getDuration() end

--- Returns the error message from the last failed attempt, or nil.
---@return string?
function Step:getError() end

--- Returns the unique name of this step.
---@return string
function Step:getName() end

--- Returns the configured retry count.
---@return integer
function Step:getRetryCount() end

--- Returns the current execution status as a string.
---@return string
function Step:getStatus() end

--- Returns the tag on this step, or nil if unset.
---@return string?
function Step:getTag() end

--- Returns the timeout stored in metadata, or 0.0 if unset.
---@return number
function Step:getTimeout() end

--- Returns whether this step is marked as optional.
---@return boolean
function Step:isOptional() end

--- Stores a Lua function as the execute callback for this step.
---@param cb any
---@return nil
function Step:setCallback(cb) end

--- Stores a Lua function (or nil) as the run-condition for this step.
---@param cond? any (optional)
---@return nil
function Step:setCondition(cond) end

--- Stores an arbitrary string value under the given key in step metadata.
---@param key any
---@param value any
---@return nil
function Step:setData(key, value) end

--- Sets the delay in seconds to wait after dependencies finish.
---@param seconds any
---@return nil
function Step:setDelay(seconds) end

--- Stores a Lua function (or nil) to call if this step fails.
---@param cb? any (optional)
---@return nil
function Step:setOnError(cb) end

--- Marks whether this step is optional (downstream steps continue on failure).
---@param optional any
---@return nil
function Step:setOptional(optional) end

--- Sets the maximum number of retry attempts on failure.
---@param count any
---@return nil
function Step:setRetryCount(count) end

--- Sets the delay in seconds between retry attempts.
---@param seconds any
---@return nil
function Step:setRetryDelay(seconds) end

--- Sets the tag on this step for grouping and filtering.
---@param tag any
---@return nil
function Step:setTag(tag) end

--- Stores a timeout in seconds in the step's metadata.
---@param seconds any
---@return nil
function Step:setTimeout(seconds) end

--- Returns the type name "PipelineStep".
---@return string
function Step:type() end

--- Returns true when the given name matches "PipelineStep" or a parent type.
---@param name any
---@return boolean
function Step:typeOf(name) end

--- Deserialises a pipeline from a definition table.
---@param def any
---@return Pipeline
function lurek.pipeline.fromTable(def) end

--- Creates a new empty pipeline with the given name (defaults to "pipeline").
---@param name? any (optional)
---@return Pipeline
function lurek.pipeline.newPipeline(name) end

--- Creates a new pipeline step with the given name and optional callback.
---@param name any
---@param callback? any (optional)
---@return PipelineStep
function lurek.pipeline.newStep(name, callback) end

---@class lurek.procgen
lurek.procgen = {}

--- Generates a cave-like map using cellular automata.
---@param w any
---@param h any
---@param opts? any (optional)
---@return table
function lurek.procgen.cellularAutomata(w, h, opts) end

--- BFS flood fill on a flat grid of bytes.
---@param data table
---@param w integer
---@param h integer
---@param sx integer
---@param sy integer
---@param threshold? integer? (optional)
---@param above? boolean? (optional)
---@return table
function lurek.procgen.floodFill(data, w, h, sx, sy, threshold, above) end

--- Evaluates periodic Perlin noise at a point.
---@param x any
---@param y any
---@param px any
---@param py any
---@return number
function lurek.procgen.perlinNoise(x, y, px, py) end

--- Generates Poisson disk sample points using Bridson's algorithm.
---@param w any
---@param h any
---@param min_dist any
---@param max_attempts? any (optional)
---@param seed? any (optional)
---@return table
function lurek.procgen.poissonDisk(w, h, min_dist, max_attempts, seed) end

--- Generates a Voronoi diagram for a set of seed points.
---@param w any
---@param h any
---@param pts_tbl any
---@param opts_tbl? any (optional)
---@return table
function lurek.procgen.voronoi(w, h, pts_tbl, opts_tbl) end

---@class lurek.raycaster
lurek.raycaster = {}

--- Lua-side wrapper around a [`Raycaster2D`] grid.
---@class Raycaster
local Raycaster = {}

--- Returns the cell value at (x, y).
---@param x any
---@param y any
---@return integer
function Raycaster:getCell(x, y) end

--- Returns the grid height in cells.
---@return integer
function Raycaster:height() end

--- Returns true when the cell at (x, y) is a wall (value > 0).
---@param x any
---@param y any
---@return boolean
function Raycaster:isBlocked(x, y) end

--- Sets the cell value at grid position (x, y).
---@param x any
---@param y any
---@param val any
---@return nil
function Raycaster:setCell(x, y, val) end

--- Replaces all grid cells from a flat array of values in row-major order.
---@param cells_tbl any
---@return nil
function Raycaster:setCells(cells_tbl) end

--- Returns the grid width in cells.
---@return integer
function Raycaster:width() end

--- Returns distance-based brightness in [0, 1].
---@param distance any
---@param max_distance any
---@return number
function lurek.raycaster.distanceShade(distance, max_distance) end

--- Creates a new raycaster grid of the given dimensions.
---@param w any
---@param h any
---@return Raycaster
function lurek.raycaster.new(w, h) end

--- Projects a wall distance to screen-space drawing parameters.
---@param distance any
---@param fov any
---@param screen_height any
---@return number
function lurek.raycaster.projectColumn(distance, fov, screen_height) end

---@class lurek.savegame
lurek.savegame = {}

--- Lua-side wrapper around [`SaveManager`] with per-module callback storage.
---@class SaveManager
local SaveManager = {}

--- Collects data from all registered collectors into a table with metadata.
---@return table
function SaveManager:collect() end

--- Deletes a save file for the given slot.
---@param slot any
---@return nil
function SaveManager:delete(slot) end

--- Disables auto-save.
---@return nil
function SaveManager:disableAutoSave() end

--- Returns whether a save file exists for the given slot.
---@param slot any
---@return boolean
function SaveManager:exists(slot) end

--- Returns the current schema version.
---@return integer
function SaveManager:getSchemaVersion() end

--- Returns metadata for a single slot, or nil if not found.
---@param slot any
---@return table?
function SaveManager:getSlotInfo(slot) end

--- Returns a list of all save slots with metadata.
---@return table
function SaveManager:getSlots() end

--- Returns the current summary string.
---@return string
function SaveManager:getSummary() end

--- Returns whether data has been modified since the last save or load.
---@return boolean
function SaveManager:isDirty() end

--- Loads data from a slot file, applies migrations, and restores.
---@param slot any
---@return boolean
function SaveManager:load(slot) end

--- Marks data as modified since the last save or load.
---@return nil
function SaveManager:markDirty() end

--- Resets all state, removing callbacks and clearing the manager.
---@return nil
function SaveManager:reset() end

--- Restores data from a table, applying migrations and calling restorers.
---@param data any
---@return nil
function SaveManager:restore(data) end

--- Collects data and writes it to a slot file.
---@param slot any
---@return nil
function SaveManager:save(slot) end

--- Sets the current schema version for new saves.
---@param version any
---@return nil
function SaveManager:setSchemaVersion(version) end

--- Sets the summary string included in save metadata.
---@param summary any
---@return nil
function SaveManager:setSummary(summary) end

--- Removes a named module and its callbacks.
---@param name any
---@return nil
function SaveManager:unregister(name) end

--- Advances the auto-save timer, returning the slot name if a save should trigger.
---@param dt any
---@return string?
function SaveManager:update(dt) end

--- Creates a new SaveManager for slot-based save/load operations.
---@return SaveManager
function lurek.savegame.newSaveManager() end

---@class lurek.scene
lurek.scene = {}

--- Lua-side wrapper around a [`DepthSorter`] with registry-stored callbacks.
---@class DepthSorter
local DepthSorter = {}

--- Registers a draw callback at the given depth layer.
---@param callback any
---@param depth any
---@return nil
function DepthSorter:add(callback, depth) end

--- Registers a table object with a draw method at the given depth.
---@param obj any
---@return nil
function DepthSorter:addObject(obj) end

--- Removes all registered callbacks without calling them.
---@return nil
function DepthSorter:clear() end

--- Calls all draw callbacks in sorted depth order, then clears.
---@return nil
function DepthSorter:flush() end

--- Returns the number of registered draw entries.
---@return integer
function DepthSorter:getCount() end

--- Sorts all registered callbacks by depth ascending.
---@return nil
function DepthSorter:sort() end

--- Clears all scenes from the stack, calling leave on each.
---@return nil
function lurek.scene.clear() end

--- Draws all scenes in the stack from bottom to top (legacy name; prefer `render`).
---@return nil
function lurek.scene.draw() end

--- Returns the current top scene table, or nil if the stack is empty.
---@return table?
function lurek.scene.getCurrent() end

--- Returns a value from the inter-scene data store, or nil if not found.
---@param key any
---@return table?
function lurek.scene.getData(key) end

--- Returns a registered scene table by name, or nil if not found.
---@param name any
---@return table?
function lurek.scene.getRegistered(name) end

--- Returns a list of all registered scene names.
---@return table
function lurek.scene.getRegisteredNames() end

--- Returns the number of scenes on the stack.
---@return integer
function lurek.scene.getStackSize() end

--- Returns the transition progress from 0.0 to 1.0.
---@return number
function lurek.scene.getTransitionProgress() end

--- Returns true if the given key exists in the data store.
---@param key any
---@return boolean
function lurek.scene.hasData(key) end

--- Returns true if a scene is registered under the given name.
---@param name any
---@return boolean
function lurek.scene.hasRegistered(name) end

--- Returns true if the scene stack is empty.
---@return boolean
function lurek.scene.isEmpty() end

--- Returns true if a scene transition is currently active.
---@return boolean
function lurek.scene.isTransitioning() end

--- Creates a new DepthSorter for z-ordered draw batching.
---@return DepthSorter
function lurek.scene.newDepthSorter() end

--- Pops the top scene from the stack with an optional transition.
---@param transition? any (optional)
---@param duration? any (optional)
---@return nil
function lurek.scene.pop(transition, duration) end

--- Pops scenes until the named scene is on top, calling leave on each removed.
---@param name any
---@return boolean
function lurek.scene.popTo(name) end

--- Calls `scene:ready(self)` on the top scene if not yet fired, then `scene:process(dt)`.
---@param dt any
---@return nil
function lurek.scene.process(dt) end

--- Calls `scene:process_late(dt)` on the topmost scene (after process, before render).
---@param dt any
---@return nil
function lurek.scene.processLate(dt) end

--- Calls `scene:process_physics(dt)` on the topmost scene (fixed timestep).
---@param dt any
---@return nil
function lurek.scene.processPhysics(dt) end

--- Pushes a scene table onto the stack with an optional transition.
---@param scene table
---@param transition? string? (optional)
---@param duration? number? (optional)
---@param params? table? (optional)
---@return nil
function lurek.scene.push(scene, transition, duration, params) end

--- Registers a scene table by name for later retrieval.
---@param name any
---@param scene any
---@return nil
function lurek.scene.registerScene(name, scene) end

--- Removes a value from the inter-scene data store by key.
---@param key any
---@return nil
function lurek.scene.removeData(key) end

--- Draws all scenes in the stack from bottom to top.
---@return nil
function lurek.scene.render() end

--- Draws UI overlay for all scenes in the stack from bottom to top.
---@return nil
function lurek.scene.renderUi() end

--- Stores a value in the inter-scene data store under the given key.
---@param key any
---@param value any
---@return nil
function lurek.scene.setData(key, value) end

--- Replaces the top scene with a new one, calling leave and enter callbacks.
---@param scene table
---@param transition? string? (optional)
---@param duration? number? (optional)
---@param params? table? (optional)
---@return nil
function lurek.scene.switchTo(scene, transition, duration, params) end

--- Removes a scene from the registry by name.
---@param name any
---@return nil
function lurek.scene.unregisterScene(name) end

--- Updates the top scene and any active transition (legacy name; prefer `process`).
---@param dt any
---@return nil
function lurek.scene.update(dt) end

---@class lurek.serial
lurek.serial = {}

--- Parses a CSV string and returns a sequence of row tables.
---@param s any
---@param delim? any (optional)
---@param headers? any (optional)
---@return table
function lurek.serial.fromCsv(s, delim, headers) end

--- Parses a JSON string and returns a Lua table.
---@param s any
---@return table
function lurek.serial.fromJson(s) end

--- Parses a TOML string and returns a Lua table.
---@param s any
---@return table
function lurek.serial.fromToml(s) end

--- Serializes a sequence of row tables to a CSV string.
---@param value any
---@param delim? any (optional)
---@param headers? any (optional)
---@return string
function lurek.serial.toCsv(value, delim, headers) end

--- Serializes a Lua value to a JSON string.
---@param value any
---@param pretty? any (optional)
---@return string
function lurek.serial.toJson(value, pretty) end

--- Serializes a Lua table to a TOML string.
---@param value any
---@return string
function lurek.serial.toToml(value) end

---@class lurek.signal
lurek.signal = {}

--- Lua-side wrapper around a [`Signal`] with registry-stored callbacks.
---@class Signal
local Signal = {}

--- Removes all callbacks for the named event.
---@param name any
---@return integer
function Signal:clear(name) end

--- Removes all callbacks across all events.
---@return integer
function Signal:clearAll() end

--- Emits the named event, calling all registered callbacks with extra arguments.
---@param args any
---@return nil
function Signal:emit(args) end

--- Returns the callback count for the named event.
---@param name any
---@return integer
function Signal:getCount(name) end

--- Returns the total callback count across all events.
---@return integer
function Signal:getTotalCount() end

--- Removes a subscription by handle ID.
---@param handle any
---@return boolean
function Signal:remove(handle) end

--- Returns the type name of this object.
---@return string
function Signal:type() end

--- Returns true if the given type name matches this object's type or any parent type.
---@param name any
---@return boolean
function Signal:typeOf(name) end

--- Discards all pending events in the queue.
---@return nil
function lurek.signal.clear() end

--- Pushes an exit event, requesting the engine to stop.
---@param code? any (optional)
---@return nil
function lurek.signal.exit(code) end

--- Creates a new pub-sub Signal dispatcher.
---@return Signal
function lurek.signal.newSignal() end

--- Returns an iterator function that pops events from the queue.
---@return function
function lurek.signal.poll() end

--- Syncs OS-level events into the queue (no-op in Lurek2D push model).
---@return nil
function lurek.signal.pump() end

--- Pushes a custom event onto the event queue.
---@param args any
---@return nil
function lurek.signal.push(args) end

--- Alias for `exit()` — requests the engine to stop at the end of the current frame.
---@return nil
function lurek.signal.quit() end

--- Requests that the engine restart at the beginning of the next frame.
---@return nil
function lurek.signal.restart() end

--- Blocks until the next event arrives or the optional timeout elapses.
---@param timeout? any (optional)
---@return string?
function lurek.signal.wait(timeout) end

---@class lurek.spine
lurek.spine = {}

--- Lua-side wrapper around a [`Skeleton`].
---@class Skeleton
local Skeleton = {}

--- Adds a root bone with optional local transform and returns its index.
---@param name any
---@param opts? any (optional)
---@return integer
function Skeleton:addBone(name, opts) end

--- Returns the total number of bones.
---@return integer
function Skeleton:boneCount() end

--- Returns the index of the named bone, or nil if not found.
---@param name any
---@return integer?
function Skeleton:findBone(name) end

--- Returns the index of the named slot, or nil if not found.
---@param name any
---@return integer?
function Skeleton:findSlot(name) end

--- Returns the world-space transform of a bone as a table, or nil if out of range.
---@param idx any
---@return table?
function Skeleton:getBoneWorld(idx) end

--- Sets the root bone position and propagates world transforms.
---@param x any
---@param y any
---@return nil
function Skeleton:setPosition(x, y) end

--- Returns the total number of slots.
---@return integer
function Skeleton:slotCount() end

--- Propagates local transforms down the bone hierarchy to compute world positions.
---@return nil
function Skeleton:updateWorldTransforms() end

--- Creates a new empty skeleton with the given name.
---@param name any
---@return Skeleton
function lurek.spine.newSkeleton(name) end

---@class lurek.system
lurek.system = {}

--- Returns the CPU architecture string for the current machine.
---@return any
function lurek.system.getArch() end

--- Returns the command-line arguments as a table.
---@return table
function lurek.system.getArgs() end

--- Returns the output table from the most recently completed runBatch call.
---@param results any
---@return any
function lurek.system.getBatchResults(results) end

--- Returns the current contents of the system clipboard.
---@return any
function lurek.system.getClipboardText() end

--- Returns whether the debug overlay is currently visible.
function lurek.system.getDebugOverlay() end

--- Returns the value of the named OS environment variable, or nil if not set.
---@param name any
---@return any
function lurek.system.getEnv(name) end

--- Returns a table of system information including OS name, CPU model, and installed RAM.
---@return any
function lurek.system.getInfo() end

--- Returns the last unhandled error message, or nil.
---@return any
function lurek.system.getLastError() end

--- Returns the name of the current minimum log level for runtime messages.
function lurek.system.getLogLevel() end

--- Returns the total amount of installed system RAM in megabytes.
---@return any
function lurek.system.getMemorySize() end

--- Returns the host operating system name ('Windows', 'Linux', 'macOS').
---@return any
function lurek.system.getOS() end

--- Returns battery state, percentage charged, and estimated time remaining.
---@return any
function lurek.system.getPowerInfo() end

--- Returns an ordered list of the user's preferred locale strings (e.g. 'en-US').
---@return any
function lurek.system.getPreferredLocales() end

--- Returns the number of logical CPU cores available.
---@return any
function lurek.system.getProcessorCount() end

--- Returns the Lurek2D engine version string.
---@return any
function lurek.system.getVersion() end

--- Emit a log message from Lua at the specified level.
---@param level any
---@param message any
function lurek.system.log(level, message) end

--- Opens a URL in the system's default browser.
---@param url any
---@return any
function lurek.system.openURL(url) end

--- Parses a command-line argument string and returns a structured key/value table.
---@param args? any (optional)
---@return any
function lurek.system.parseArgs(args) end

--- Runs a list of shell commands in parallel and returns immediately without blocking.
---@param tasks any
---@param opts? any (optional)
---@return any
function lurek.system.runBatch(tasks, opts) end

--- Replaces the system clipboard contents with the given string.
---@param text any
function lurek.system.setClipboardText(text) end

--- Shows or hides the FPS/draw-call debug overlay.
---@param enabled any
function lurek.system.setDebugOverlay(enabled) end

--- Sets the minimum severity level for runtime log messages.
---@param level any
function lurek.system.setLogLevel(level) end

---@class lurek.terminal
lurek.terminal = {}

--- Lua-side wrapper around a [`Terminal`] with widget binding management.
---@class Terminal
local Terminal = {}

--- Attaches a widget to this terminal.
---@param widget_ud any
---@return nil
function Terminal:addWidget(widget_ud) end

--- Clears all cells to defaults.
---@return nil
function Terminal:clear() end

--- Detaches all widgets from this terminal.
---@return nil
function Terminal:clearWidgets() end

--- Returns the cell data at 1-based coordinates.
---@param col any
---@param row any
---@return integer
function Terminal:get(col, row) end

--- Returns the default cell size in pixels.
---@return number
function Terminal:getCellSize() end

--- Returns the terminal grid dimensions.
---@return integer
function Terminal:getDimensions() end

--- Returns the currently focused widget, or nil.
---@return Widget?
function Terminal:getFocused() end

--- Returns the number of attached widgets.
---@return integer
function Terminal:getWidgetCount() end

--- Routes a key press to the focused widget and fires callbacks.
---@param key any
---@return boolean
function Terminal:keypressed(key) end

--- Detaches a widget from this terminal.
---@param widget_ud any
---@return nil
function Terminal:removeWidget(widget_ud) end

--- Renders the terminal grid and widgets as render commands.
---@param x? any (optional)
---@param y? any (optional)
---@return nil
function Terminal:render(x, y) end

--- Sets a cell at 1-based coordinates with character FG and BG colours.
---@param args any
---@return nil
function Terminal:set(args) end

--- Sets the focused widget, or clears focus if nil is passed.
---@param value any
---@return nil
function Terminal:setFocus(value) end

--- Routes text input to the focused widget and fires callbacks.
---@param text any
---@return boolean
function Terminal:textinput(text) end

--- Lua-side wrapper around a [`Widget`] with attachment and callback state.
---@class Widget
local Widget = {}

--- Adds a child widget to a panel widget.
---@param child_ud any
---@return nil
function Widget:addChild(child_ud) end

--- Adds an item to a list widget.
---@param item any
---@return nil
function Widget:addItem(item) end

--- Removes all children from a panel widget.
---@return nil
function Widget:clearChildren() end

--- Removes all items from a list widget.
---@return nil
function Widget:clearItems() end

--- Returns a child widget from a panel by 1-based index, or nil.
---@param index any
---@return Widget?
function Widget:getChild(index) end

--- Returns the number of children in a panel widget.
---@return integer
function Widget:getChildCount() end

--- Returns the colour of a label or border widget.
---@return number
function Widget:getColor() end

--- Returns a list item by 1-based index.
---@param index any
---@return string
function Widget:getItem(index) end

--- Returns the number of items in a list widget.
---@return integer
function Widget:getItemCount() end

--- Returns the maximum character length of a text box widget.
---@return integer
function Widget:getMaxLength() end

--- Returns the widget position as 1-based coordinates.
---@return integer
function Widget:getPosition() end

--- Returns the selected item index (1-based) in a list widget, or nil.
---@return integer?
function Widget:getSelected() end

--- Returns the widget size in cells.
---@return integer
function Widget:getSize() end

--- Returns the border style name of a border widget.
---@return string
function Widget:getStyle() end

--- Returns the free-form identification tag.
---@return string
function Widget:getTag() end

--- Returns the text content of a label, button, or text box widget.
---@return string
function Widget:getText() end

--- Returns the title of a border widget.
---@return string
function Widget:getTitle() end

--- Returns whether the widget accepts input.
---@return boolean
function Widget:isEnabled() end

--- Returns whether the widget is visible.
---@return boolean
function Widget:isVisible() end

--- Removes a child widget from a panel widget.
---@param child_ud any
---@return nil
function Widget:removeChild(child_ud) end

--- Removes an item from a list widget by 1-based index.
---@param index any
---@return nil
function Widget:removeItem(index) end

--- Sets whether the widget accepts input.
---@param enabled any
---@return nil
function Widget:setEnabled(enabled) end

--- Sets the maximum character length of a text box widget.
---@param max_length any
---@return nil
function Widget:setMaxLength(max_length) end

--- Registers a text change callback for a text box widget.
---@param callback? any (optional)
---@return nil
function Widget:setOnChange(callback) end

--- Registers a click callback for a button widget.
---@param callback? any (optional)
---@return nil
function Widget:setOnClick(callback) end

--- Registers a selection change callback for a list widget.
---@param callback? any (optional)
---@return nil
function Widget:setOnSelect(callback) end

--- Sets the widget position from 1-based coordinates.
---@param col any
---@param row any
---@return nil
function Widget:setPosition(col, row) end

--- Sets the selected item in a list widget by 1-based index.
---@param index? any (optional)
---@return nil
function Widget:setSelected(index) end

--- Sets the widget size in cells.
---@param width any
---@param height any
---@return nil
function Widget:setSize(width, height) end

--- Sets the border style of a border widget.
---@param style_name any
---@return nil
function Widget:setStyle(style_name) end

--- Sets the free-form identification tag.
---@param tag any
---@return nil
function Widget:setTag(tag) end

--- Sets the text content of a label, button, or text box widget.
---@param text any
---@return nil
function Widget:setText(text) end

--- Sets the title of a border widget.
---@param title any
---@return nil
function Widget:setTitle(title) end

--- Sets the widget visibility.
---@param visible any
---@return nil
function Widget:setVisible(visible) end

--- Creates a new decorative border widget at 1-based coordinates.
---@param col any
---@param row any
---@param width any
---@param height any
---@return Widget
function lurek.terminal.newBorder(col, row, width, height) end

--- Creates a new button widget at 1-based coordinates.
---@param col integer
---@param row integer
---@param width integer
---@param height? integer? (optional)
---@param text? string? (optional)
---@return Widget
function lurek.terminal.newButton(col, row, width, height, text) end

--- Creates a new label widget at 1-based coordinates.
---@param col any
---@param row any
---@param text? any (optional)
---@return Widget
function lurek.terminal.newLabel(col, row, text) end

--- Creates a new scrollable list widget at 1-based coordinates.
---@param col any
---@param row any
---@param width any
---@param height any
---@return Widget
function lurek.terminal.newList(col, row, width, height) end

--- Creates a new container panel widget at 1-based coordinates.
---@param col any
---@param row any
---@param width? any (optional)
---@param height? any (optional)
---@return Widget
function lurek.terminal.newPanel(col, row, width, height) end

--- Creates a new terminal grid with the given dimensions.
---@param cols? any (optional)
---@param rows? any (optional)
---@return Terminal
function lurek.terminal.newTerminal(cols, rows) end

--- Creates a new single-line text box widget at 1-based coordinates.
---@param col any
---@param row any
---@param width any
---@return Widget
function lurek.terminal.newTextBox(col, row, width) end

---@class lurek.thread
lurek.thread = {}

---@class Channel
local Channel = {}

function Channel:clear() end

---@param timeout? any (optional)
function Channel:demand(timeout) end

function Channel:getCount() end

function Channel:peek() end

function Channel:pop() end

---@param value any
function Channel:push(value) end

---@param value any
function Channel:supply(value) end

function Channel:type() end

---@param name any
function Channel:typeOf(name) end

--- Lua-side wrapper around a background [`LuaThread`].
---@class ThreadHandle
local ThreadHandle = {}

--- Returns the error message if the thread failed, or nil.
---@return string?
function ThreadHandle:getError() end

--- Returns whether the thread is currently executing.
---@return boolean
function ThreadHandle:isRunning() end

--- Launches the background thread, passing optional arguments via varargs.
---@param args any
---@return nil
function ThreadHandle:start(args) end

--- Returns the type name of this object.
---@return string
function ThreadHandle:type() end

--- Returns whether this object is of the given type.
---@param name any
---@return boolean
function ThreadHandle:typeOf(name) end

--- Blocks the calling thread until the background thread finishes.
---@return nil
function ThreadHandle:wait() end

--- Gets or creates a named global channel shared across threads.
---@param name any
---@return Channel
function lurek.thread.getChannel(name) end

--- Creates an unnamed thread-safe channel for inter-thread communication.
---@return Channel
function lurek.thread.newChannel() end

--- Creates a new background thread from a Lua code string.
---@param code any
---@return Thread
function lurek.thread.newThread(code) end

---@class lurek.tilemap
lurek.tilemap = {}

--- Lua-side wrapper around an [`AutoTileSheet`].
---@class AutoTileSheet
local AutoTileSheet = {}

--- Returns the bitmask value associated with a 1-based local tile ID.
---@param tile_id any
---@return integer
function AutoTileSheet:getBitmaskForTile(tile_id) end

--- Returns the layout variant as a string.
---@return string
function AutoTileSheet:getLayout() end

--- Returns the atlas region rectangle for the 1-based tile ID.
---@param tile_id any
---@return number
function AutoTileSheet:getQuad(tile_id) end

--- Returns the number of tiles in this sheet.
---@return integer
function AutoTileSheet:getTileCount() end

--- Returns the 1-based tile ID for a given bitmask, or nil.
---@param bitmask any
---@return integer?
function AutoTileSheet:getTileForBitmask(bitmask) end

--- Returns the tile height in pixels.
---@return integer
function AutoTileSheet:getTileHeight() end

--- Returns the tile width in pixels.
---@return integer
function AutoTileSheet:getTileWidth() end

--- Lua-side wrapper around a [`ChunkMap`].
---@class ChunkMap
local ChunkMap = {}

--- Returns the tile coordinate range for chunk (cx, cy) as (x0, y0, x1, y1).
---@param cx any
---@param cy any
---@return integer
function ChunkMap:chunkTileRange(cx, cy) end

--- Clears the tile at (x, y) by setting its GID to 0.
---@param x any
---@param y any
---@return nil
function ChunkMap:clearTile(x, y) end

--- Returns the chunk size (tiles per side).
---@return integer
function ChunkMap:getChunkSize() end

--- Returns a table of all currently loaded chunk coordinates as {{cx, cy}, ...}.
---@return table
function ChunkMap:getLoadedChunks() end

--- Returns the GID at tile coordinate (x, y).
---@param x any
---@param y any
---@return integer
function ChunkMap:getTile(x, y) end

--- Pre-allocates the chunk at chunk coordinates (cx, cy).
---@param cx any
---@param cy any
---@return nil
function ChunkMap:loadChunk(cx, cy) end

--- Sets the GID at tile coordinate (x, y).
---@param x any
---@param y any
---@param gid any
---@return nil
function ChunkMap:setTile(x, y, gid) end

--- Removes the chunk at chunk coordinates (cx, cy) from memory.
---@param cx any
---@param cy any
---@return nil
function ChunkMap:unloadChunk(cx, cy) end

--- Lua-side wrapper around an [`IsoMap`].
---@class IsoMap
local IsoMap = {}

--- Appends a new empty Z-level and returns its 1-based index.
---@return integer
function IsoMap:addLevel() end

--- Fills every cell in level z with gid for the given part (1-based z; 0-based part).
---@param z any
---@param part any
---@param gid any
---@return nil
function IsoMap:fillLevel(z, part, gid) end

--- Returns the map height in tiles.
---@return integer
function IsoMap:getHeight() end

--- Returns the number of Z-levels currently in the map.
---@return integer
function IsoMap:getLevelCount() end

--- Returns the vertical pixel offset between consecutive Z-levels.
---@return integer
function IsoMap:getLevelHeight() end

--- Returns the tile footprint height in pixels.
---@return integer
function IsoMap:getTileHeight() end

--- Returns the tile footprint width in pixels.
---@return integer
function IsoMap:getTileWidth() end

--- Returns the map width in tiles.
---@return integer
function IsoMap:getWidth() end

--- Returns the visibility of a level (1-based z).
---@param z any
---@return boolean
function IsoMap:isLevelVisible(z) end

--- Converts screen pixel coordinates to isometric tile coordinates at Z-level 0.
---@param sx any
---@param sy any
---@return number
function IsoMap:screenToTile(sx, sy) end

--- Sets the visibility of a level (1-based z).
---@param z any
---@param visible any
function IsoMap:setLevelVisible(z, visible) end

--- Sets the screen pixel origin.
---@param x any
---@param y any
---@return nil
function IsoMap:setOrigin(x, y) end

--- Projects isometric tile coordinates (tx, ty, tz) to screen pixels.
---@param tx any
---@param ty any
---@param tz any
---@return number
function IsoMap:tileToScreen(tx, ty, tz) end

--- Lua-side wrapper around a [`MapBlock`].
---@class MapBlock
local MapBlock = {}

--- Returns the block dimensions as (width, height) in tiles.
---@return integer
function MapBlock:getDimensions() end

--- Returns the block height in tiles.
---@return integer
function MapBlock:getHeight() end

--- Returns the number of segments along the height.
---@return integer
function MapBlock:getHeightInSegments() end

--- Returns the number of layers in this block.
---@return integer
function MapBlock:getLayerCount() end

--- Returns the name of this block.
---@return string
function MapBlock:getName() end

--- Returns the segment size in tiles.
---@return integer
function MapBlock:getSegmentSize() end

--- Returns the side connection ID for a segment on a given edge.
---@param edge_str any
---@param segment any
---@return integer
function MapBlock:getSide(edge_str, segment) end

--- Returns the GID of the tile at (x, y) on the given layer (1-based).
---@param layer any
---@param x any
---@param y any
---@return integer
function MapBlock:getTile(layer, x, y) end

--- Returns the placement weight.
---@return number
function MapBlock:getWeight() end

--- Returns the block width in tiles.
---@return integer
function MapBlock:getWidth() end

--- Returns the number of segments along the width.
---@return integer
function MapBlock:getWidthInSegments() end

--- Sets the human-readable name of this block.
---@param name any
---@return nil
function MapBlock:setName(name) end

--- Sets the placement weight.
---@param weight any
---@return nil
function MapBlock:setWeight(weight) end

--- Lua-side wrapper around a [`MapGroup`].
---@class MapGroup
local MapGroup = {}

--- Adds a block to this group.
---@param block_ud any
---@return nil
function MapGroup:addBlock(block_ud) end

--- Adds a MapScript to this group.
---@param script_ud any
---@return nil
function MapGroup:addScript(script_ud) end

--- Returns the number of blocks in this group.
---@return integer
function MapGroup:getBlockCount() end

--- Returns the name of this group.
---@return string
function MapGroup:getName() end

--- Returns the number of scripts in this group.
---@return integer
function MapGroup:getScriptCount() end

--- Removes a block by 1-based index.
---@param idx any
---@return nil
function MapGroup:removeBlock(idx) end

--- Lua-side wrapper around a [`MapScript`] procedural generation script.
---@class MapScript
local MapScript = {}

--- Appends a generation step from a step-definition table.
---@param step_def any
---@return nil
function MapScript:addStep(step_def) end

--- Returns the number of steps in this script.
---@return integer
function MapScript:getStepCount() end

--- Lua-side wrapper around a [`TileMap`].
---@class TileMap
local TileMap = {}

--- Adds a new empty layer and returns its 1-based index.
---@param name any
---@param w any
---@param h any
---@return integer
function TileMap:addLayer(name, w, h) end

--- Adds a tileset to this map.
---@param ts_ud any
---@return nil
function TileMap:addTileSet(ts_ud) end

--- Clears a tile (sets GID to 0) at (x, y) on the given layer (1-based).
---@param layer any
---@param x any
---@param y any
function TileMap:clearTile(layer, x, y) end

--- Fills an entire layer with the given GID (1-based layer).
---@param layer any
---@param gid any
---@return nil
function TileMap:fill(layer, gid) end

--- Returns the chunk size used for spatial partitioning.
---@return integer
function TileMap:getChunkSize() end

--- Returns the RGBA tint color of a layer.
---@param idx any
---@return number
function TileMap:getLayerColor(idx) end

--- Returns the number of layers.
---@return integer
function TileMap:getLayerCount() end

--- Returns the name of a layer by 1-based index.
---@param idx any
---@return string?
function TileMap:getLayerName(idx) end

--- Returns the pixel offset of a layer.
---@param idx any
---@return number
function TileMap:getLayerOffset(idx) end

--- Returns the parallax factor of a layer.
---@param idx any
---@return number
function TileMap:getLayerParallax(idx) end

--- Returns layer visibility.
---@param idx any
---@return boolean
function TileMap:getLayerVisible(idx) end

--- Returns the map orientation as a string ("topdown" or "sideview").
---@return string
function TileMap:getOrientation() end

--- Returns the GID at (x, y) on the given layer (1-based).
---@param layer any
---@param x any
---@param y any
---@return integer
function TileMap:getTile(layer, x, y) end

--- Returns tile dimensions as (width, height).
---@return integer
function TileMap:getTileDimensions() end

--- Returns the tile height in pixels.
---@return integer
function TileMap:getTileHeight() end

--- Returns a tileset by 1-based index, or nil if out of range.
---@param idx any
---@return TileSet?
function TileMap:getTileSet(idx) end

--- Returns the number of tilesets attached to this map.
---@return integer
function TileMap:getTileSetCount() end

--- Returns the tile width in pixels.
---@return integer
function TileMap:getTileWidth() end

--- Returns the viewport as (x, y, w, h) or nil if not set.
---@return number
function TileMap:getViewport() end

--- Returns true if the tile at (x, y) on layer is solid (1-based).
---@param layer any
---@param x any
---@param y any
---@return boolean
function TileMap:isSolid(layer, x, y) end

--- Sets the map orientation from a string ("topdown" or "sideview").
---@param orientation any
---@return nil
function TileMap:setOrientation(orientation) end

--- Converts tile coordinates to world pixel coordinates (1-based input).
---@param tx any
---@param ty any
---@return number
function TileMap:tileToWorld(tx, ty) end

--- Advances tile animation timers by dt seconds.
---@param dt any
---@return nil
function TileMap:update(dt) end

--- Converts world pixel coordinates to tile coordinates.
---@param wx any
---@param wy any
---@return integer
function TileMap:worldToTile(wx, wy) end

--- Lua-side wrapper around a [`TileSet`].
---@class TileSet
local TileSet = {}

--- Returns the animation frames for a 1-based local tile ID as a table of {tileid, duration}, or nil.
---@param tile_id any
---@return table?
function TileSet:getAnimation(tile_id) end

--- Returns the number of tile columns in the atlas texture.
---@return integer
function TileSet:getColumns() end

--- Returns the first global ID assigned to this tileset.
---@return integer
function TileSet:getFirstGid() end

--- Returns the margin in pixels around the edges of the atlas.
---@return integer
function TileSet:getMargin() end

--- Computes the atlas source rectangle for a 1-based local tile ID.
---@param tile_id any
---@return table
function TileSet:getQuad(tile_id) end

--- Returns the spacing in pixels between tiles in the atlas.
---@return integer
function TileSet:getSpacing() end

--- Returns the total number of tiles in this tileset.
---@return integer
function TileSet:getTileCount() end

--- Returns the tile dimensions as (width, height).
---@return integer
function TileSet:getTileDimensions() end

--- Returns the height of a single tile in pixels.
---@return integer
function TileSet:getTileHeight() end

--- Returns the width of a single tile in pixels.
---@return integer
function TileSet:getTileWidth() end

--- Returns whether a 1-based local tile ID is solid.
---@param tile_id any
---@return boolean
function TileSet:isSolid(tile_id) end

--- Sets whether a 1-based local tile ID is solid for collision purposes.
---@param tile_id any
---@param solid any
---@return nil
function TileSet:setSolid(tile_id, solid) end

--- Converts screen position back to axial hex coordinates (pointy-top layout).
---@param sx any
---@param sy any
---@param size any
---@return integer
function lurek.tilemap.fromScreenHex(sx, sy, size) end

--- Converts screen position back to tile coordinates for diamond isometric projection.
---@param sx any
---@param sy any
---@param tw any
---@param th any
---@return number
function lurek.tilemap.fromScreenIso(sx, sy, tw, th) end

--- Returns all hex cells within radius distance (filled hex circle) as a table.
---@param q any
---@param r any
---@param radius any
---@return table
function lurek.tilemap.hexArea(q, r, radius) end

--- Returns the hex distance between two axial coordinates.
---@param q1 any
---@param r1 any
---@param q2 any
---@param r2 any
---@return integer
function lurek.tilemap.hexDistance(q1, r1, q2, r2) end

--- Returns all hex cells along a line between two axial coordinates as a table.
---@param q1 any
---@param r1 any
---@param q2 any
---@param r2 any
---@return table
function lurek.tilemap.hexLine(q1, r1, q2, r2) end

--- Returns the six axial neighbor coordinates as a table of {q, r} pairs.
---@param q any
---@param r any
---@return table
function lurek.tilemap.hexNeighbors(q, r) end

--- Reflects hex coordinates across an axis through the center.
---@param q any
---@param r any
---@param center_q any
---@param center_r any
---@param axis any
---@return integer
function lurek.tilemap.hexReflect(q, r, center_q, center_r, axis) end

--- Returns all cells at exactly radius distance from (q, r) as a table.
---@param q any
---@param r any
---@param radius any
---@return table
function lurek.tilemap.hexRing(q, r, radius) end

--- Rotates hex coordinates around a center by steps x 60 degrees clockwise.
---@param q any
---@param r any
---@param center_q any
---@param center_r any
---@param steps any
---@return integer
function lurek.tilemap.hexRotate(q, r, center_q, center_r, steps) end

--- Rounds fractional axial coordinates to the nearest hex cell.
---@param q any
---@param r any
---@return integer
function lurek.tilemap.hexRound(q, r) end

--- Returns all hex cells from center outward to radius, ring by ring, as a table.
---@param q any
---@param r any
---@param radius any
---@return table
function lurek.tilemap.hexSpiral(q, r, radius) end

--- Snaps an angle (in radians) to the nearest isometric direction (1-4).
---@param angle any
---@return integer
function lurek.tilemap.isoDirectionFromAngle(angle) end

--- Returns the name of an isometric direction (1-4).
---@param direction any
---@return string
function lurek.tilemap.isoDirectionName(direction) end

--- Rotates an isometric direction (1-4) clockwise by steps.
---@param direction any
---@param steps any
---@return integer
function lurek.tilemap.isoRotate(direction, steps) end

--- Parses a TMX XML string and returns a table with map metadata and layers.
---@param xml any
---@return table
function lurek.tilemap.loadTMX(xml) end

--- Creates a new AutoTileSheet with the given tile dimensions and layout.
---@param tile_w any
---@param tile_h any
---@param layout_str any
---@return AutoTileSheet
function lurek.tilemap.newAutoTileSheet(tile_w, tile_h, layout_str) end

--- Creates a new ChunkMap with the given chunk size.
---@param chunk_size? any (optional)
---@return ChunkMap
function lurek.tilemap.newChunkMap(chunk_size) end

--- Creates a new IsoMap with no levels.
---@param width any
---@param height any
---@param tile_w any
---@param tile_h any
---@param level_height any
---@return IsoMap
function lurek.tilemap.newIsoMap(width, height, tile_w, tile_h, level_height) end

--- Creates a new MapBlock with the given dimensions.
---@param width any
---@param height any
---@param layers? any (optional)
---@param segment_size? any (optional)
---@return MapBlock
function lurek.tilemap.newMapBlock(width, height, layers, segment_size) end

--- Creates a MapGen from a MapGroup, a preset name or dimensions, and a segment size.
---@param group MapGroup
---@param preset string
---@param segmentSize integer
---@return MapGen
function lurek.tilemap.newMapGen(group, preset, segmentSize) end

--- Creates a new empty MapGroup with the given name.
---@param name any
---@return MapGroup
function lurek.tilemap.newMapGroup(name) end

--- Creates a new empty MapScript procedural generation script.
---@return MapScript
function lurek.tilemap.newMapScript() end

--- Creates a new TileMap with the given tile size and chunk size.
---@param tile_width any
---@param tile_height any
---@param chunk_size? any (optional)
---@return TileMap
function lurek.tilemap.newTileMap(tile_width, tile_height, chunk_size) end

--- Creates a new TileSet with the given atlas layout parameters.
---@param firstGid integer
---@param tileCount integer
---@param columns integer
---@param tileWidth integer
---@param tileHeight integer
---@param spacing? integer? (optional)
---@param margin? integer? (optional)
---@return TileSet
function lurek.tilemap.newTileSet(firstGid, tileCount, columns, tileWidth, tileHeight, spacing, margin) end

--- Converts axial hex coordinates to screen position (pointy-top layout).
---@param q any
---@param r any
---@param size any
---@return number
function lurek.tilemap.toScreenHex(q, r, size) end

--- Converts tile coordinates to screen position using diamond isometric projection.
---@param tx any
---@param ty any
---@param tw any
---@param th any
---@return number
function lurek.tilemap.toScreenIso(tx, ty, tw, th) end

---@class lurek.time
lurek.time = {}

--- Lua-side wrapper around a [`Scheduler`] with per-event callback storage.
---@class Scheduler
local Scheduler = {}

--- Schedules a callback to fire once after a delay.
---@param delay any
---@param func any
---@return integer
function Scheduler:after(delay, func) end

--- Cancels a scheduled event by its numeric ID.
---@param id any
---@return boolean
function Scheduler:cancel(id) end

--- Cancels all scheduled events and returns the count removed.
---@return integer
function Scheduler:cancelAll() end

--- Cancels a scheduled event by its string name.
---@param name any
---@return boolean
function Scheduler:cancelNamed(name) end

--- Returns the number of active scheduled events.
---@return integer
function Scheduler:getCount() end

--- Returns the base interval in seconds for an event, or nil.
---@param id any
---@return number?
function Scheduler:getInterval(id) end

--- Returns the seconds remaining until the next fire for an event, or nil.
---@param id any
---@return number?
function Scheduler:getRemaining(id) end

--- Returns the repeat count remaining for an event, or nil.
---@param id any
---@return integer?
function Scheduler:getRepeatCount(id) end

--- Returns the current time-scale multiplier.
---@return number
function Scheduler:getTimeScale() end

--- Returns whether the scheduler has no active events.
---@return boolean
function Scheduler:isEmpty() end

--- Returns whether the given event is currently paused.
---@param id any
---@return boolean
function Scheduler:isPaused(id) end

--- Pauses a scheduled event by its ID.
---@param id any
---@return boolean
function Scheduler:pause(id) end

--- Resets an event's remaining time back to its original interval.
---@param id any
---@return boolean
function Scheduler:resetEvent(id) end

--- Resumes a paused event by its ID.
---@param id any
---@return boolean
function Scheduler:resume(id) end

--- Changes the repeat interval of an existing event.
---@param id any
---@param interval any
---@return boolean
function Scheduler:setInterval(id, interval) end

--- Sets a global time-scale multiplier for this scheduler.
---@param scale any
---@return nil
function Scheduler:setTimeScale(scale) end

--- Advances all timers by dt seconds, firing due callbacks.
---@param dt any
---@return integer
function Scheduler:update(dt) end

--- Returns the rolling-average frame delta time in seconds.
---@return number
function lurek.time.getAverageDelta() end

--- Returns the delta time in seconds for the current frame.
---@return number
function lurek.time.getDelta() end

--- Returns the current frames-per-second measurement.
---@return number
function lurek.time.getFPS() end

--- Returns the high-resolution elapsed time since engine start in seconds.
---@return number
function lurek.time.getMicroTime() end

--- Returns the fixed timestep used by `process_physics` callbacks (seconds).
---@return number
function lurek.time.getPhysicsDelta() end

--- Returns the total elapsed time since engine start in seconds.
---@return number
function lurek.time.getTime() end

--- Creates a new independent Scheduler for managing timed callbacks.
---@return Scheduler
function lurek.time.newScheduler() end

--- Sets the fixed timestep for `process_physics` callbacks (seconds).
---@param dt any
---@return nil
function lurek.time.setPhysicsDelta(dt) end

--- Suspends execution for the given number of seconds.
---@param seconds any
---@return nil
function lurek.time.sleep(seconds) end

--- Advances the timer by one frame, returning the delta time.
---@return number
function lurek.time.step() end

---@class lurek.tween
lurek.tween = {}

---@class Tween
local Tween = {}

--- Returns raw 0..1 playback progress (not eased, not accounting for yoyo).
---@return number
function Tween:getProgress() end

--- Returns true if the tween is still running (not completed or cancelled).
---@return boolean
function Tween:isActive() end

--- Pauses this tween; time stops advancing but the tween is not cancelled.
---@return nil
function Tween:pause() end

--- Resumes a paused tween.
---@return nil
function Tween:resume() end

--- Sets the number of extra play cycles after the first (0 = play once, -1 = infinite).
---@param n any
---@return nil
function Tween:setRepeat(n) end

--- Enables or disables yoyo (ping-pong) on each repeat cycle.
---@param enabled any
---@return nil
function Tween:setYoyo(enabled) end

---@class TweenParallel
local TweenParallel = {}

--- Cancels the parallel group immediately.
---@return nil
function TweenParallel:cancel() end

--- Returns true if the parallel is running and not yet complete.
---@return boolean
function TweenParallel:isActive() end

---@class TweenSequence
local TweenSequence = {}

--- Cancels the sequence and stops all pending steps.
---@return nil
function TweenSequence:cancel() end

--- Returns true if the sequence has been started and has not yet completed.
---@return boolean
function TweenSequence:isActive() end

--- Cancels all active tweens, sequences, and parallels immediately.
---@return nil
function lurek.tween.cancelAll() end

--- Creates a no-op tween that waits `seconds`, then optionally calls `callback`.
---@param seconds any
---@param cb? any (optional)
---@return TweenSequence
function lurek.tween.delay(seconds, cb) end

--- Returns the number of currently active tween objects (tweens + seqs + pars).
---@return integer
function lurek.tween.getActiveCount() end

--- Returns a list of all available easing names (built-in + custom).
---@return table
function lurek.tween.getEasingNames() end

--- Creates an empty TweenParallel. Add entries with :tween() or :add(tween),
---@return TweenParallel
function lurek.tween.parallel() end

--- Registers a custom easing function under `name`. `fn(t)` receives 0..1, returns 0..1.
---@param name any
---@param f any
---@return nil
function lurek.tween.registerEasing(name, f) end

--- Creates an empty TweenSequence. Add steps with :tween(), :delay(), :callback(),
---@return TweenSequence
function lurek.tween.sequence() end

--- Creates a new property tween and registers it for automatic updating.
---@param duration number
---@param target table
---@param fields table
---@param easing string
---@return Tween
function lurek.tween.tween(duration, target, fields, easing) end

--- Advances all active tweens, sequences, and parallels by `dt` seconds.
---@param dt any
---@return nil
function lurek.tween.update(dt) end

---@class lurek.ui
lurek.ui = {}

--- Adds Accordion-specific methods (1-based sections in Lua).
---@class Accordion
local Accordion = {}

--- Adds a section entry to this Accordion widget.
---@param title any
---@param content_idx? any (optional)
---@return nil
function Accordion:addSection(title, content_idx) end

--- Returns the section count of this Accordion widget.
---@return integer
function Accordion:getSectionCount() end

--- Returns the section title of this Accordion widget.
---@param section_idx any
---@return nil
function Accordion:getSectionTitle(section_idx) end

--- Returns true if exclusive is enabled for this Accordion widget.
---@return boolean
function Accordion:isExclusive() end

--- Returns true if section expanded is enabled for this Accordion widget.
---@param section_idx any
---@return boolean
function Accordion:isSectionExpanded(section_idx) end

--- Sets the exclusive for this Accordion widget.
---@param v any
---@return nil
function Accordion:setExclusive(v) end

--- Toggles the expanded/collapsed status of an Accordion section.
---@param section_idx any
---@return nil
function Accordion:toggleSection(section_idx) end

--- Adds Button-specific methods to a widget table.
---@class Button
local Button = {}

--- Returns the text of this Button widget.
---@return string
function Button:getText() end

--- Sets the text for this Button widget.
---@param text any
---@return nil
function Button:setText(text) end

--- Adds CheckBox-specific methods to a widget table.
---@class Checkbox
local Checkbox = {}

--- Returns the text of this Checkbox widget.
---@return string
function Checkbox:getText() end

--- Returns true if checked is enabled for this Checkbox widget.
---@return boolean
function Checkbox:isChecked() end

--- Sets the checked for this Checkbox widget.
---@param checked any
---@return nil
function Checkbox:setChecked(checked) end

--- Sets the text for this Checkbox widget.
---@param text any
---@return nil
function Checkbox:setText(text) end

--- Adds ColorPicker-specific methods.
---@class Color_Picker
local Color_Picker = {}

--- Returns the color of this Color_Picker widget.
---@return number
function Color_Picker:getColor() end

--- Returns the color mode of this Color_Picker widget.
---@return string
function Color_Picker:getColorMode() end

--- Returns the show alpha of this Color_Picker widget.
---@return boolean
function Color_Picker:getShowAlpha() end

--- Sets the color for this Color_Picker widget.
---@param r any
---@param green any
---@param b any
---@param a? any (optional)
---@return nil
function Color_Picker:setColor(r, green, b, a) end

--- Sets the color mode for this Color_Picker widget.
---@param mode any
---@return nil
function Color_Picker:setColorMode(mode) end

--- Registers a callback invoked when this widget's value changes.
---@param f any
---@return nil
function Color_Picker:setOnChange(f) end

--- Sets the show alpha for this Color_Picker widget.
---@param v any
---@return nil
function Color_Picker:setShowAlpha(v) end

--- Adds ComboBox-specific methods (1-based indices in Lua).
---@class Combo_Box
local Combo_Box = {}

--- Adds a item entry to this Combo_Box widget.
---@param text any
---@return nil
function Combo_Box:addItem(text) end

--- Clears all items entries from this Combo_Box widget.
---@return nil
function Combo_Box:clearItems() end

--- Returns the item of this Combo_Box widget.
---@param index any
---@return string
function Combo_Box:getItem(index) end

--- Returns the item count of this Combo_Box widget.
---@return integer
function Combo_Box:getItemCount() end

--- Returns the selected index of this Combo_Box widget.
---@return integer
function Combo_Box:getSelectedIndex() end

--- Returns the selected item of this Combo_Box widget.
---@return string
function Combo_Box:getSelectedItem() end

--- Removes the item from this Combo_Box widget.
---@param index any
---@return nil
function Combo_Box:removeItem(index) end

--- Sets the selected index for this Combo_Box widget.
---@param index any
---@return nil
function Combo_Box:setSelectedIndex(index) end

--- Adds Dialog-specific methods.
---@class Dialog
local Dialog = {}

--- Adds a button entry to this Dialog widget.
---@param text any
---@param cb? any (optional)
---@return nil
function Dialog:addButton(text, cb) end

--- Closes and removes this dialog from the screen.
---@return nil
function Dialog:close() end

--- Returns the content of this Dialog widget.
---@return integer
function Dialog:getContent() end

--- Returns the title of this Dialog widget.
---@return string
function Dialog:getTitle() end

--- Returns true if modal is enabled for this Dialog widget.
---@return boolean
function Dialog:isModal() end

--- Returns true if open is enabled for this Dialog widget.
---@return boolean
function Dialog:isOpen() end

--- Performs the open operation on this Dialog widget.
---@return nil
function Dialog:open() end

--- Sets the content for this Dialog widget.
---@param content_idx? any (optional)
---@return nil
function Dialog:setContent(content_idx) end

--- Sets the modal for this Dialog widget.
---@param v any
---@return nil
function Dialog:setModal(v) end

--- Registers a callback invoked when this dialog is closed.
---@param f any
---@return nil
function Dialog:setOnClose(f) end

--- Sets the title for this Dialog widget.
---@param title any
---@return nil
function Dialog:setTitle(title) end

--- Adds DockPanel-specific methods.
---@class Dock_Panel
local Dock_Panel = {}

--- Performs the dock operation on this Dock_Panel widget.
---@param child_idx any
---@param side any
---@return nil
function Dock_Panel:dock(child_idx, side) end

--- Returns the docked count of this Dock_Panel widget.
---@return integer
function Dock_Panel:getDockedCount() end

--- Returns the split size of this Dock_Panel widget.
---@param side any
---@return nil
function Dock_Panel:getSplitSize(side) end

--- Sets the split size for this Dock_Panel widget.
---@param side any
---@param size any
---@return nil
function Dock_Panel:setSplitSize(side, size) end

--- Performs the undock operation on this Dock_Panel widget.
---@param child_idx any
---@return nil
function Dock_Panel:undock(child_idx) end

--- Adds GUITable-specific methods (1-based rows/cols in Lua).
---@class Gui_Table
local Gui_Table = {}

--- Adds a column entry to this Gui_Table widget.
---@param header any
---@param width? any (optional)
---@return nil
function Gui_Table:addColumn(header, width) end

--- Adds a row entry to this Gui_Table widget.
---@param cells any
---@return nil
function Gui_Table:addRow(cells) end

--- Returns the cell of this Gui_Table widget.
---@param row any
---@param col any
---@return nil
function Gui_Table:getCell(row, col) end

--- Returns the column count of this Gui_Table widget.
---@return integer
function Gui_Table:getColumnCount() end

--- Returns the row count of this Gui_Table widget.
---@return integer
function Gui_Table:getRowCount() end

--- Returns the selected row of this Gui_Table widget.
---@return nil
function Gui_Table:getSelectedRow() end

--- Returns true if sortable is enabled for this Gui_Table widget.
---@return boolean
function Gui_Table:isSortable() end

--- Sets the cell for this Gui_Table widget.
---@param row any
---@param col any
---@param text any
---@return nil
function Gui_Table:setCell(row, col, text) end

--- Registers a callback invoked when a table row is selected.
---@param f any
---@return nil
function Gui_Table:setOnSelect(f) end

--- Sets the selected row for this Gui_Table widget.
---@param row? any (optional)
---@return nil
function Gui_Table:setSelectedRow(row) end

--- Sets the sortable for this Gui_Table widget.
---@param v any
---@return nil
function Gui_Table:setSortable(v) end

--- Adds GUIWindow-specific methods.
---@class Gui_Window
local Gui_Window = {}

--- Returns the title of this Gui_Window widget.
---@return string
function Gui_Window:getTitle() end

--- Returns true if closeable is enabled for this Gui_Window widget.
---@return boolean
function Gui_Window:isCloseable() end

--- Returns true if draggable is enabled for this Gui_Window widget.
---@return boolean
function Gui_Window:isDraggable() end

--- Returns true if resizable is enabled for this Gui_Window widget.
---@return boolean
function Gui_Window:isResizable() end

--- Sets the closeable for this Gui_Window widget.
---@param v any
---@return nil
function Gui_Window:setCloseable(v) end

--- Sets the draggable for this Gui_Window widget.
---@param v any
---@return nil
function Gui_Window:setDraggable(v) end

--- Registers a callback invoked when this window is closed.
---@param f any
---@return nil
function Gui_Window:setOnClose(f) end

--- Sets the resizable for this Gui_Window widget.
---@param v any
---@return nil
function Gui_Window:setResizable(v) end

--- Sets the title for this Gui_Window widget.
---@param title any
---@return nil
function Gui_Window:setTitle(title) end

--- Adds ImageWidget-specific methods.
---@class Image_Widget
local Image_Widget = {}

--- Queues a toast notification from a table.
---@param toast_table any
---@return nil
function Image_Widget:addToast(toast_table) end

--- Clears keyboard focus.
---@return nil
function Image_Widget:clearFocus() end

--- Headless compatibility stub for GUI draw.
---@return nil
function Image_Widget:draw() end

--- Moves focus to the next focusable widget.
---@return nil
function Image_Widget:focusNext() end

--- Moves focus to the previous focusable widget.
---@return nil
function Image_Widget:focusPrev() end

--- Returns the focused widget index or nil.
---@return number
function Image_Widget:getFocus() end

--- Returns the root panel widget table.
---@return table
function Image_Widget:getRoot() end

--- Returns the scale mode of this Image_Widget widget.
---@return string
function Image_Widget:getScaleMode() end

--- Returns whether a theme is set.
---@return boolean
function Image_Widget:getTheme() end

--- Returns the tint of this Image_Widget widget.
---@return number
function Image_Widget:getTint() end

--- Returns the number of active toasts.
---@return number
function Image_Widget:getToastCount() end

--- Returns the total widget count in the context.
---@return number
function Image_Widget:getWidgetCount() end

--- Forwards a key press event to the GUI.
---@param key any
---@return boolean
function Image_Widget:keypressed(key) end

--- Forwards a mouse move event to the GUI.
---@param x any
---@param y any
---@return boolean
function Image_Widget:mousemoved(x, y) end

--- Forwards a mouse press event to the GUI.
---@param x any
---@param y any
---@param btn? any (optional)
---@return boolean
function Image_Widget:mousepressed(x, y, btn) end

--- Forwards a mouse release event to the GUI.
---@param x any
---@param y any
---@param btn? any (optional)
---@return boolean
function Image_Widget:mousereleased(x, y, btn) end

--- Creates a collapsible accordion widget.
---@return table
function Image_Widget:newAccordion() end

--- Creates a button widget.
---@param text? any (optional)
---@return table
function Image_Widget:newButton(text) end

--- Creates a checkbox widget.
---@param text? any (optional)
---@return table
function Image_Widget:newCheckbox(text) end

--- Creates a color picker widget.
---@return table
function Image_Widget:newColorPicker() end

--- Creates a dropdown combo box widget.
---@return table
function Image_Widget:newComboBox() end

--- Creates a modal dialog widget.
---@param title? any (optional)
---@return table
function Image_Widget:newDialog(title) end

--- Creates a dock panel.
---@return table
function Image_Widget:newDockPanel() end

--- Creates an image display widget.
---@return table
function Image_Widget:newImageWidget() end

--- Creates a text label widget.
---@param text? any (optional)
---@return table
function Image_Widget:newLabel(text) end

--- Creates a flexbox layout container.
---@param direction? any (optional)
---@return table
function Image_Widget:newLayout(direction) end

--- Creates a selectable list widget.
---@return table
function Image_Widget:newList() end

--- Creates a menu bar widget.
---@return table
function Image_Widget:newMenuBar() end

--- Creates a menu item widget.
---@param text? any (optional)
---@return table
function Image_Widget:newMenuItem(text) end

--- Creates a 9-patch slicer widget.
---@return table
function Image_Widget:newNinePatch() end

--- Creates a container panel widget.
---@return table
function Image_Widget:newPanel() end

--- Creates a progress bar widget.
---@param min? any (optional)
---@param max? any (optional)
---@return table
function Image_Widget:newProgressBar(min, max) end

--- Creates a grouped radio button widget.
---@param text? any (optional)
---@param group? any (optional)
---@return table
function Image_Widget:newRadioButton(text, group) end

--- Creates a scroll bar widget.
---@param vertical? any (optional)
---@return table
function Image_Widget:newScrollBar(vertical) end

--- Creates a scrollable panel widget.
---@return table
function Image_Widget:newScrollPanel() end

--- Creates a separator line.
---@param vertical? any (optional)
---@return table
function Image_Widget:newSeparator(vertical) end

--- Creates a value slider widget.
---@param min? any (optional)
---@param max? any (optional)
---@return table
function Image_Widget:newSlider(min, max) end

--- Creates a spacing filler widget.
---@param w? any (optional)
---@param h? any (optional)
---@return table
function Image_Widget:newSpacer(w, h) end

--- Creates a resizable split panel.
---@param orientation? any (optional)
---@return table
function Image_Widget:newSplitPanel(orientation) end

--- Creates a status bar widget.
---@return table
function Image_Widget:newStatusBar() end

--- Creates a tab bar widget.
---@return table
function Image_Widget:newTabBar() end

--- Creates a data table widget.
---@return table
function Image_Widget:newTable() end

--- Creates a text input widget.
---@return table
function Image_Widget:newTextInput() end

--- Creates a new theme instance.
---@return Theme
function Image_Widget:newTheme() end

--- Creates a toast notification widget.
---@param message? any (optional)
---@param duration? any (optional)
---@return table
function Image_Widget:newToast(message, duration) end

--- Creates a toolbar widget.
---@param orientation? any (optional)
---@return table
function Image_Widget:newToolbar(orientation) end

--- Creates a tooltip panel widget.
---@param text? any (optional)
---@return table
function Image_Widget:newTooltipPanel(text) end

--- Creates a collapsible tree view widget.
---@return table
function Image_Widget:newTreeView() end

--- Creates a draggable window widget.
---@param title? any (optional)
---@return table
function Image_Widget:newWindow(title) end

--- Sets keyboard focus to a widget or clears it.
---@param widget? any (optional)
---@return nil
function Image_Widget:setFocus(widget) end

--- Sets the scale mode for this Image_Widget widget.
---@param mode any
---@return nil
function Image_Widget:setScaleMode(mode) end

--- Sets the active GUI theme.
---@param theme_ud any
---@return nil
function Image_Widget:setTheme(theme_ud) end

--- Sets the tint for this Image_Widget widget.
---@param r any
---@param green any
---@param b any
---@param a? any (optional)
---@return nil
function Image_Widget:setTint(r, green, b, a) end

--- Forwards text input to the focused text input widget.
---@param text any
---@return boolean
function Image_Widget:textinput(text) end

--- Advances toast timers, removes expired toasts, and dispatches pending GUI events.
---@param dt any
---@return nil
function Image_Widget:update(dt) end

--- Forwards a mouse wheel event to the GUI.
---@param x any
---@param y any
---@return boolean
function Image_Widget:wheelmoved(x, y) end

--- Adds Label-specific methods to a widget table.
---@class Label
local Label = {}

--- Returns the text of this Label widget.
---@return string
function Label:getText() end

--- Sets the text for this Label widget.
---@param text any
---@return nil
function Label:setText(text) end

--- Adds Layout-specific methods.
---@class Layout
local Layout = {}

--- Returns the align of this Layout widget.
---@return string
function Layout:getAlign() end

--- Returns the direction of this Layout widget.
---@return string
function Layout:getDirection() end

--- Returns the justify of this Layout widget.
---@return string
function Layout:getJustify() end

--- Returns the spacing of this Layout widget.
---@return number
function Layout:getSpacing() end

--- Returns the wrap of this Layout widget.
---@return boolean
function Layout:getWrap() end

--- Sets the align for this Layout widget.
---@param align any
---@return nil
function Layout:setAlign(align) end

--- Sets the columns for this Layout widget.
---@param n any
---@return nil
function Layout:setColumns(n) end

--- Sets the direction for this Layout widget.
---@param dir any
---@return nil
function Layout:setDirection(dir) end

--- Sets the justify for this Layout widget.
---@param justify any
---@return nil
function Layout:setJustify(justify) end

--- Sets the spacing for this Layout widget.
---@param spacing any
---@return nil
function Layout:setSpacing(spacing) end

--- Sets the wrap for this Layout widget.
---@param wrap any
---@return nil
function Layout:setWrap(wrap) end

--- Adds ListBox-specific methods (1-based indices in Lua).
---@class List_Box
local List_Box = {}

--- Adds a item entry to this List_Box widget.
---@param text any
---@return nil
function List_Box:addItem(text) end

--- Clears all items entries from this List_Box widget.
---@return nil
function List_Box:clearItems() end

--- Returns the item of this List_Box widget.
---@param index any
---@return string
function List_Box:getItem(index) end

--- Returns the item count of this List_Box widget.
---@return integer
function List_Box:getItemCount() end

--- Returns the selected index of this List_Box widget.
---@return integer
function List_Box:getSelectedIndex() end

--- Removes the item from this List_Box widget.
---@param index any
---@return nil
function List_Box:removeItem(index) end

--- Sets the item height for this List_Box widget.
---@param h any
---@return nil
function List_Box:setItemHeight(h) end

--- Sets the selected index for this List_Box widget.
---@param index any
---@return nil
function List_Box:setSelectedIndex(index) end

--- Adds MenuBar-specific methods.
---@class Menu_Bar
local Menu_Bar = {}

--- Adds a menu entry to this Menu_Bar widget.
---@param menu_idx any
---@return nil
function Menu_Bar:addMenu(menu_idx) end

--- Returns the menu count of this Menu_Bar widget.
---@return integer
function Menu_Bar:getMenuCount() end

--- Returns the menus of this Menu_Bar widget.
---@return nil
function Menu_Bar:getMenus() end

--- Removes the menu from this Menu_Bar widget.
---@param menu_idx any
---@return nil
function Menu_Bar:removeMenu(menu_idx) end

--- Adds MenuItem-specific methods.
---@class Menu_Item
local Menu_Item = {}

--- Adds a sub item entry to this Menu_Item widget.
---@param child_idx any
---@return nil
function Menu_Item:addSubItem(child_idx) end

--- Returns the shortcut of this Menu_Item widget.
---@return string
function Menu_Item:getShortcut() end

--- Returns the sub items of this Menu_Item widget.
---@return nil
function Menu_Item:getSubItems() end

--- Returns the text of this Menu_Item widget.
---@return string
function Menu_Item:getText() end

--- Returns true if checked is enabled for this Menu_Item widget.
---@return boolean
function Menu_Item:isChecked() end

--- Sets the checked for this Menu_Item widget.
---@param v any
---@return nil
function Menu_Item:setChecked(v) end

--- Registers a callback invoked when this menu item is clicked.
---@param f any
---@return nil
function Menu_Item:setOnClick(f) end

--- Sets the shortcut for this Menu_Item widget.
---@param shortcut any
---@return nil
function Menu_Item:setShortcut(shortcut) end

--- Sets the text for this Menu_Item widget.
---@param text any
---@return nil
function Menu_Item:setText(text) end

--- Adds NinePatch-specific methods.
---@class Nine_Patch
local Nine_Patch = {}

--- Returns the image dimensions of this Nine_Patch widget.
---@return integer
function Nine_Patch:getImageDimensions() end

--- Returns the insets of this Nine_Patch widget.
---@return integer
function Nine_Patch:getInsets() end

--- Returns the slices of this Nine_Patch widget.
---@return table
function Nine_Patch:getSlices() end

--- Sets the image dimensions for this Nine_Patch widget.
---@param w any
---@param h any
---@return nil
function Nine_Patch:setImageDimensions(w, h) end

--- Sets the insets for this Nine_Patch widget.
---@param left any
---@param top any
---@param right any
---@param bottom any
---@return nil
function Nine_Patch:setInsets(left, top, right, bottom) end

--- Adds Panel-specific methods.
---@class Panel
local Panel = {}

--- Returns the title of this Panel widget.
---@return string
function Panel:getTitle() end

--- Sets the scrollable for this Panel widget.
---@param scrollable any
---@return nil
function Panel:setScrollable(scrollable) end

--- Sets the title for this Panel widget.
---@param title any
---@return nil
function Panel:setTitle(title) end

--- Adds ProgressBar-specific methods to a widget table.
---@class Progress_Bar
local Progress_Bar = {}

--- Returns the max of this Progress_Bar widget.
---@return number
function Progress_Bar:getMax() end

--- Returns the min of this Progress_Bar widget.
---@return number
function Progress_Bar:getMin() end

--- Returns the progress of this Progress_Bar widget.
---@return number
function Progress_Bar:getProgress() end

--- Returns the value of this Progress_Bar widget.
---@return number
function Progress_Bar:getValue() end

--- Sets the range for this Progress_Bar widget.
---@param min any
---@param max any
---@return nil
function Progress_Bar:setRange(min, max) end

--- Sets the value for this Progress_Bar widget.
---@param v any
---@return nil
function Progress_Bar:setValue(v) end

--- Adds RadioButton-specific methods.
---@class Radio_Button
local Radio_Button = {}

--- Returns the group of this Radio_Button widget.
---@return string
function Radio_Button:getGroup() end

--- Returns the text of this Radio_Button widget.
---@return string
function Radio_Button:getText() end

--- Returns true if selected is enabled for this Radio_Button widget.
---@return boolean
function Radio_Button:isSelected() end

--- Sets the group for this Radio_Button widget.
---@param group any
---@return nil
function Radio_Button:setGroup(group) end

--- Registers a callback invoked when this widget's value changes.
---@param f any
---@return nil
function Radio_Button:setOnChange(f) end

--- Sets the selected for this Radio_Button widget.
---@param v any
---@return nil
function Radio_Button:setSelected(v) end

--- Sets the text for this Radio_Button widget.
---@param text any
---@return nil
function Radio_Button:setText(text) end

--- Adds ScrollBar-specific methods.
---@class Scroll_Bar
local Scroll_Bar = {}

--- Returns the content size of this Scroll_Bar widget.
---@return number
function Scroll_Bar:getContentSize() end

--- Returns the scroll position of this Scroll_Bar widget.
---@return number
function Scroll_Bar:getScrollPosition() end

--- Returns the view size of this Scroll_Bar widget.
---@return number
function Scroll_Bar:getViewSize() end

--- Returns true if vertical is enabled for this Scroll_Bar widget.
---@return boolean
function Scroll_Bar:isVertical() end

--- Sets the content size for this Scroll_Bar widget.
---@param v any
---@return nil
function Scroll_Bar:setContentSize(v) end

--- Registers a callback invoked when this widget's value changes.
---@param f any
---@return nil
function Scroll_Bar:setOnChange(f) end

--- Sets the scroll position for this Scroll_Bar widget.
---@param v any
---@return nil
function Scroll_Bar:setScrollPosition(v) end

--- Sets the view size for this Scroll_Bar widget.
---@param v any
---@return nil
function Scroll_Bar:setViewSize(v) end

--- Adds ScrollPanel-specific methods.
---@class Scroll_Panel
local Scroll_Panel = {}

--- Returns the content size of this Scroll_Panel widget.
---@return number
function Scroll_Panel:getContentSize() end

--- Returns the max scroll of this Scroll_Panel widget.
---@return number
function Scroll_Panel:getMaxScroll() end

--- Returns the scroll position of this Scroll_Panel widget.
---@return number
function Scroll_Panel:getScrollPosition() end

--- Returns the scroll speed of this Scroll_Panel widget.
---@return number
function Scroll_Panel:getScrollSpeed() end

--- Sets the content size for this Scroll_Panel widget.
---@param w any
---@param h any
---@return nil
function Scroll_Panel:setContentSize(w, h) end

--- Sets the scroll position for this Scroll_Panel widget.
---@param x any
---@param y any
---@return nil
function Scroll_Panel:setScrollPosition(x, y) end

--- Sets the scroll speed for this Scroll_Panel widget.
---@param speed any
---@return nil
function Scroll_Panel:setScrollSpeed(speed) end

--- Adds Separator-specific methods.
---@class Separator
local Separator = {}

--- Returns the thickness of this Separator widget.
---@return number
function Separator:getThickness() end

--- Returns true if vertical is enabled for this Separator widget.
---@return boolean
function Separator:isVertical() end

--- Sets the thickness for this Separator widget.
---@param thickness any
---@return nil
function Separator:setThickness(thickness) end

--- Sets the vertical for this Separator widget.
---@param v any
---@return nil
function Separator:setVertical(v) end

--- Adds Slider-specific methods to a widget table.
---@class Slider
local Slider = {}

--- Returns the max of this Slider widget.
---@return number
function Slider:getMax() end

--- Returns the min of this Slider widget.
---@return number
function Slider:getMin() end

--- Returns the value of this Slider widget.
---@return number
function Slider:getValue() end

--- Sets the range for this Slider widget.
---@param min any
---@param max any
---@return nil
function Slider:setRange(min, max) end

--- Sets the step for this Slider widget.
---@param step any
---@return nil
function Slider:setStep(step) end

--- Sets the value for this Slider widget.
---@param v any
---@return nil
function Slider:setValue(v) end

--- Adds SplitPanel-specific methods.
---@class Split_Panel
local Split_Panel = {}

--- Returns the first child of this Split_Panel widget.
---@return nil
function Split_Panel:getFirstChild() end

--- Returns the min panel size of this Split_Panel widget.
---@return number
function Split_Panel:getMinPanelSize() end

--- Returns the orientation of this Split_Panel widget.
---@return string
function Split_Panel:getOrientation() end

--- Returns the second child of this Split_Panel widget.
---@return nil
function Split_Panel:getSecondChild() end

--- Returns the split position of this Split_Panel widget.
---@return number
function Split_Panel:getSplitPosition() end

--- Sets the first child for this Split_Panel widget.
---@param child_idx any
---@return nil
function Split_Panel:setFirstChild(child_idx) end

--- Sets the min panel size for this Split_Panel widget.
---@param v any
---@return nil
function Split_Panel:setMinPanelSize(v) end

--- Sets the orientation for this Split_Panel widget.
---@param v any
---@return nil
function Split_Panel:setOrientation(v) end

--- Sets the second child for this Split_Panel widget.
---@param child_idx any
---@return nil
function Split_Panel:setSecondChild(child_idx) end

--- Sets the split position for this Split_Panel widget.
---@param v any
---@return nil
function Split_Panel:setSplitPosition(v) end

--- Adds StatusBar-specific methods.
---@class Status_Bar
local Status_Bar = {}

--- Adds a section entry to this Status_Bar widget.
---@param text any
---@param width? any (optional)
---@return nil
function Status_Bar:addSection(text, width) end

--- Returns the section count of this Status_Bar widget.
---@return integer
function Status_Bar:getSectionCount() end

--- Returns the section text of this Status_Bar widget.
---@param section_idx any
---@return integer
function Status_Bar:getSectionText(section_idx) end

--- Resizes the section list for this Status_Bar widget.
---@param count any
---@return nil
function Status_Bar:setSectionCount(count) end

--- Sets the section text for this Status_Bar widget.
---@param section_idx any
---@param text any
---@return nil
function Status_Bar:setSectionText(section_idx, text) end

--- Compatibility shim for assigning a widget to a section.
---@param section_idx any
---@param widget any
---@return nil
function Status_Bar:setSectionWidget(section_idx, widget) end

--- Adds TabBar-specific methods (1-based indices in Lua).
---@class Tab_Bar
local Tab_Bar = {}

--- Adds a tab entry to this Tab_Bar widget.
---@param label any
---@return nil
function Tab_Bar:addTab(label) end

--- Returns the active tab of this Tab_Bar widget.
---@return integer
function Tab_Bar:getActiveTab() end

--- Returns the tab of this Tab_Bar widget.
---@param index any
---@return integer
function Tab_Bar:getTab(index) end

--- Returns the tab count of this Tab_Bar widget.
---@return integer
function Tab_Bar:getTabCount() end

--- Removes the tab from this Tab_Bar widget.
---@param index any
---@return nil
function Tab_Bar:removeTab(index) end

--- Sets the active tab for this Tab_Bar widget.
---@param index any
---@return nil
function Tab_Bar:setActiveTab(index) end

--- Adds TextInput-specific methods to a widget table.
---@class Text_Input
local Text_Input = {}

--- Returns the cursor position of this Text_Input widget.
---@return integer
function Text_Input:getCursorPosition() end

--- Returns the placeholder of this Text_Input widget.
---@return string
function Text_Input:getPlaceholder() end

--- Returns the text of this Text_Input widget.
---@return string
function Text_Input:getText() end

--- Returns true if focused is enabled for this Text_Input widget.
---@return boolean
function Text_Input:isFocused() end

--- Sets the max length for this Text_Input widget.
---@param n any
---@return nil
function Text_Input:setMaxLength(n) end

--- Sets the placeholder for this Text_Input widget.
---@param text any
---@return nil
function Text_Input:setPlaceholder(text) end

--- Sets the text for this Text_Input widget.
---@param text any
---@return nil
function Text_Input:setText(text) end

--- Adds Toast-specific methods.
---@class Toast
local Toast = {}

--- Returns the duration of this Toast widget.
---@return number
function Toast:getDuration() end

--- Returns the message of this Toast widget.
---@return string
function Toast:getMessage() end

--- Returns the progress of this Toast widget.
---@return number
function Toast:getProgress() end

--- Returns true if expired is enabled for this Toast widget.
---@return boolean
function Toast:isExpired() end

--- Sets the duration for this Toast widget.
---@param d any
---@return nil
function Toast:setDuration(d) end

--- Sets the message for this Toast widget.
---@param msg any
---@return nil
function Toast:setMessage(msg) end

--- Adds Toolbar-specific methods.
---@class Toolbar
local Toolbar = {}

--- Adds a button entry to this Toolbar widget.
---@param id any
---@param tooltip? any (optional)
---@return nil
function Toolbar:addButton(id, tooltip) end

--- Adds a separator entry to this Toolbar widget.
---@return nil
function Toolbar:addSeparator() end

--- Adds a spacer entry to this Toolbar widget.
---@param size? any (optional)
---@return nil
function Toolbar:addSpacer(size) end

--- Returns the button of this Toolbar widget.
---@param id any
---@return boolean
function Toolbar:getButton(id) end

--- Returns the orientation of this Toolbar widget.
---@return string
function Toolbar:getOrientation() end

--- Returns true if button toggled is enabled for this Toolbar widget.
---@param id any
---@return boolean
function Toolbar:isButtonToggled(id) end

--- Sets the button enabled for this Toolbar widget.
---@param id any
---@param enabled any
---@return nil
function Toolbar:setButtonEnabled(id, enabled) end

--- Sets the button toggled for this Toolbar widget.
---@param id any
---@param toggled any
---@return nil
function Toolbar:setButtonToggled(id, toggled) end

--- Sets the orientation for this Toolbar widget.
---@param v any
---@return nil
function Toolbar:setOrientation(v) end

--- Adds TooltipPanel-specific methods.
---@class Tooltip_Panel
local Tooltip_Panel = {}

--- Returns the delay of this Tooltip_Panel widget.
---@return number
function Tooltip_Panel:getDelay() end

--- Returns the target of this Tooltip_Panel widget.
---@return nil
function Tooltip_Panel:getTarget() end

--- Returns the text of this Tooltip_Panel widget.
---@return string
function Tooltip_Panel:getText() end

--- Sets the delay for this Tooltip_Panel widget.
---@param v any
---@return nil
function Tooltip_Panel:setDelay(v) end

--- Sets the target for this Tooltip_Panel widget.
---@param target? any (optional)
---@return nil
function Tooltip_Panel:setTarget(target) end

--- Sets the text for this Tooltip_Panel widget.
---@param text any
---@return nil
function Tooltip_Panel:setText(text) end

--- Adds TreeView-specific methods (1-based indices in Lua).
---@class Tree_View
local Tree_View = {}

--- Adds a node entry to this Tree_View widget.
---@param text any
---@param parent_index? any (optional)
---@return nil
function Tree_View:addNode(text, parent_index) end

--- Clears all nodes entries from this Tree_View widget.
---@return nil
function Tree_View:clearNodes() end

--- Performs the collapse all operation on this Tree_View widget.
---@return nil
function Tree_View:collapseAll() end

--- Performs the collapse node operation on this Tree_View widget.
---@param index any
---@return nil
function Tree_View:collapseNode(index) end

--- Performs the expand all operation on this Tree_View widget.
---@return nil
function Tree_View:expandAll() end

--- Performs the expand node operation on this Tree_View widget.
---@param index any
---@return nil
function Tree_View:expandNode(index) end

--- Returns the child nodes of this Tree_View widget.
---@param index any
---@return nil
function Tree_View:getChildNodes(index) end

--- Returns the node count of this Tree_View widget.
---@return integer
function Tree_View:getNodeCount() end

--- Returns the node depth of this Tree_View widget.
---@param index any
---@return nil
function Tree_View:getNodeDepth(index) end

--- Returns the node text of this Tree_View widget.
---@param index any
---@return string
function Tree_View:getNodeText(index) end

--- Returns the parent node of this Tree_View widget.
---@param index any
---@return nil
function Tree_View:getParentNode(index) end

--- Returns the selected node of this Tree_View widget.
---@return integer
function Tree_View:getSelectedNode() end

--- Returns true if expanded is enabled for this Tree_View widget.
---@param index any
---@return boolean
function Tree_View:isExpanded(index) end

--- Returns true if node expanded is enabled for this Tree_View widget.
---@param index any
---@return boolean
function Tree_View:isNodeExpanded(index) end

--- Removes the node from this Tree_View widget.
---@param index any
---@return nil
function Tree_View:removeNode(index) end

--- Sets the node icon for this Tree_View widget.
---@param index any
---@param icon any
---@return nil
function Tree_View:setNodeIcon(index, icon) end

--- Sets the node text for this Tree_View widget.
---@param index any
---@param text any
---@return nil
function Tree_View:setNodeText(index, text) end

--- Sets the selected node for this Tree_View widget.
---@param index any
---@return nil
function Tree_View:setSelectedNode(index) end

--- Toggles the expanded/collapsed status of a Tree_View node.
---@param index any
---@return nil
function Tree_View:toggleNode(index) end

--- Adds a child widget to this container.
---@param child any
---@return nil
function lurek.ui.addChild(child) end

--- Removes all anchor constraints.
---@return nil
function lurek.ui.clearAnchor() end

--- Returns whether (x, y) is inside this widget.
---@param x any
---@param y any
---@return boolean
function lurek.ui.containsPoint(x, y) end

--- Recursively searches for a widget by id starting from this widget.
---@param id any
---@return table
function lurek.ui.findById(id) end

--- Returns the number of children in this container.
---@return number
function lurek.ui.getChildCount() end

--- Returns the flex-grow factor.
---@return number
function lurek.ui.getFlexGrow() end

--- Returns the flex-shrink factor.
---@return number
function lurek.ui.getFlexShrink() end

--- Returns the widget string identifier.
---@return string
function lurek.ui.getId() end

--- Returns the widget margin (top, right, bottom, left).
---@return number
function lurek.ui.getMargin() end

--- Returns the maximum widget size.
---@return number
function lurek.ui.getMaxSize() end

--- Returns the minimum widget size.
---@return number
function lurek.ui.getMinSize() end

--- Returns the widget padding (top, right, bottom, left).
---@return number
function lurek.ui.getPadding() end

--- Returns the widget position.
---@return number
function lurek.ui.getPosition() end

--- Returns the widget size.
---@return number
function lurek.ui.getSize() end

--- Returns the widget interaction state name.
---@return string
function lurek.ui.getState() end

--- Returns the widget tooltip text.
---@return string
function lurek.ui.getTooltip() end

--- Returns the widget z-order.
---@return number
function lurek.ui.getZOrder() end

--- Returns whether the widget is enabled.
---@return boolean
function lurek.ui.isEnabled() end

--- Returns whether the widget is visible.
---@return boolean
function lurek.ui.isVisible() end

--- Removes a child widget from this container.
---@param child any
---@return nil
function lurek.ui.removeChild(child) end

--- Sets anchor edges (left, top, right, bottom).
---@param left number
---@param top number
---@param right number
---@param bottom number
---@return nil
function lurek.ui.setAnchor(left, top, right, bottom) end

--- Sets center anchor offsets.
---@param cx? any (optional)
---@param cy? any (optional)
---@return nil
function lurek.ui.setAnchorCenter(cx, cy) end

--- Sets whether the widget is enabled.
---@param v any
---@return nil
function lurek.ui.setEnabled(v) end

--- Sets the flex-grow factor.
---@param grow any
---@return nil
function lurek.ui.setFlexGrow(grow) end

--- Sets the flex-shrink factor.
---@param shrink any
---@return nil
function lurek.ui.setFlexShrink(shrink) end

--- Sets the widget string identifier.
---@param id any
---@return nil
function lurek.ui.setId(id) end

--- Sets widget margin (CSS-like: top, right?, bottom?, left?).
---@param top any
---@param right? any (optional)
---@param bottom? any (optional)
---@param left? any (optional)
---@return nil
function lurek.ui.setMargin(top, right, bottom, left) end

--- Sets the maximum widget size.
---@param w any
---@param h any
---@return nil
function lurek.ui.setMaxSize(w, h) end

--- Sets the minimum widget size.
---@param w any
---@param h any
---@return nil
function lurek.ui.setMinSize(w, h) end

--- Registers a callback invoked when this widget's value changes.
---@param f any
---@return nil
function lurek.ui.setOnChange(f) end

--- Registers a callback invoked when this widget is clicked.
---@param f any
---@return nil
function lurek.ui.setOnClick(f) end

--- Stores a custom draw callback for later invocation.
---@param f any
---@return nil
function lurek.ui.setOnDraw(f) end

--- Sets widget padding (CSS-like: top, right?, bottom?, left?).
---@param top any
---@param right? any (optional)
---@param bottom? any (optional)
---@param left? any (optional)
---@return nil
function lurek.ui.setPadding(top, right, bottom, left) end

--- Sets the widget position.
---@param x any
---@param y any
---@return nil
function lurek.ui.setPosition(x, y) end

--- Sets the widget size.
---@param w any
---@param h any
---@return nil
function lurek.ui.setSize(w, h) end

--- Sets the widget tooltip text.
---@param text any
---@return nil
function lurek.ui.setTooltip(text) end

--- Sets widget visibility.
---@param v any
---@return nil
function lurek.ui.setVisible(v) end

--- Sets the widget z-order for draw sorting.
---@param z any
---@return nil
function lurek.ui.setZOrder(z) end

---@class lurek.window
lurek.window = {}

--- Requests the window to close.
---@return nil
function lurek.window.close() end

--- Requests the window manager to bring the window to the foreground.
---@return nil
function lurek.window.focus() end

--- Converts physical pixels to device-independent coordinates.
---@param value any
---@return number
function lurek.window.fromPixels(value) end

--- Returns the DPI scaling factor for the window.
---@return number
function lurek.window.getDPIScale() end

--- Returns the desktop resolution as width, height.
---@return integer
function lurek.window.getDesktopDimensions() end

--- Returns the window dimensions as width, height.
---@return integer
function lurek.window.getDimensions() end

--- Returns the number of connected displays.
---@return integer
function lurek.window.getDisplayCount() end

--- Returns the name of the current display.
---@param display? any (optional)
---@return string
function lurek.window.getDisplayName(display) end

--- Returns the current display orientation.
---@return string
function lurek.window.getDisplayOrientation() end

--- Returns the fullscreen state and type string.
---@return boolean
function lurek.window.getFullscreen() end

--- Returns all available fullscreen video modes.
---@return table
function lurek.window.getFullscreenModes() end

--- Returns the logical game height in virtual pixels.
---@return number
function lurek.window.getGameHeight() end

--- Returns the logical game width in virtual pixels.
---@return number
function lurek.window.getGameWidth() end

--- Returns the window height in pixels.
---@return integer
function lurek.window.getHeight() end

--- Returns the window dimensions and mode flags as width, height, flags.
---@return integer
function lurek.window.getMode() end

--- Returns the native DPI scale factor.
---@return number
function lurek.window.getNativeDPIScale() end

--- Returns the window dimensions in physical pixels.
---@return integer
function lurek.window.getPixelDimensions() end

--- Returns the window position as x, y in screen coordinates.
---@return integer
function lurek.window.getPosition() end

--- Returns the safe display area as x, y, w, h.
---@return number
function lurek.window.getSafeArea() end

--- Returns viewport scale and offset information as a table.
---@return table
function lurek.window.getScaleInfo() end

--- Returns the current viewport scale mode string.
---@return string
function lurek.window.getScaleMode() end

--- Returns the OS color theme preference.
---@return string
function lurek.window.getSystemTheme() end

--- Returns the current window title.
---@return string
function lurek.window.getTitle() end

--- Returns the current VSync mode integer.
---@return integer
function lurek.window.getVSync() end

--- Returns the window width in pixels.
---@return integer
function lurek.window.getWidth() end

--- Returns whether the window has keyboard focus.
---@return boolean
function lurek.window.hasFocus() end

--- Returns whether the mouse cursor is inside the window.
---@return boolean
function lurek.window.hasMouseFocus() end

--- Returns whether the window is in fullscreen mode.
---@return boolean
function lurek.window.isFullscreen() end

--- Returns whether high-DPI rendering is allowed.
---@return boolean
function lurek.window.isHighDPIAllowed() end

--- Returns whether the window is maximized.
---@return boolean
function lurek.window.isMaximized() end

--- Returns whether the window is minimized.
---@return boolean
function lurek.window.isMinimized() end

--- Returns whether the window is open.
---@return boolean
function lurek.window.isOpen() end

--- Returns whether the window can be resized by the user.
---@return boolean
function lurek.window.isResizable() end

--- Returns whether the window is visible.
---@return boolean
function lurek.window.isVisible() end

--- Maximizes the window to fill the desktop.
---@return nil
function lurek.window.maximize() end

--- Minimizes the window to the taskbar.
---@return nil
function lurek.window.minimize() end

--- Flashes the window in the taskbar to request user attention.
---@return nil
function lurek.window.requestAttention() end

--- Restores the window from minimized or maximized state.
---@return nil
function lurek.window.restore() end

--- Enables or disables fullscreen mode.
---@param enabled any
---@param fstype? any (optional)
---@return nil
function lurek.window.setFullscreen(enabled, fstype) end

--- Sets the window icon from a file path.
---@param path any
---@return nil
function lurek.window.setIcon(path) end

--- Resizes the window and optionally changes fullscreen and vsync.
---@param w any
---@param h any
---@param flags? any (optional)
---@return nil
function lurek.window.setMode(w, h, flags) end

--- Moves the window to the given screen position.
---@param x any
---@param y any
---@return nil
function lurek.window.setPosition(x, y) end

--- Sets the viewport scale mode.
---@param mode any
---@return nil
function lurek.window.setScaleMode(mode) end

--- Sets the window title bar text.
---@param title any
---@return nil
function lurek.window.setTitle(title) end

--- Sets the VSync mode (1=on, 0=off, -1=adaptive).
---@param mode any
---@return nil
function lurek.window.setVSync(mode) end

--- Shows a platform-native message box dialog.
---@param title string
---@param message string
---@param boxType? string? (optional)
---@param btnType? string? (optional)
---@return string
function lurek.window.showMessageBox(title, message, boxType, btnType) end

--- Converts a device-independent coordinate to physical pixels.
---@param value any
---@return number
function lurek.window.toPixels(value) end
