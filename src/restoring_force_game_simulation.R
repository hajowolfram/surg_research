# Script contains function for simulating games with restoring force

# Load necessary data from original huang study; file paths may differ
load('ctmc/nofouls/team_subMC.RData')
load('ctmc/nofouls/team_pL.RData')
load('ctmc/nofouls/team_lineups.RData')
load('ctmc/nofouls/team_lineup_times.RData')
load('ctmc/nofouls/team_lineup_starting.RData')
load('ctmc/nofouls/team_lineup_coef.RData') # this data object contains the plus/minus scoring rates for each five-person lineup. 

#Simulate matchup
simulate_matchup <- function(team_a, team_b) {
  #Running tally of plus/minus
  a_plus_minus = 0
  b_plus_minus = 0
  
  #Extracting team specific information
  a_tMC = team_subMC[[team_a]]
  a_tLU = team_lineups[[team_a]]
  a_tLT = team_lineup_times[[team_a]]
  a_tLS = team_lineup_starting[[team_a]]
  a_tPL = team_pL[[team_a]][,2]
  a_LU_sim = rep(0, dim(a_tMC)[1])
  
  b_tMC = team_subMC[[team_b]]
  b_tLU = team_lineups[[team_b]]
  b_tLT = team_lineup_times[[team_b]]
  b_tLS = team_lineup_starting[[team_b]]
  b_tPL = team_pL[[team_b]][,2]
  b_LU_sim = rep(0, dim(b_tMC)[1])
  
  # Sampling starting states based on empirical distributions (tLS s) 
  a_state = sample(1:length(a_tLS), 1, prob = a_tLS/sum(a_tLS))
  b_state = sample(1:length(b_tLS), 1, prob = b_tLS/sum(b_tLS))
  
  #Variables to keep track of states after they have been changed
  a_prev_state = a_state
  b_prev_state = b_state
  
  #Separate time indices much be kept to maintain substitution independence between teams
  a_T = 0
  b_T = 0
  game_duration = 60 * 48
  interval_start = 0 # beginning of the current time interval 
  while (a_T < game_duration || b_T < game_duration) {
    if (a_T <= b_T) {
      #Advancing a_T
      interval_start = a_T
      a_trans_prob = a_tMC[a_state, -a_state] / a_tLT[a_state]
      
      while (sum(a_trans_prob) == 0) {
        a_trans_prob = a_tMC[-a_state, a_state] / a_tLT[a_state]
        a_rate_prob = rexp(length(a_trans_prob), a_trans_prob)
        a_rate_prob[is.na(a_rate_prob)] = max(a_rate_prob[!is.na(a_rate_prob)]) + 1
        a_stateN = which.min(a_rate_prob)
        if (a_stateN >= a_state) {
          a_stateN = a_stateN + 1
        }
        a_prev_state = a_state
        a_state = a_stateN
        a_trans_prob = a_tMC[a_state, -a_state] / a_tLT[a_state]
      }
      
      a_rate_prob = rexp(length(a_trans_prob), a_trans_prob)
      a_rate_prob[is.na(a_rate_prob)] = max(a_rate_prob[!is.na(a_rate_prob)]) + 1
      if (a_T + min(a_rate_prob) > game_duration) {
        a_LU_sim[a_state] = a_LU_sim[a_state] + (game_duration - a_T)
        a_T = game_duration
      } else {
        a_T = a_T + min(a_rate_prob)
        a_LU_sim[a_state] = a_LU_sim[a_state] + min(a_rate_prob)
      }
      a_stateN = which.min(a_rate_prob)
      if (a_stateN >= a_state) {
        a_stateN = a_stateN + 1
      }
      a_prev_state = a_state
      a_state = a_stateN
    } else {
      #Advancing b_T
      interval_start = b_T
      
      trans_prob = b_tMC[b_state, -b_state] / b_tLT[b_state]
      
      while (sum(trans_prob) == 0) {
        trans_prob = b_tMC[-b_state, b_state] / b_tLT[b_state]
        rate_prob = rexp(length(trans_prob), trans_prob)
        rate_prob[is.na(rate_prob)] = max(rate_prob[!is.na(rate_prob)]) + 1
        b_stateN = which.min(rate_prob)
        if (b_stateN >= b_state) {
          b_stateN = b_stateN + 1
        }
        b_prev_state = b_state
        b_state = b_stateN
        trans_prob = b_tMC[b_state, -b_state] / b_tLT[b_state]
      }
      
      rate_prob = rexp(length(trans_prob), trans_prob)
      rate_prob[is.na(rate_prob)] = max(rate_prob[!is.na(rate_prob)]) + 1
      if (b_T + min(rate_prob) > game_duration) {
        b_LU_sim[b_state] = b_LU_sim[b_state] + (game_duration - b_T)
        b_T = game_duration
      } else {
        b_LU_sim[b_state] = b_LU_sim[b_state] + min(rate_prob)
        b_T = b_T + min(rate_prob)
      }
      b_stateN = which.min(rate_prob)
      if (b_stateN >= b_state) {
        b_stateN = b_stateN + 1
      }
      b_prev_state = b_state
      b_state = b_stateN
    }
    
    #Here we will increment scoring from what interval?
    time_interval = min(a_T, b_T) - interval_start
    
    #Adjusting coefficients to account for linear restoring force
    a_adjusted_coef = team_lineup_coef[[team_a]][a_prev_state]
    b_adjusted_coef = team_lineup_coef[[team_b]][b_prev_state]
    c = 0
    score_differential = abs(a_plus_minus - b_plus_minus)
    if (a_plus_minus > b_plus_minus) {
      #a is winning
      a_adjusted_coef = a_adjusted_coef - (score_differential * c)
      b_adjusted_coef = b_adjusted_coef + (score_differential * c)
    } else if (a_plus_minus < b_plus_minus) {
      #b is winning
      a_adjusted_coef = a_adjusted_coef + (score_differential * c)
      b_adjusted_coef = b_adjusted_coef - (score_differential * c)
    }
    
    a_plus_minus = a_plus_minus + (time_interval * a_adjusted_coef)
    b_plus_minus = b_plus_minus + (time_interval * b_adjusted_coef)
    
  } #end while loop
  return(a_plus_minus - b_plus_minus)
}

#Function for simulating best of 7 series
simulate_series <- function(team_a, team_b) {
  a_wins = 0
  b_wins = 0
  while (a_wins < 4 && b_wins < 4) {
    differential = simulate_matchup(team_a, team_b)
    if (differential > 0) {
      a_wins = a_wins + 1
    } else if (differential < 0) {
      b_wins = b_wins + 1
    }
  } 
  if (a_wins > b_wins) {
    return(team_a)
  } else if (b_wins > a_wins){
    return(team_b)
  }
}

#Example: simulating matchup between Chicago and Golden State 
simulate_matchup("Hou", "Por")

#Example: simulating 7 game series between Indiana and Atlanta
simulate_series("Ind", "Atl")