use rodio::Source;
use std::sync::atomic::{AtomicU32, Ordering};
use std::sync::{Arc, RwLock};

#[derive(Debug)]

/// Thread-safe atomic parameter.
///
/// # Fields
/// - al — AtomicU32.
/// Thread-safe atomic parameter.
///
/// # Fields
/// - al — AtomicU32.
pub struct AtomicParam {
    val: AtomicU32,
}

impl AtomicParam {
    /// Creates a new param.
    ///
    /// # Parameters
    /// - al — 32.
    ///
    /// # Returns
    /// Self.
    /// Creates a new param.
    ///
    /// # Parameters
    /// - al — 32.
    ///
    /// # Returns
    /// Self.
    pub fn new(val: f32) -> Self {
        Self {
            val: AtomicU32::new(val.to_bits()),
        }
    }

    /// Gets the value.
    ///
    /// # Returns
    /// 32.
    /// Gets the value.
    ///
    /// # Returns
    /// 32.
    pub fn get(&self) -> f32 {
        f32::from_bits(self.val.load(Ordering::Relaxed))
    }

    /// Sets the value.
    ///
    /// # Parameters
    /// - al — 32.
    /// Sets the value.
    ///
    /// # Parameters
    /// - al — 32.
    pub fn set(&self, val: f32) {
        self.val.store(val.to_bits(), Ordering::Relaxed);
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum EffectType {
    Lowpass,
    Highpass,
    Bandpass,
    Reverb,
    Chorus,
}

#[derive(Debug)]
pub struct EffectParams {
    pub id: u32,
    pub typ: EffectType,
    pub p1: AtomicParam, // cutoff / room_size
    pub p2: AtomicParam, // center / mix
    pub p3: AtomicParam, // unused for now
}

impl EffectParams {
    pub fn new(id: u32, typ: EffectType) -> Self {
        Self {
            id,
            typ,
            p1: AtomicParam::new(0.0),
            p2: AtomicParam::new(0.0),
            p3: AtomicParam::new(0.0),
        }
    }
}

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

    /// Process sample.
    ///
    /// # Parameters
    /// - sample — 32.
    /// - channel — u16.
    /// - sample_rate — u32.
    ///
    /// # Returns
    /// 32.
    /// Process sample.
    ///
    /// # Parameters
    /// - sample — 32.
    /// - channel — u16.
    /// - sample_rate — u32.
    ///
    /// # Returns
    /// 32.
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

pub struct SharedEffectGraph {
    pub effects: Arc<RwLock<Vec<Arc<EffectParams>>>>,
}

impl SharedEffectGraph {
    pub fn new() -> Self {
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

pub struct DynamicEffectSource<I: Source<Item = f32>> {
    input: I,
    shared_graph: Arc<RwLock<Vec<Arc<EffectParams>>>>,
    active_effects: Vec<ActiveEffect>,
    current_channel: u16,
    sample_rate: u32,
    channels: u16,
}

impl<I: Source<Item = f32>> DynamicEffectSource<I> {
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
