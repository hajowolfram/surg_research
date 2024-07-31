# Series simulations with varying restoring force strengths
# Uses exact_rf_simulate_series function from rf_exact_simulation.R

k_vals = list(0.000001, 0.00001, 0.0001, 0.001, 0.01)

for (k in k_vals) {
  correct_predictions = 0
  for (i in 1:1000) {
    if (exact_rf_simulate_series("GS", "Cle", c) == "GS") {
      correct_predictions = correct_predictions + 1
    }
  }
  print(sprintf("c = %f: %d", k, correct_predictions))
}