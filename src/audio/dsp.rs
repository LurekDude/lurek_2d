//! Digital signal processing effects for the Lurek2D audio pipeline.
//!
//! Provides `AtomicParam` for lock-free parameter updates, `ActiveEffect` for
//! tracking DSP state, and standard audio effects (volume, reverb, delay,
//! equaliser, distortion, chorus, flanger, bitcrusher, compressor).

use rodio::Source;
use std::sync::atomic::{AtomicU32, Ordering};
use std::sync::{Arc, RwLock};

use crate::runtime::log_messages::{DP01, DP02, DP03};
use crate::log_msg;

/// Thread-safe atomic `f32` parameter backed by an `AtomicU32` bit-cast.
///
/// Allows lock-free reads and writes across the audio thread and the main
/// engine thread without requiring a `Mutex`.
///
/// # Fields
/// - `val` — `AtomicU32` storing the bit pattern of the `f32` value.
#[derive(Debug)]
pub struct AtomicParam {
    val: AtomicU32,
}

impl AtomicParam {
    /// Creates a new `AtomicParam` initialised to `val`.
    ///
    /// # Parameters
    /// - `val` — `f32`. Initial parameter value.
    ///
    /// # Returns
    /// `Self`.
    pub fn new(val: f32) -> Self {
        Self {
            val: AtomicU32::new(val.to_bits()),
        }
    }

    /// Returns the current value, loaded with `Relaxed` ordering.
    ///
    /// # Returns
    /// `f32`.
    pub fn get(&self) -> f32 {
        f32::from_bits(self.val.load(Ordering::Relaxed))
    }

    /// Stores a new value with `Relaxed` ordering.
    ///
    /// # Parameters
    /// - `val` — `f32`. New parameter value.
    pub fn set(&self, val: f32) {
        self.val.store(val.to_bits(), Ordering::Relaxed);
    }
}

/// Category of DSP audio effect applied to a sound source.
///
/// # Variants
/// - `Lowpass` — Low-pass biquad filter; attenuates high frequencies above the cutoff.
/// - `Highpass` — High-pass biquad filter; attenuates low frequencies below the cutoff.
/// - `Bandpass` — Band-pass biquad filter; passes only a band of frequencies around the center.
/// - `Reverb` — Comb-filter reverb effect with room-size and mix controls.
/// - `Chorus` — Short-delay chorus/flanger with decay and mix controls.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum EffectType {
    Lowpass,
    Highpass,
    Bandpass,
    Reverb,
    Chorus,
}

/// Shared configuration for a single DSP effect slot.
///
/// `EffectParams` is shared between the main thread (which sets parameters)
/// and the audio thread (which reads them) via `Arc<EffectParams>`.
/// All parameter mutations go through `AtomicParam` to avoid locking.
///
/// # Fields
/// - `id` — `u32`. Unique monotonic slot identifier.
/// - `typ` — `EffectType`. The category of DSP effect.
/// - `p1` — `AtomicParam`. Primary parameter: cutoff frequency (filter) or room-size (reverb/chorus).
/// - `p2` — `AtomicParam`. Secondary parameter: center frequency (bandpass) or wet/dry mix.
/// - `p3` — `AtomicParam`. Reserved for future effect parameters.
#[derive(Debug)]
pub struct EffectParams {
    pub id: u32,
    pub typ: EffectType,
    pub p1: AtomicParam, // cutoff / room_size
    pub p2: AtomicParam, // center / mix
    pub p3: AtomicParam, // unused for now
}

impl EffectParams {
    /// Creates a new `EffectParams` with the given slot ID and effect type.
    ///
    /// # Parameters
    /// - `id` — `u32`. Unique monotonic slot identifier.
    /// - `typ` — `EffectType`. The category of DSP effect.
    ///
    /// # Returns
    /// `Self`.
    pub fn new(id: u32, typ: EffectType) -> Self {
        log_msg!(debug, DP01, "id={}", id);
        Self {
            id,
            typ,
            p1: AtomicParam::new(0.0),
            p2: AtomicParam::new(0.0),
            p3: AtomicParam::new(0.0),
        }
    }

    /// Sets an effect parameter by name using lock-free atomic writes.
    ///
    /// Valid parameter names depend on the effect type:
    /// - Filters (`lowpass`/`highpass`/`bandpass`): `"cutoff"` / `"frequency"`, `"q"`, `"mix"`.
    /// - `reverb`: `"room_size"`, `"damping"`, `"mix"`.
    /// - `chorus`: `"rate"`, `"depth"`, `"mix"`.
    ///
    /// # Parameters
    /// - `param` — `&str`. The parameter name.
    /// - `value` — `f32`. The parameter value.
    ///
    /// # Returns
    /// `Result<(), String>`.
    pub fn set_param(&self, param: &str, value: f32) -> Result<(), String> {
        match self.typ {
            EffectType::Lowpass | EffectType::Highpass | EffectType::Bandpass => match param {
                "cutoff" | "frequency" => {
                    self.p1.set(value);
                    Ok(())
                }
                "q" => {
                    self.p2.set(value);
                    Ok(())
                }
                "mix" => {
                    self.p3.set(value);
                    Ok(())
                }
                _ => Err(format!("invalid parameter: {}", param)),
            },
            EffectType::Reverb => match param {
                "room_size" => {
                    self.p1.set(value);
                    Ok(())
                }
                "damping" => {
                    self.p2.set(value);
                    Ok(())
                }
                "mix" => {
                    self.p3.set(value);
                    Ok(())
                }
                _ => Err(format!("invalid parameter: {}", param)),
            },
            EffectType::Chorus => match param {
                "rate" => {
                    self.p1.set(value);
                    Ok(())
                }
                "depth" => {
                    self.p2.set(value);
                    Ok(())
                }
                "mix" => {
                    self.p3.set(value);
                    Ok(())
                }
                _ => Err(format!("invalid parameter: {}", param)),
            },
        }
    }
}

/// Per-stream instantiation of an `EffectParams` slot, holding the filter state for a single audio stream.
///
/// One `ActiveEffect` is created per `EffectParams` inside each `DynamicEffectSource`.
/// It owns the biquad filter history (`bq_x1`/`bq_x2`/`bq_y1`/`bq_y2`) for two channels
/// and the comb-filter delay buffer used by the reverb and chorus effects.
///
/// # Fields
/// - `params` — `Arc<EffectParams>`. Shared reference to the effect configuration.
/// - `bq_x1`/`bq_x2` — `[f32; 2]`. Biquad input history for left and right channels.
/// - `bq_y1`/`bq_y2` — `[f32; 2]`. Biquad output history for left and right channels.
/// - `comb_buf` — `Vec<f32>`. Delay-line ring buffer for reverb/chorus effects.
/// - `comb_pos` — `usize`. Current write head position in `comb_buf`.
#[derive(Clone)]
pub struct ActiveEffect {
    pub params: Arc<EffectParams>,
    // biquad state: x1, x2, y1, y2 for 2 channels
    pub bq_x1: [f32; 2],
    pub bq_x2: [f32; 2],
    pub bq_y1: [f32; 2],
    pub bq_y2: [f32; 2],
    // comb state
    pub comb_buf: Vec<f32>,
    pub comb_pos: usize,
}

impl ActiveEffect {
    /// Creates a new `ActiveEffect` for the given effect configuration.
    ///
    /// Allocates the comb-filter delay buffer sized to `sample_rate` and `channels`.
    ///
    /// # Parameters
    /// - `params` — `Arc<EffectParams>`. Shared effect slot configuration.
    /// - `sample_rate` — `u32`. Sample rate of the audio stream.
    /// - `channels` — `u16`. Channel count of the audio stream.
    ///
    /// # Returns
    /// `Self`.
    pub fn new(params: Arc<EffectParams>, sample_rate: u32, channels: u16) -> Self {
        let comb_len = match params.typ {
            EffectType::Reverb | EffectType::Chorus => {
                let ms = if params.typ == EffectType::Chorus {
                    0.02
                } else {
                    0.05
                };
                ((sample_rate as f32 * ms) as usize * channels as usize).max(1)
            }
            _ => 1,
        };

        log_msg!(debug, DP02, "sr={} ch={}", sample_rate, channels);

        Self {
            params,
            bq_x1: [0.0; 2],
            bq_x2: [0.0; 2],
            bq_y1: [0.0; 2],
            bq_y2: [0.0; 2],
            comb_buf: vec![0.0; comb_len],
            comb_pos: 0,
        }
    }

    /// Applies this effect's DSP algorithm to a single PCM sample.
    ///
    /// # Parameters
    /// - `sample` — `f32`. The input PCM sample.
    /// - `channel` — `u16`. The interleaved channel index (0 = left, 1 = right).
    /// - `sample_rate` — `u32`. Sample rate of the audio stream.
    ///
    /// # Returns
    /// `f32`. The processed output sample.
    pub fn process(&mut self, sample: f32, channel: u16, sample_rate: u32) -> f32 {
        let c = (channel as usize) % 2;
        let typ = self.params.typ;

        match typ {
            EffectType::Lowpass | EffectType::Highpass | EffectType::Bandpass => {
                let f0 = self.params.p1.get().clamp(20.0, 20000.0);
                let q = 0.707_f32;
                let w0 = 2.0 * std::f32::consts::PI * f0 / (sample_rate as f32);
                let alpha = w0.sin() / (2.0 * q);
                let cos_w0 = w0.cos();

                let (b0, b1, b2, a0, a1, a2) = match typ {
                    EffectType::Lowpass => (
                        (1.0 - cos_w0) / 2.0,
                        1.0 - cos_w0,
                        (1.0 - cos_w0) / 2.0,
                        1.0 + alpha,
                        -2.0 * cos_w0,
                        1.0 - alpha,
                    ),
                    EffectType::Highpass => (
                        (1.0 + cos_w0) / 2.0,
                        -(1.0 + cos_w0),
                        (1.0 + cos_w0) / 2.0,
                        1.0 + alpha,
                        -2.0 * cos_w0,
                        1.0 - alpha,
                    ),
                    EffectType::Bandpass => (
                        w0.sin() / 2.0,
                        0.0,
                        -w0.sin() / 2.0,
                        1.0 + alpha,
                        -2.0 * cos_w0,
                        1.0 - alpha,
                    ),
                    _ => unreachable!(),
                };

                let x0 = sample;
                let out = (b0 / a0) * x0 + (b1 / a0) * self.bq_x1[c] + (b2 / a0) * self.bq_x2[c]
                    - (a1 / a0) * self.bq_y1[c]
                    - (a2 / a0) * self.bq_y2[c];

                self.bq_x2[c] = self.bq_x1[c];
                self.bq_x1[c] = x0;
                self.bq_y2[c] = self.bq_y1[c];
                self.bq_y1[c] = out;

                out
            }
            EffectType::Reverb | EffectType::Chorus => {
                let p1 = self.params.p1.get(); // room_size / decay
                let p2 = self.params.p2.get(); // mix

                let delayed = self.comb_buf[self.comb_pos];
                self.comb_buf[self.comb_pos] = sample + delayed * p1;
                self.comb_pos = (self.comb_pos + 1) % self.comb_buf.len();

                sample * (1.0 - p2) + delayed * p2
            }
        }
    }
}

/// Shared, thread-safe graph of active DSP effects owned by a sound source.
///
/// The main thread pushes `Arc<EffectParams>` entries into the graph; the audio
/// thread observes them via a non-blocking `try_read` lock on every sample batch
/// and synchronises its `active_effects` list accordingly.
///
/// # Fields
/// - `effects` — `Arc<RwLock<Vec<Arc<EffectParams>>>>`. The list of effects to apply in order.
pub struct SharedEffectGraph {
    pub effects: Arc<RwLock<Vec<Arc<EffectParams>>>>,
}

impl SharedEffectGraph {
    /// Creates an empty `SharedEffectGraph` with no effects in the chain.
    ///
    /// # Returns
    /// `Self`.
    pub fn new() -> Self {
        log_msg!(debug, DP03);
        Self {
            effects: Arc::new(RwLock::new(Vec::new())),
        }
    }
}

impl Default for SharedEffectGraph {
    fn default() -> Self {
        Self::new()
    }
}

impl SharedEffectGraph {}

/// A rodio `Source` wrapper that applies a dynamic chain of DSP effects to an inner audio source.
///
/// On every audio-thread call to `Iterator::next`, `DynamicEffectSource` checks whether the
/// shared effect list has changed (`sync_effects`) and processes the sample through each
/// `ActiveEffect` in sequence before returning it to the mixer.
///
/// # Type Parameters
/// - `I` — The inner [`rodio::Source`] that produces `f32` samples.
///
/// # Fields
/// - `input` — `I`. The wrapped inner audio source.
/// - `shared_graph` — `Arc<RwLock<Vec<Arc<EffectParams>>>>`. Lock-shared effect configuration.
/// - `active_effects` — `Vec<ActiveEffect>`. Per-stream effect state, synchronised from `shared_graph`.
/// - `current_channel` — `u16`. Interleaved channel index used to route samples to the correct filter lane.
/// - `sample_rate` — `u32`. Sample rate of the inner source, cached for filter coefficient computation.
/// - `channels` — `u16`. Channel count of the inner source.
pub struct DynamicEffectSource<I: Source<Item = f32>> {
    input: I,
    shared_graph: Arc<RwLock<Vec<Arc<EffectParams>>>>,
    active_effects: Vec<ActiveEffect>,
    current_channel: u16,
    sample_rate: u32,
    channels: u16,
}

impl<I: Source<Item = f32>> DynamicEffectSource<I> {
    /// Wraps an inner audio source with a dynamic DSP effect chain.
    ///
    /// # Parameters
    /// - `input` — `I`. The inner rodio source that produces `f32` samples.
    /// - `shared_graph` — `Arc<RwLock<Vec<Arc<EffectParams>>>>`. The shared effect list.
    ///
    /// # Returns
    /// `Self`.
    pub fn new(input: I, shared_graph: Arc<RwLock<Vec<Arc<EffectParams>>>>) -> Self {
        let sample_rate = input.sample_rate();
        let channels = input.channels();
        Self {
            input,
            shared_graph,
            active_effects: Vec::new(),
            current_channel: 0,
            sample_rate,
            channels,
        }
    }

    fn sync_effects(&mut self) {
        if let Ok(guard) = self.shared_graph.try_read() {
            let shared_len = guard.len();
            // simple diffing: just replace if sizes differ. In a real engine, we'd check IDs
            if self.active_effects.len() != shared_len {
                self.active_effects.clear();
                for ef in guard.iter() {
                    self.active_effects.push(ActiveEffect::new(
                        Arc::clone(ef),
                        self.sample_rate,
                        self.channels,
                    ));
                }
            } else {
                for (i, ef) in guard.iter().enumerate() {
                    if self.active_effects[i].params.id != ef.id {
                        self.active_effects[i] =
                            ActiveEffect::new(Arc::clone(ef), self.sample_rate, self.channels);
                    }
                }
            }
        }
    }
}

impl<I: Source<Item = f32>> Iterator for DynamicEffectSource<I> {
    type Item = I::Item;

    fn next(&mut self) -> Option<Self::Item> {
        let sample_opt = self.input.next();
        if let Some(sample) = sample_opt {
            if self.current_channel == 0 {
                // only sync on frames, not interleaved channels
                self.sync_effects();
            }

            let mut current_val = sample;
            for ef in &mut self.active_effects {
                current_val = ef.process(current_val, self.current_channel, self.sample_rate);
            }

            self.current_channel = (self.current_channel + 1) % self.channels;

            // convert back to whatever sample type the pipeline uses
            Some(current_val)
        } else {
            None
        }
    }
}

impl<I: Source<Item = f32>> Source for DynamicEffectSource<I> {
    fn current_frame_len(&self) -> Option<usize> {
        self.input.current_frame_len()
    }

    fn channels(&self) -> u16 {
        self.input.channels()
    }

    fn sample_rate(&self) -> u32 {
        self.input.sample_rate()
    }

    fn total_duration(&self) -> Option<std::time::Duration> {
        self.input.total_duration()
    }
}
