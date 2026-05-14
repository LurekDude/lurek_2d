
use crate::log_msg;
use crate::runtime::log_messages::{DP01, DP02, DP03};
use rodio::Source;
use std::sync::atomic::{AtomicU32, Ordering};
use std::sync::{Arc, RwLock};
#[derive(Debug)]
/// Lock-free f32 parameter shared between the audio thread and the Lua API via atomic bit-cast.
pub struct AtomicParam {
    /// Bit-cast f32 stored as u32 for atomic load/store via `Relaxed` ordering.
    val: AtomicU32,
}
impl AtomicParam {
    /// Create a new `AtomicParam` initialised to `val`.
    pub fn new(val: f32) -> Self {
        Self {
            val: AtomicU32::new(val.to_bits()),
        }
    }
    /// Return the current f32 value using `Relaxed` ordering.
    pub fn get(&self) -> f32 {
        f32::from_bits(self.val.load(Ordering::Relaxed))
    }
    /// Store a new f32 value using `Relaxed` ordering.
    pub fn set(&self, val: f32) {
        self.val.store(val.to_bits(), Ordering::Relaxed);
    }
}
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
/// DSP effect algorithm applied by `ActiveEffect::process` per sample.
pub enum EffectType {
    /// Biquad low-pass filter (cutoff, Q, mix).
    Lowpass,
    /// Biquad high-pass filter (cutoff, Q, mix).
    Highpass,
    /// Biquad band-pass filter (cutoff, Q, mix).
    Bandpass,
    /// Biquad notch filter (cutoff, bandwidth).
    Notch,
    /// Biquad low-shelf EQ (cutoff, gain_db, Q).
    LowShelf,
    /// Biquad high-shelf EQ (cutoff, gain_db, Q).
    HighShelf,
    /// Biquad peaking/bell EQ (cutoff, gain_db, Q).
    BellEq,
    /// Short comb-based reverb (mix); 50 ms delay line.
    Reverb,
    /// Long comb-based reverb (mix); 120 ms delay line.
    Reverb2,
    /// Modulated chorus (rate, depth, mix); 20 ms delay line.
    Chorus,
    /// LFO-modulated flanger (rate, depth, mix); 5 ms delay line.
    Flanger,
    /// LFO-modulated phaser (rate, depth, mix); 10 ms all-pass delay.
    Phaser,
    /// Soft-clip distortion (drive, mix).
    Distortion,
    /// Peak limiter with envelope follower (threshold, release).
    Limiter,
    /// Dynamic-range compressor (threshold, ratio, makeup_gain).
    Compressor,
}
#[derive(Debug)]
/// Shared, lock-free parameter block for one DSP effect; shared between Lua API and audio thread.
pub struct EffectParams {
    /// Unique integer ID assigned when the effect is added to a `Bus` effect chain.
    pub id: u32,
    /// Algorithm variant that determines how `p1`/`p2`/`p3` are interpreted.
    pub typ: EffectType,
    /// Primary parameter (e.g. cutoff Hz, drive, threshold, rate) — meaning is type-specific.
    pub p1: AtomicParam,
    /// Secondary parameter (e.g. gain_db, bandwidth, depth, ratio) — meaning is type-specific.
    pub p2: AtomicParam,
    /// Tertiary parameter (e.g. mix, Q, makeup_gain) — meaning is type-specific.
    pub p3: AtomicParam,
}
impl EffectParams {
    /// Create new `EffectParams` with `id`, `typ`, and all parameters initialised to 0.0.
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
    /// Set a named parameter on this effect; error if `param` is not valid for `typ`.
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
            EffectType::Notch => match param {
                "cutoff" | "frequency" => {
                    self.p1.set(value);
                    Ok(())
                }
                "bandwidth" | "q" => {
                    self.p2.set(value);
                    Ok(())
                }
                _ => Err(format!("invalid parameter: {}", param)),
            },
            EffectType::LowShelf | EffectType::HighShelf => match param {
                "cutoff" | "frequency" => {
                    self.p1.set(value);
                    Ok(())
                }
                "gain_db" => {
                    self.p2.set(value);
                    Ok(())
                }
                _ => Err(format!("invalid parameter: {}", param)),
            },
            EffectType::BellEq => match param {
                "cutoff" | "frequency" => {
                    self.p1.set(value);
                    Ok(())
                }
                "gain_db" => {
                    self.p2.set(value);
                    Ok(())
                }
                "q" => {
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
            EffectType::Reverb2 => match param {
                "room_size" => {
                    self.p1.set(value);
                    Ok(())
                }
                "damping" | "pre_delay" => {
                    self.p2.set(value);
                    Ok(())
                }
                "mix" => {
                    self.p3.set(value);
                    Ok(())
                }
                _ => Err(format!("invalid parameter: {}", param)),
            },
            EffectType::Chorus | EffectType::Flanger | EffectType::Phaser => match param {
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
            EffectType::Distortion => match param {
                "drive" => {
                    self.p1.set(value);
                    Ok(())
                }
                "mix" => {
                    self.p2.set(value);
                    Ok(())
                }
                _ => Err(format!("invalid parameter: {}", param)),
            },
            EffectType::Limiter => match param {
                "threshold" => {
                    self.p1.set(value);
                    Ok(())
                }
                "release" => {
                    self.p2.set(value);
                    Ok(())
                }
                _ => Err(format!("invalid parameter: {}", param)),
            },
            EffectType::Compressor => match param {
                "threshold" => {
                    self.p1.set(value);
                    Ok(())
                }
                "ratio" => {
                    self.p2.set(value);
                    Ok(())
                }
                "makeup_gain" => {
                    self.p3.set(value);
                    Ok(())
                }
                _ => Err(format!("invalid parameter: {}", param)),
            },
        }
    }
}
#[derive(Clone)]
/// Per-source instantiation of a DSP effect with its own filter and delay-line state.
pub struct ActiveEffect {
    /// Shared parameter block read each sample; updated lock-free from the Lua API.
    pub params: Arc<EffectParams>,
    /// Biquad x[n-1] delay element per channel.
    pub bq_x1: [f32; 2],
    /// Biquad x[n-2] delay element per channel.
    pub bq_x2: [f32; 2],
    /// Biquad y[n-1] delay element per channel.
    pub bq_y1: [f32; 2],
    /// Biquad y[n-2] delay element per channel.
    pub bq_y2: [f32; 2],
    /// Circular delay line used by reverb, chorus, flanger, and phaser effects.
    pub comb_buf: Vec<f32>,
    /// Write position in `comb_buf`; advanced circularly each sample.
    pub comb_pos: usize,
    /// Envelope follower state for limiter and compressor gain tracking.
    pub compressor_env: f32,
    /// LFO phase in radians for chorus, flanger, and phaser modulation.
    pub lfo_phase: f32,
}
impl ActiveEffect {
    /// Allocate `ActiveEffect` for `params`, sizing `comb_buf` based on effect type and `sample_rate`.
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
            EffectType::Reverb2 => {
                ((sample_rate as f32 * 0.12) as usize * channels as usize).max(1)
            }
            EffectType::Flanger => {
                ((sample_rate as f32 * 0.005) as usize * channels as usize).max(1)
            }
            EffectType::Phaser => ((sample_rate as f32 * 0.01) as usize * channels as usize).max(1),
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
            compressor_env: 0.0,
            lfo_phase: 0.0,
        }
    }
    /// Apply the effect to one `sample` on `channel`, returning the processed output sample.
    pub fn process(&mut self, sample: f32, channel: u16, sample_rate: u32) -> f32 {
        let c = (channel as usize) % 2;
        let typ = self.params.typ;
        let sr = sample_rate as f32;
        match typ {
            EffectType::Lowpass | EffectType::Highpass | EffectType::Bandpass => {
                let f0 = self.params.p1.get().clamp(20.0, 20000.0);
                let q = 0.707_f32;
                let w0 = 2.0 * std::f32::consts::PI * f0 / sr;
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
            EffectType::Notch => {
                let f0 = self.params.p1.get().clamp(20.0, 20000.0);
                let bw = self.params.p2.get().clamp(10.0, 5000.0).max(10.0);
                let q = f0 / bw;
                let w0 = 2.0 * std::f32::consts::PI * f0 / sr;
                let alpha = w0.sin() / (2.0 * q);
                let cos_w0 = w0.cos();
                let a0 = 1.0 + alpha;
                let x0 = sample;
                let out = (1.0 / a0) * x0
                    + (-2.0 * cos_w0 / a0) * self.bq_x1[c]
                    + (1.0 / a0) * self.bq_x2[c]
                    - (-2.0 * cos_w0 / a0) * self.bq_y1[c]
                    - ((1.0 - alpha) / a0) * self.bq_y2[c];
                self.bq_x2[c] = self.bq_x1[c];
                self.bq_x1[c] = x0;
                self.bq_y2[c] = self.bq_y1[c];
                self.bq_y1[c] = out;
                out
            }
            EffectType::LowShelf | EffectType::HighShelf => {
                let f0 = self.params.p1.get().clamp(20.0, 20000.0);
                let gain_db = self.params.p2.get().clamp(-24.0, 24.0);
                let a_gain = 10.0_f32.powf(gain_db / 40.0);
                let w0 = 2.0 * std::f32::consts::PI * f0 / sr;
                let cos_w0 = w0.cos();
                let sin_w0 = w0.sin();
                let alpha = sin_w0 / 2.0 * (a_gain + 1.0 / a_gain).sqrt();
                let (b0, b1, b2, a0, a1, a2) = if typ == EffectType::LowShelf {
                    (
                        a_gain
                            * ((a_gain + 1.0) - (a_gain - 1.0) * cos_w0
                                + 2.0 * a_gain.sqrt() * alpha),
                        2.0 * a_gain * ((a_gain - 1.0) - (a_gain + 1.0) * cos_w0),
                        a_gain
                            * ((a_gain + 1.0)
                                - (a_gain - 1.0) * cos_w0
                                - 2.0 * a_gain.sqrt() * alpha),
                        (a_gain + 1.0) + (a_gain - 1.0) * cos_w0 + 2.0 * a_gain.sqrt() * alpha,
                        -2.0 * ((a_gain - 1.0) + (a_gain + 1.0) * cos_w0),
                        (a_gain + 1.0) + (a_gain - 1.0) * cos_w0 - 2.0 * a_gain.sqrt() * alpha,
                    )
                } else {
                    (
                        a_gain
                            * ((a_gain + 1.0)
                                + (a_gain - 1.0) * cos_w0
                                + 2.0 * a_gain.sqrt() * alpha),
                        -2.0 * a_gain * ((a_gain - 1.0) + (a_gain + 1.0) * cos_w0),
                        a_gain
                            * ((a_gain + 1.0) + (a_gain - 1.0) * cos_w0
                                - 2.0 * a_gain.sqrt() * alpha),
                        (a_gain + 1.0) - (a_gain - 1.0) * cos_w0 + 2.0 * a_gain.sqrt() * alpha,
                        2.0 * ((a_gain - 1.0) - (a_gain + 1.0) * cos_w0),
                        (a_gain + 1.0) - (a_gain - 1.0) * cos_w0 - 2.0 * a_gain.sqrt() * alpha,
                    )
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
            EffectType::BellEq => {
                let f0 = self.params.p1.get().clamp(20.0, 20000.0);
                let gain_db = self.params.p2.get().clamp(-24.0, 24.0);
                let q = self.params.p3.get().max(0.1).max(0.1);
                let q = if q <= 0.0 { 1.0 } else { q };
                let a_gain = 10.0_f32.powf(gain_db / 40.0);
                let w0 = 2.0 * std::f32::consts::PI * f0 / sr;
                let alpha = w0.sin() / (2.0 * q);
                let cos_w0 = w0.cos();
                let a0 = 1.0 + alpha / a_gain;
                let x0 = sample;
                let out = ((1.0 + alpha * a_gain) / a0) * x0
                    + ((-2.0 * cos_w0) / a0) * self.bq_x1[c]
                    + ((1.0 - alpha * a_gain) / a0) * self.bq_x2[c]
                    - ((-2.0 * cos_w0) / a0) * self.bq_y1[c]
                    - ((1.0 - alpha / a_gain) / a0) * self.bq_y2[c];
                self.bq_x2[c] = self.bq_x1[c];
                self.bq_x1[c] = x0;
                self.bq_y2[c] = self.bq_y1[c];
                self.bq_y1[c] = out;
                out
            }
            EffectType::Reverb | EffectType::Chorus => {
                let p1 = self.params.p1.get();
                let p2 = self.params.p2.get();
                let delayed = self.comb_buf[self.comb_pos];
                self.comb_buf[self.comb_pos] = sample + delayed * p1;
                self.comb_pos = (self.comb_pos + 1) % self.comb_buf.len();
                sample * (1.0 - p2) + delayed * p2
            }
            EffectType::Reverb2 => {
                let room_size = self.params.p1.get().clamp(0.0, 1.0);
                let damping = self.params.p2.get().clamp(0.0, 1.0);
                let mix = self.params.p3.get().clamp(0.0, 1.0);
                let buf_len = self.comb_buf.len().max(1);
                let tap_offsets = [buf_len / 4, buf_len / 3, buf_len / 2, (buf_len * 2) / 3];
                let mut wet = 0.0_f32;
                for offset in tap_offsets {
                    let tap_pos = (self.comb_pos + buf_len - offset) % buf_len;
                    wet += self.comb_buf[tap_pos];
                }
                wet *= 0.25;
                let store = sample + wet * room_size * (1.0 - damping);
                self.comb_buf[self.comb_pos] = store;
                self.comb_pos = (self.comb_pos + 1) % buf_len;
                sample * (1.0 - mix) + wet * mix
            }
            EffectType::Flanger => {
                let rate = self.params.p1.get().clamp(0.01, 10.0);
                let depth = self.params.p2.get().clamp(0.0, 1.0);
                let mix = self.params.p3.get().clamp(0.0, 1.0);
                let buf_len = self.comb_buf.len().max(2);
                if c == 0 {
                    self.lfo_phase = (self.lfo_phase + 2.0 * std::f32::consts::PI * rate / sr)
                        % (2.0 * std::f32::consts::PI);
                }
                let lfo_val = (self.lfo_phase.sin() + 1.0) * 0.5;
                let delay_samps = ((buf_len - 1) as f32 * depth * lfo_val) as usize;
                let tap_pos =
                    (self.comb_pos + buf_len - delay_samps.clamp(0, buf_len - 1)) % buf_len;
                let delayed = self.comb_buf[tap_pos];
                self.comb_buf[self.comb_pos] = sample;
                self.comb_pos = (self.comb_pos + 1) % buf_len;
                sample * (1.0 - mix) + delayed * mix
            }
            EffectType::Phaser => {
                let rate = self.params.p1.get().clamp(0.01, 10.0);
                let depth = self.params.p2.get().clamp(0.0, 1.0);
                let mix = self.params.p3.get().clamp(0.0, 1.0);
                let buf_len = self.comb_buf.len().max(2);
                if c == 0 {
                    self.lfo_phase = (self.lfo_phase + 2.0 * std::f32::consts::PI * rate / sr)
                        % (2.0 * std::f32::consts::PI);
                }
                let lfo_val = (self.lfo_phase.sin() + 1.0) * 0.5;
                let delay_samps = ((buf_len - 1) as f32 * depth * lfo_val) as usize;
                let tap_pos =
                    (self.comb_pos + buf_len - delay_samps.clamp(0, buf_len - 1)) % buf_len;
                let delayed = self.comb_buf[tap_pos];
                self.comb_buf[self.comb_pos] = sample;
                self.comb_pos = (self.comb_pos + 1) % buf_len;
                sample * (1.0 - mix) + (sample - delayed) * mix
            }
            EffectType::Distortion => {
                let drive = self.params.p1.get().max(1.0);
                let mix = self.params.p2.get().clamp(0.0, 1.0);
                let threshold = 1.0 / drive;
                let driven = sample * drive;
                let clipped = driven.clamp(-1.0, 1.0) * threshold;
                sample * (1.0 - mix) + clipped * mix
            }
            EffectType::Limiter => {
                let threshold = self.params.p1.get().clamp(0.001, 1.0);
                let release = self.params.p2.get().clamp(0.001, 1.0);
                let abs_s = sample.abs();
                if abs_s > threshold {
                    let gain = threshold / abs_s;
                    self.compressor_env = self.compressor_env * (1.0 - release) + gain * release;
                } else {
                    self.compressor_env = (self.compressor_env + release).min(1.0);
                }
                sample * self.compressor_env
            }
            EffectType::Compressor => {
                let threshold = self.params.p1.get().clamp(0.0, 1.0);
                let ratio = self.params.p2.get().max(1.0);
                let makeup = self.params.p3.get().max(0.0);
                let attack = 1.0 - (-1.0_f32 / (0.01 * sr)).exp();
                let release_coeff = 1.0 - (-1.0_f32 / (0.1 * sr)).exp();
                let level = sample.abs();
                if level > self.compressor_env {
                    self.compressor_env += attack * (level - self.compressor_env);
                } else {
                    self.compressor_env += release_coeff * (level - self.compressor_env);
                }
                let gain = if self.compressor_env > threshold && threshold > 0.0 {
                    let db_over = 20.0 * (self.compressor_env / threshold).log10();
                    let db_reduced = db_over / ratio;
                    let gain_linear = 10.0_f32.powf(-db_reduced / 20.0);
                    gain_linear * (1.0 + makeup)
                } else {
                    1.0 + makeup
                };
                sample * gain
            }
        }
    }
}
/// Arc-wrapped effect parameter list shared between `Bus` (writer) and `DynamicEffectSource` (reader).
pub struct SharedEffectGraph {
    /// List of effect parameter blocks; `DynamicEffectSource` re-syncs its `ActiveEffect` vec from this.
    pub effects: Arc<RwLock<Vec<Arc<EffectParams>>>>,
}
impl SharedEffectGraph {
    /// Create an empty `SharedEffectGraph`.
    pub fn new() -> Self {
        log_msg!(debug, DP03);
        Self {
            effects: Arc::new(RwLock::new(Vec::new())),
        }
    }
}
/// `Default` impl: returns `SharedEffectGraph::new()`.
impl Default for SharedEffectGraph {
    /// Create default shared effect graph.
    fn default() -> Self {
        Self::new()
    }
}
impl SharedEffectGraph {}
/// Rodio `Source` wrapper that applies the `SharedEffectGraph` effect chain sample by sample.
pub struct DynamicEffectSource<I: Source<Item = f32>> {
    /// Upstream rodio source supplying raw f32 samples.
    input: I,
    /// Shared parameter list polled each frame to sync the local `active_effects` vec.
    shared_graph: Arc<RwLock<Vec<Arc<EffectParams>>>>,
    /// Per-source `ActiveEffect` instances kept in sync with `shared_graph` each frame.
    active_effects: Vec<ActiveEffect>,
    /// Current interleaved channel index, reset to 0 after `channels - 1`.
    current_channel: u16,
    /// Sample rate in Hz captured from `input` at construction.
    sample_rate: u32,
    /// Channel count captured from `input` at construction.
    channels: u16,
}
impl<I: Source<Item = f32>> DynamicEffectSource<I> {
    /// Wrap `input` with the given `shared_graph`; captures sample rate and channel count.
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
    /// Re-sync `active_effects` from `shared_graph` if the effect count changed (called per frame).
    fn sync_effects(&mut self) {
        if let Ok(guard) = self.shared_graph.try_read() {
            let shared_len = guard.len();
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
    /// Advance the upstream source, apply the full effect chain per sample, and return the result.
    fn next(&mut self) -> Option<Self::Item> {
        let sample_opt = self.input.next();
        if let Some(sample) = sample_opt {
            if self.current_channel == 0 {
                self.sync_effects();
            }
            let mut current_val = sample;
            for ef in &mut self.active_effects {
                current_val = ef.process(current_val, self.current_channel, self.sample_rate);
            }
            self.current_channel = (self.current_channel + 1) % self.channels;
            Some(current_val)
        } else {
            None
        }
    }
}
impl<I: Source<Item = f32>> Source for DynamicEffectSource<I> {
    /// Delegate `current_frame_len` to the upstream source.
    fn current_frame_len(&self) -> Option<usize> {
        self.input.current_frame_len()
    }
    /// Delegate `channels` to the upstream source.
    fn channels(&self) -> u16 {
        self.input.channels()
    }
    /// Delegate `sample_rate` to the upstream source.
    fn sample_rate(&self) -> u32 {
        self.input.sample_rate()
    }
    /// Delegate `total_duration` to the upstream source.
    fn total_duration(&self) -> Option<std::time::Duration> {
        self.input.total_duration()
    }
}
