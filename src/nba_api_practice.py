from nba_api.stats.endpoints import playercareerstats

### for familiarising myself with the nba_api

# Nikola Jokic
career = playercareerstats.PlayerCareerStats(player_id='203999') 

# pandas data frames (optional: pip install pandas)
jokic_pd = career.get_data_frames()[0]
# jokic_pd.head()

# json
career.get_json()

# dictionary
career.get_dict()

