import pandas as pd
import numpy as np
import random


def load_and_prepare_data(filepath):
    pass
    # raw_data = pd.read_csv(filepath)
    
    # lineup_ids = raw_data.columns[3:10]  
    
    # transition_matrix = np.random.rand(len(lineup_ids), len(lineup_ids))
    # np.fill_diagonal(transition_matrix, 0)
    # transition_matrix /= transition_matrix.sum(axis=1, keepdims=True)

    # scoring_rates = np.random.rand(len(lineup_ids))
    # lineup_times = np.random.rand(len(lineup_ids)) * 100 + 100    
    # starting_probs = np.random.rand(len(lineup_ids))
    # starting_probs /= starting_probs.sum() 
    # team_subMC = {'Atl': transition_matrix}
    # team_lineups = {'Atl': lineup_ids.to_list()}
    # team_lineup_times = {'Atl': lineup_times}
    # team_lineup_starting = {'Atl': starting_probs}
    # team_pL = {'Atl': np.column_stack((np.arange(len(lineup_ids)), scoring_rates))}
    
    # return team_subMC, team_lineups, team_lineup_times, team_lineup_starting, team_pL

def simulate_single_game(team_subMC, team_lineups, team_lineup_times, team_lineup_starting, team_pL, team_name):
    tMC = team_subMC[team_name] 
    tLU = team_lineups[team_name]  
    tLT = team_lineup_times[team_name]  
    tLS = team_lineup_starting[team_name] 
    tPL = team_pL[team_name][:, 1]

    #lineup time
    LU_sim = np.zeros(tMC.shape[0])

    # starting state disttribution
    state = random.choices(range(len(tLS)), weights=tLS)[0]
    T = 0

    while T < (48 * 60):
        if np.sum(tMC[state, :]) == 0:
            continue
        
        trans_prob = np.delete(tMC[state, :], state) / tLT[state]
        rate_prob = np.random.exponential(1/trans_prob)
        rate_prob[np.isnan(rate_prob)] = np.max(rate_prob[~np.isnan(rate_prob)]) + 1

        if T + np.min(rate_prob) > 2880:
            T = 2880
        else:
            T += np.min(rate_prob)

        stateN = np.argmin(rate_prob)
        if stateN >= state:
            stateN += 1
        
        LU_sim[state] += np.min(rate_prob)
        state = stateN

    return LU_sim

def simulate_matchup(team_a, team_b, team_subMC, team_lineups, team_lineup_times, team_lineup_starting, team_pL, team_lineup_coef):
    a_lineup_times = simulate_single_game(team_subMC, team_lineups, team_lineup_times, team_lineup_starting, team_pL, team_a)
    b_lineup_times = simulate_single_game(team_subMC, team_lineups, team_lineup_times, team_lineup_starting, team_pL, team_b)

    a_scoring_rates = team_lineup_coef[team_a]
    b_scoring_rates = team_lineup_coef[team_b]

    overall_plus_minus = np.sum(a_lineup_times * a_scoring_rates) - np.sum(b_lineup_times * b_scoring_rates)
    return overall_plus_minus