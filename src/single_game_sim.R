# This script generates the lineup sim for a single game. 

# Load necessary data from original huang study; file paths may differ
load('team_subMC.RData')
load('team_pL.RData')
load('team_lineups.RData')
load('team_lineup_times.RData')
load('team_lineup_starting.RData')
load('team_lineup_coef.RData') # this data object contains the plus/minus scoring rates for each five-person lineup. 

# Function to simulate a single game for a single team
simulate_single_game <- function(team_name) {
  # Extract team-specific data
  
  #team markov chain
  tMC = team_subMC[[team_name]]
  
  #team lineup matrix
  tLU = team_lineups[[team_name]]
  
  #total time for each lineup
  tLT = team_lineup_times[[team_name]]
  
  tLS = elastic_team_lineup_starting[[team_name]]
  tPL = team_pL[[team_name]][,2]
  
  # Initialize lineup time accumulator
  LU_sim = rep(0, dim(tMC)[1])
  
  # Sampling starting state based on empirical distribution (tLS) 
  state = sample(1:length(tLS), 1, prob = tLS/sum(tLS))
  T = 0
  
  while (T < (48 * 60)) { # 48 minutes in seconds
    trans_prob = tMC[state, -state] / tLT[state]
    
    while (sum(trans_prob) == 0) {
      trans_prob = tMC[-state, state] / tLT[state]
      rate_prob = rexp(length(trans_prob), trans_prob)
      rate_prob[is.na(rate_prob)] = max(rate_prob[!is.na(rate_prob)]) + 1
      stateN = which.min(rate_prob)
      if (stateN >= state) stateN = stateN + 1
      state = stateN
      trans_prob = tMC[state, -state] / tLT[state]
    }
    
    rate_prob = rexp(length(trans_prob), trans_prob)
    rate_prob[is.na(rate_prob)] = max(rate_prob[!is.na(rate_prob)]) + 1
    if (T + min(rate_prob) > 2880) {
      LU_sim[state] = LU_sim[state] + (2880 - T)
      T = 2880
    } else {
      LU_sim[state] = LU_sim[state] + min(rate_prob)
      T = T + min(rate_prob)
    }
    print(min(rate_prob))
    stateN = which.min(rate_prob)
    if (stateN >= state) stateN = stateN + 1
    state = stateN
  }
  
  return(LU_sim)
}

#Function for simulating matchup between two teams. If the function returns a positive integer, team a won; if negative, team b won.
simulate_matchup <- function(team_a, team_b) {
  a_lineup_times <- simulate_single_game(team_a)
  b_lineup_times <- simulate_single_game(team_b)
  
  #These variables should vary based on the desired regression type (e.g., ridge regression is used in the original study). 
  a_scoring_rates = team_lineup_coef[[team_a]]
  b_scoring_rates = team_lineup_coef[[team_b]]
  
  overall_plus_minus = sum(a_lineup_times * a_scoring_rates) - sum(b_lineup_times * b_scoring_rates)
  return(overall_plus_minus)
}

#Example: simulating matchup between Chicago and Golden State
simulate_matchup("Chi", "GS")

x <- simulate_single_game("Chi")

sum(x)