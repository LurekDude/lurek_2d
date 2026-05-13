use std::f32::consts::PI;
pub fn linear(t: f32) -> f32 {
    t
}
pub fn ease_in_quad(t: f32) -> f32 {
    t * t
}
pub fn ease_out_quad(t: f32) -> f32 {
    t * (2.0 - t)
}
pub fn ease_in_out_quad(t: f32) -> f32 {
    if t < 0.5 {
        2.0 * t * t
    } else {
        -1.0 + (4.0 - 2.0 * t) * t
    }
}
pub fn ease_in_cubic(t: f32) -> f32 {
    t * t * t
}
pub fn ease_out_cubic(t: f32) -> f32 {
    let u = t - 1.0;
    u * u * u + 1.0
}
pub fn ease_in_out_cubic(t: f32) -> f32 {
    if t < 0.5 {
        4.0 * t * t * t
    } else {
        let u = 2.0 * t - 2.0;
        0.5 * u * u * u + 1.0
    }
}
pub fn ease_in_quart(t: f32) -> f32 {
    t * t * t * t
}
pub fn ease_out_quart(t: f32) -> f32 {
    let u = t - 1.0;
    1.0 - u * u * u * u
}
pub fn ease_in_out_quart(t: f32) -> f32 {
    if t < 0.5 {
        8.0 * t * t * t * t
    } else {
        let u = t - 1.0;
        1.0 - 8.0 * u * u * u * u
    }
}
pub fn ease_in_sine(t: f32) -> f32 {
    1.0 - (t * PI / 2.0).cos()
}
pub fn ease_out_sine(t: f32) -> f32 {
    (t * PI / 2.0).sin()
}
pub fn ease_in_out_sine(t: f32) -> f32 {
    0.5 * (1.0 - (PI * t).cos())
}
pub fn ease_in_expo(t: f32) -> f32 {
    if t <= 0.0 {
        0.0
    } else {
        (2.0_f32).powf(10.0 * (t - 1.0))
    }
}
pub fn ease_out_expo(t: f32) -> f32 {
    if t >= 1.0 {
        1.0
    } else {
        1.0 - (2.0_f32).powf(-10.0 * t)
    }
}
pub fn ease_in_out_expo(t: f32) -> f32 {
    if t <= 0.0 {
        return 0.0;
    }
    if t >= 1.0 {
        return 1.0;
    }
    if t < 0.5 {
        0.5 * (2.0_f32).powf(20.0 * t - 10.0)
    } else {
        1.0 - 0.5 * (2.0_f32).powf(-20.0 * t + 10.0)
    }
}
pub fn ease_in_elastic(t: f32) -> f32 {
    if t <= 0.0 {
        return 0.0;
    }
    if t >= 1.0 {
        return 1.0;
    }
    let p = 0.3_f32;
    -(2.0_f32.powf(10.0 * (t - 1.0)) * ((t - 1.0 - p / 4.0) * 2.0 * PI / p).sin())
}
pub fn ease_out_elastic(t: f32) -> f32 {
    if t <= 0.0 {
        return 0.0;
    }
    if t >= 1.0 {
        return 1.0;
    }
    let p = 0.3_f32;
    2.0_f32.powf(-10.0 * t) * ((t - p / 4.0) * 2.0 * PI / p).sin() + 1.0
}
pub fn ease_in_out_elastic(t: f32) -> f32 {
    if t <= 0.0 {
        return 0.0;
    }
    if t >= 1.0 {
        return 1.0;
    }
    let p = 0.45_f32;
    let s = p / 4.0;
    if t < 0.5 {
        -0.5 * 2.0_f32.powf(20.0 * t - 10.0) * ((2.0 * t - 1.0 - s) * 2.0 * PI / p).sin()
    } else {
        0.5 * 2.0_f32.powf(-20.0 * t + 10.0) * ((2.0 * t - 1.0 - s) * 2.0 * PI / p).sin() + 1.0
    }
}
pub fn ease_out_bounce(t: f32) -> f32 {
    if t < 1.0 / 2.75 {
        7.5625 * t * t
    } else if t < 2.0 / 2.75 {
        let t = t - 1.5 / 2.75;
        7.5625 * t * t + 0.75
    } else if t < 2.5 / 2.75 {
        let t = t - 2.25 / 2.75;
        7.5625 * t * t + 0.9375
    } else {
        let t = t - 2.625 / 2.75;
        7.5625 * t * t + 0.984375
    }
}
pub fn ease_in_bounce(t: f32) -> f32 {
    1.0 - ease_out_bounce(1.0 - t)
}
pub fn ease_in_out_bounce(t: f32) -> f32 {
    if t < 0.5 {
        0.5 * ease_in_bounce(2.0 * t)
    } else {
        0.5 * ease_out_bounce(2.0 * t - 1.0) + 0.5
    }
}
pub fn ease_in_back(t: f32) -> f32 {
    let s = 1.70158_f32;
    t * t * ((s + 1.0) * t - s)
}
pub fn ease_out_back(t: f32) -> f32 {
    let s = 1.70158_f32;
    let u = t - 1.0;
    u * u * ((s + 1.0) * u + s) + 1.0
}
pub fn ease_in_out_back(t: f32) -> f32 {
    let s = 1.70158_f32 * 1.525;
    if t < 0.5 {
        let t2 = 2.0 * t;
        0.5 * t2 * t2 * ((s + 1.0) * t2 - s)
    } else {
        let t2 = 2.0 * t - 2.0;
        0.5 * (t2 * t2 * ((s + 1.0) * t2 + s) + 2.0)
    }
}
pub fn apply(name: &str, t: f32) -> Option<f32> {
    resolve_easing_fn(name).map(|f| f(t))
}
pub fn resolve_easing_fn(name: &str) -> Option<fn(f32) -> f32> {
    match name.to_lowercase().as_str() {
        "linear" => Some(linear),
        "inquad" => Some(ease_in_quad),
        "outquad" => Some(ease_out_quad),
        "inoutquad" => Some(ease_in_out_quad),
        "incubic" => Some(ease_in_cubic),
        "outcubic" => Some(ease_out_cubic),
        "inoutcubic" => Some(ease_in_out_cubic),
        "inquart" => Some(ease_in_quart),
        "outquart" => Some(ease_out_quart),
        "inoutquart" => Some(ease_in_out_quart),
        "insine" => Some(ease_in_sine),
        "outsine" => Some(ease_out_sine),
        "inoutsine" => Some(ease_in_out_sine),
        "inexpo" => Some(ease_in_expo),
        "outexpo" => Some(ease_out_expo),
        "inoutexpo" => Some(ease_in_out_expo),
        "inelastic" => Some(ease_in_elastic),
        "outelastic" => Some(ease_out_elastic),
        "inoutelastic" => Some(ease_in_out_elastic),
        "outbounce" => Some(ease_out_bounce),
        "inbounce" => Some(ease_in_bounce),
        "inoutbounce" => Some(ease_in_out_bounce),
        "inback" => Some(ease_in_back),
        "outback" => Some(ease_out_back),
        "inoutback" => Some(ease_in_out_back),
        _ => None,
    }
}
