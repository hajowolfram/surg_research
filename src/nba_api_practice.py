from nba_api.stats.endpoints import playercareerstats
from nba_api.stats.static import teams
from nba_api.stats.endpoints import leaguegamefinder
from nba_api.stats.library.parameters import Season
from nba_api.stats.library.parameters import SeasonType
from nba_api.stats.endpoints import playbyplay

# Nikola Jokic
career = playercareerstats.PlayerCareerStats(player_id='203999') 

# pandas data frames (optional: pip install pandas)
jokic_pd = career.get_data_frames()[0]

# json
career.get_json()

# dictionary
career.get_dict()

# get_teams returns a list of 30 dictionaries, each an NBA team.
nba_teams = teams.get_teams()

# Select the dictionary for the Pacers, which contains their team ID
pacers = [team for team in nba_teams if team['abbreviation'] == 'IND'][0]
pacers_id = pacers['id']
print(f'pacers_id: {pacers_id}')

# Query for the last regular season game where the Pacers were playing
gamefinder = leaguegamefinder.LeagueGameFinder(team_id_nullable=pacers_id,
                            season_nullable=Season.default,
                            season_type_nullable=SeasonType.regular)  

games_dict = gamefinder.get_normalized_dict()
games = games_dict['LeagueGameFinderResults']
game = games[0]
game_id = game['GAME_ID']
game_matchup = game['MATCHUP']

print(f'Searching through {len(games)} game(s) for the game_id of {game_id} where {game_matchup}')

# Query for the play by play of most recent regular season game
df = playbyplay.PlayByPlay(game_id).get_data_frames()[0]
df.head() 