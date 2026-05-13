//! Tests for the \$module_name\ AI module.
//! These tests verify type conversions, state transitions, and module invariants.

#[cfg(test)]
mod tests {
    use super::*;

    fn make_net(shape: &[(usize, usize)]) -> NeuralNet {
        let mut nn = NeuralNet::new();
        for &(inputs, outputs) in shape {
            nn.add_layer(inputs, outputs, Activation::Sigmoid);
        }
        nn
    }

    #[test]
    fn single_layer_forward() {
        let nn = make_net(&[(2, 1)]);
        let out = nn.forward(&[1.0, 1.0]);
        assert_eq!(out.len(), 1);
    }

    #[test]
    fn two_layer_forward() {
        let nn = make_net(&[(3, 4), (4, 2)]);
        let out = nn.forward(&[1.0, 0.5, -0.3]);
        assert_eq!(out.len(), 2);
    }

    #[test]
    fn set_weights_round_trip() {
        let mut nn = make_net(&[(2, 2)]);
        let flat = nn.get_weights();
        nn.set_weights(&flat);
        let flat2 = nn.get_weights();
        assert_eq!(flat, flat2);
    }

    #[test]
    fn layer_count_matches() {
        let nn = make_net(&[(3, 5), (5, 2)]);
        assert_eq!(nn.layer_count(), 2);
    }

    #[test]
    fn output_bounded_by_activation() {
        let nn = make_net(&[(2, 3)]);
        let out = nn.forward(&[100.0, -100.0]);
        for v in &out {
            assert!(*v >= 0.0 && *v <= 1.0, "sigmoid should bound output");
        }
    }
}