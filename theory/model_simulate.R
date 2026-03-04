# ***********************************************************
# Title: Female Export Consortia — Theoretical Model
#
# Purpose: Simulate the dynamic model combining Melitz (2003) 
#          and Bandiera et al. (2022) to illustrate how 
#          consortia lower the export threshold and generate
#          a transition from a low to a high steady state.
#       Part 1: Settings & model parameters
#       Part 2: Model functions
#       Part 3: Figure 1 — Transition functions and steady states
#       Part 4: Figure 2 — Firm trajectories under scenarios
#       Part 5: Figure 3 — Firm size distributions (unimodal → bimodal)
#       Part 6: Calibration to data (placeholder)
#
# Authors: Münch, Bouziri, Scheifele
# Requires: (none for simulation; consortium_final.dta for calibration)
# Creates: transition_functions.pdf, firm_trajectories.pdf, 
#          firm_distributions.pdf
#
# Notes: Uses base R graphics. For the final paper version,
#        replace with ggplot2 code in the companion _ggplot.R
#        script (requires: ggplot2, data.table, scales, patchwork).
# ***********************************************************


# ***********************************************************
# Part 1: Settings & model parameters ----
# ***********************************************************

set.seed(42)

### Output directory ----
o_fig <- file.path(getwd(), "figures")
dir.create(o_fig, showWarnings = FALSE, recursive = TRUE)

### Model parameters ----
# Explanatory notes:
  # The model features two transition functions for firm capability k_t:
  #   g_D(k) = A_D * k^alpha   (domestic-only firms)
  #   g_X(k) = A_X * k^alpha   (exporting firms)
  # A firm exports if k_t >= k_bar (individual threshold) or
  #   k_t >= k_bar_c (consortium threshold, lower due to cost-sharing).
  # At steady state g(k*) = k*, so A = (k*)^(1 - alpha).

alpha   <- 0.85        # concavity of capability accumulation
k_L     <- 4.0         # low steady state (domestic)
k_H     <- 27.4        # high steady state (exporting)
k_bar   <- 9.0         # export threshold (individual)
k_bar_c <- 2.11        # export threshold (consortium, = k_bar / cost_share_factor)

# Derived productivity parameters
A_D <- k_L^(1 - alpha)  # domestic TFP: ensures g_D(k_L) = k_L
A_X <- k_H^(1 - alpha)  # export TFP:   ensures g_X(k_H) = k_H

cat("Model parameters:\n")
cat("  alpha =", alpha, "\n")
cat("  A_D   =", round(A_D, 4), " (domestic)\n")
cat("  A_X   =", round(A_X, 4), " (export)\n")
cat("  k_L*  =", k_L, "  k_H* =", k_H, "\n")
cat("  k_bar =", k_bar, " k_bar_c =", k_bar_c, "\n")

# Simulation parameters
N_firms  <- 176        # number of firms (matches RCT sample)
T_max    <- 30         # number of periods to simulate
sigma_k  <- 0.8        # s.d. of initial capability distribution
k0_mean  <- 4.2        # mean initial capability (near k_L*)


# ***********************************************************
# Part 2: Model functions ----
# ***********************************************************

### Transition functions ----
g_D <- function(k) A_D * k^alpha   # domestic
g_X <- function(k) A_X * k^alpha   # export

### Single-period transition (one firm) ----
step_firm <- function(k, threshold) {
  # Firm exports if capability >= threshold; otherwise domestic only
  if (k >= threshold) {
    k_next <- g_X(k)
  } else {
    k_next <- g_D(k)
  }
  return(max(k_next, 0.01))  # floor to avoid numerical issues
}

### Multi-period trajectory (one firm) ----
simulate_trajectory <- function(k0, T, threshold_vec) {
  # threshold_vec: vector of length T with the applicable threshold each period
  # Explanatory notes:
    # This allows the threshold to change over time, e.g., 
    # consortium active for first T_c periods then reverts to k_bar.
  path <- numeric(T + 1)
  path[1] <- k0
  for (t in 1:T) {
    path[t + 1] <- step_firm(path[t], threshold_vec[t])
  }
  return(path)
}

### Multi-firm distribution simulation ----
simulate_distribution <- function(k0_vec, T, threshold_vec) {
  N <- length(k0_vec)
  k_final <- numeric(N)
  for (i in 1:N) {
    traj <- simulate_trajectory(k0_vec[i], T, threshold_vec)
    k_final[i] <- traj[T + 1]
  }
  return(k_final)
}


# ***********************************************************
# Part 3: Figure 1 — Transition functions and steady states ----
# ***********************************************************

k_grid <- seq(0.01, 35, by = 0.1)

pdf(file.path(o_fig, "transition_functions.pdf"), width = 10, height = 8)
par(mar = c(5, 5, 3, 2))

# 45-degree line
plot(k_grid, k_grid, type = "l", lty = 2, col = "black", lwd = 1.2,
     xlim = c(0, 35), ylim = c(0, 35),
     xlab = expression("Capability " * k[t]),
     ylab = expression("Capability " * k[t+1]),
     main = "Transition Functions and Steady States",
     cex.main = 1.5, cex.lab = 1.2)

# Domestic transition
lines(k_grid, g_D(k_grid), col = "blue", lwd = 2)

# Export transition
lines(k_grid, g_X(k_grid), col = "red", lwd = 2)

# Steady state points
points(k_L, k_L, pch = 16, col = "blue", cex = 2)
points(k_H, k_H, pch = 16, col = "red", cex = 2)

# Steady state labels
text(k_L + 1.5, k_L - 1.5, bquote(k[L]^"*" == .(k_L)), cex = 1.1)
text(k_H + 1, k_H - 2.5, bquote(k[H]^"*" == .(k_H)), cex = 1.1)

# Threshold lines
abline(v = k_bar, lty = 3, col = "grey40", lwd = 1.2)
text(k_bar + 0.5, 1.5, bquote(bar(k) == .(k_bar)), 
     adj = 0, cex = 0.95, col = "grey40")

abline(v = k_bar_c, lty = 3, col = "forestgreen", lwd = 1.2)
text(k_bar_c + 0.3, 3, bquote(bar(k)[c] == .(k_bar_c)), 
     adj = 0, cex = 0.95, col = "forestgreen")

# Legend
legend("bottomright", 
       legend = c(expression("45° line"), 
                  expression(g[D](k) ~ "(domestic)"), 
                  expression(g[X](k) ~ "(export)")),
       col = c("black", "blue", "red"), 
       lty = c(2, 1, 1), lwd = c(1.2, 2, 2),
       bg = "white", cex = 1.1)

dev.off()
cat("Saved: transition_functions.pdf\n")


# ***********************************************************
# Part 4: Figure 2 — Firm trajectories under scenarios ----
# ***********************************************************

### Define threshold vectors for each scenario ----
k0_traj <- k0_mean  # starting just above k_L*

# Scenario 1: No consortium (threshold = k_bar forever)
thresh_none <- rep(k_bar, T_max)

# Scenario 2: Permanent consortium (threshold = k_bar_c forever)
thresh_perm <- rep(k_bar_c, T_max)

# Scenario 3: Temporary consortium — 5 periods
T_temp_short <- 5
thresh_temp5 <- c(rep(k_bar_c, T_temp_short), rep(k_bar, T_max - T_temp_short))

# Scenario 4: Temporary consortium — 12 periods
T_temp_long <- 12
thresh_temp12 <- c(rep(k_bar_c, T_temp_long), rep(k_bar, T_max - T_temp_long))

### Simulate trajectories ----
traj_none   <- simulate_trajectory(k0_traj, T_max, thresh_none)
traj_perm   <- simulate_trajectory(k0_traj, T_max, thresh_perm)
traj_temp5  <- simulate_trajectory(k0_traj, T_max, thresh_temp5)
traj_temp12 <- simulate_trajectory(k0_traj, T_max, thresh_temp12)

pdf(file.path(o_fig, "firm_trajectories.pdf"), width = 12, height = 7)
par(mar = c(5, 5, 3, 2))

plot(0:T_max, traj_none, type = "o", pch = 16, col = "blue", lwd = 2,
     xlim = c(0, T_max), ylim = c(0, 30),
     xlab = "Period t",
     ylab = expression("Firm capability " * k[t]),
     main = "Firm Trajectories Under Different Scenarios",
     cex.main = 1.5, cex.lab = 1.2)

lines(0:T_max, traj_perm, type = "o", pch = 15, col = "red", lwd = 2)
lines(0:T_max, traj_temp5, type = "o", pch = 17, col = "darkgreen", lwd = 2)
lines(0:T_max, traj_temp12, type = "o", pch = 18, col = "magenta", lwd = 2)

# Reference lines
abline(h = k_bar, lty = 3, col = "grey50")
text(T_max - 4, k_bar + 0.6, bquote(bar(k) == .(k_bar)), 
     cex = 0.95, col = "grey50")

abline(h = k_H, lty = 2, col = adjustcolor("red", 0.4))

# Legend
legend("topleft",
       legend = c("No consortium", "Permanent consortium",
                  "Temporary (5 periods)", "Temporary (12 periods)"),
       col = c("blue", "red", "darkgreen", "magenta"),
       pch = c(16, 15, 17, 18), lwd = 2, bg = "white", cex = 1)

dev.off()
cat("Saved: firm_trajectories.pdf\n")


# ***********************************************************
# Part 5: Figure 3 — Firm distributions (unimodal → bimodal) ----
# ***********************************************************

### Draw initial firm distribution ----
# Explanatory notes:
  # Initial distribution is unimodal, centered near k_L* with some spread.
  # Truncated at 0.5 to avoid negative capabilities.
k0_vec <- pmax(rnorm(N_firms, mean = k0_mean, sd = sigma_k), 0.5)

### Simulate without consortium (all firms face k_bar) ----
T_dist <- 20
thresh_no_cons  <- rep(k_bar, T_dist)
k_final_no_cons <- simulate_distribution(k0_vec, T_dist, thresh_no_cons)

### Simulate with consortium (all firms face k_bar_c) ----
thresh_cons  <- rep(k_bar_c, T_dist)
k_final_cons <- simulate_distribution(k0_vec, T_dist, thresh_cons)

pdf(file.path(o_fig, "firm_distributions.pdf"), width = 12, height = 5)
par(mfrow = c(1, 2), mar = c(5, 4.5, 3, 1))

# Panel A: Without consortium
hist(k_final_no_cons, breaks = seq(0, 35, by = 1.5),
     col = "steelblue", border = "white",
     main = "Without consortium (t=20)",
     xlab = "Firm capability", ylab = "Number of firms",
     xlim = c(0, 30), cex.main = 1.3, cex.lab = 1.1)

# Panel B: With consortium
hist(k_final_cons, breaks = seq(0, 35, by = 1.5),
     col = "steelblue", border = "white",
     main = "With consortium (t=20)",
     xlab = "Firm capability", ylab = "Number of firms",
     xlim = c(0, 30), cex.main = 1.3, cex.lab = 1.1)

# Shared super-title
mtext("Firm Size Distribution: Unimodal to Bimodal", 
      outer = TRUE, line = -1.5, cex = 1.4, font = 2)

dev.off()
cat("Saved: firm_distributions.pdf\n")


# ***********************************************************
# Part 6: Calibration to data (placeholder) ----
# ***********************************************************

# Explanatory notes:
  # This section imports consortium_final.dta and calibrates model
  # parameters to match empirical moments. Currently a placeholder —
  # uncomment and adapt once data file is available.
  #
  # Key calibration targets:
  #   1. Treatment effect on export probability: ~16.5pp
  #   2. Control group export rate: ~0.26
  #   3. Distribution of baseline sales (proxy for initial k)
  #   4. Program cost relative to firm profits: F / pi(k_L*) > 1
  #
  # Known issue: simulated treatment effect overshoots empirical
  # estimate. Recalibration of the initial firm distribution
  # (k0_mean, sigma_k) and/or threshold parameters needed.
  #
  # To use this section:
  #   1. Install haven: install.packages("haven")
  #   2. Place consortium_final.dta in the working directory
  #   3. Change if(0) to if(1) below

if (0) {
  
  library(haven)
  
  ### Import analysis data ----
  df_firms <- read_dta("consortium_final.dta")
  
  ### Extract empirical moments for calibration ----
  
  # Step 1: Baseline sales distribution as proxy for initial capability
  bl <- df_firms[df_firms$surveyround == 1, c("id_plateforme", "ca_w99", "treatment")]
  
  # Step 2: Endline export probability by treatment status
  el <- df_firms[df_firms$surveyround == 3, c("id_plateforme", "exported", "treatment")]
  export_rates <- tapply(el$exported, el$treatment, mean, na.rm = TRUE)
  cat("Empirical export rates:\n")
  print(export_rates)
  
  # Step 3: Compute treatment effect on export (raw difference)
  te_export <- export_rates["1"] - export_rates["0"]
  cat("Raw treatment effect on export:", round(te_export, 3), "\n")
  
  ### Calibrate initial distribution to match baseline sales ----
  # Map baseline sales to capability units:
  #   k = sales / scaling_factor  (choose so median ~ k_L*)
  # scaling_factor <- median(bl$ca_w99, na.rm = TRUE) / k_L
  
  ### Compare simulated vs empirical treatment effect ----
  # sim_export_rate_treat   <- mean(k_final_cons >= k_bar_c)
  # sim_export_rate_control <- mean(k_final_no_cons >= k_bar)
  # sim_te <- sim_export_rate_treat - sim_export_rate_control
  # cat("Simulated TE:", round(sim_te, 3), "vs Empirical:", round(te_export, 3), "\n")
}

cat("\n=== Model simulation complete ===\n")
