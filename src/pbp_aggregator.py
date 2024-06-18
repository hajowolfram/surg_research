import numpy as np
import pandas as pd
import nba_api
import time

from nba_api.stats.endpoints import playercareerstats
from nba_api.stats.static import teams
from nba_api.stats.endpoints import leaguegamefinder
from nba_api.stats.library.parameters import Season
from nba_api.stats.library.parameters import SeasonType
from nba_api.stats.endpoints import playbyplay

#Finding id for atlanta hawks
nba_teams = teams.get_teams()
atl = [team for team in nba_teams if team['abbreviation'] == 'ATL'][0]
atl_id = atl['id']


#Query for hawks games
gamefinder = leaguegamefinder.LeagueGameFinder(team_id_nullable=atl_id,
                            season_nullable=Season.default,
                            season_type_nullable=SeasonType.regular)  

games_dict = gamefinder.get_normalized_dict()
games = games_dict['LeagueGameFinderResults']

aggregate_df = None
for i in range(82):
    curr_game_id = games[i]['GAME_ID']
    time.sleep(0.5)
    aggregate_df = pd.concat([aggregate_df, playbyplay.PlayByPlay(curr_game_id).get_data_frames()[0]])
    print("Game " + str(i) + " appended")


aggregate_df.to_csv("atl_pbp.csv", sep='\t')

print("Succesfully exported to data to csv")