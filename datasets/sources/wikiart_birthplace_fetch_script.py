import pandas as pd
import requests
import time


def get_birthplace(artist_name, artist_birthplaces, retries=3, delay=1,):
    endpoint_url="https://query.wikidata.org/sparql"

    if artist_name in artist_birthplaces:
        return artist_birthplaces[artist_name]
    
    #SPARQL query to fetch the birth place. See: https://www.mediawiki.org/wiki/API:Main_page#Endpoint
    query = '''
    SELECT ?artist ?artistLabel ?placeOfBirthLabel WHERE {
      ?artist ?label "%s"@en.
      ?artist wdt:P19 ?placeOfBirth.
      SERVICE wikibase:label { bd:serviceParam wikibase:language "en". }
    }
    LIMIT 1
    ''' % artist_name.replace('"', '\"')

    #Request, up to 'retries' times
    for attempt in range(retries):
        response = requests.get(endpoint_url, params={'query': query, 'format': 'json'})
        
        if response.status_code == 200:
            data = response.json()
            results = data.get('results', {}).get('bindings', [])
            if results:
                #Success, return the birth place
                birth_place = results[0].get('placeOfBirthLabel', {}).get('value', None)
                artist_birthplaces[artist_name] = birth_place
                return birth_place
            break #(won't break into else, breaks out of the loop) 
        else:
            print(f"Error fetching data for {artist_name}, status code: {response.status_code}. Attempt {attempt + 1} of {retries}.")
            if response.status_code in [429, 500, 502, 503, 504]:
                time.sleep(delay * (attempt + 1)) #Increasing delay backoff, seems to help
            else:
                break #Don't try again on non-retryable error

    #Failed to get the birth place
    artist_birthplaces[artist_name] = None
    return None

if __name__ == '__main__':
    art_data = pd.read_csv("originals/wikiart_art_pieces.csv")
    non_artists = ['Byzantine Mosaics', 'Orthodox Icons', 'Romanesque Architecture']
    art_data = art_data[~art_data['artist'].isin(non_artists)]

    art_data['birth_place'] = None 
    artist_birthplaces = {} #Dict for birthplaces (no repeated API calls this way)
    
    for index, row in art_data.iterrows():
        artist_name = row['artist']
        birth_place = get_birthplace(artist_name, artist_birthplaces)
        art_data.at[index, 'birth_place'] = birth_place
        print(f"Fetched birthplace for {artist_name}: {birth_place}") #progress, as this can take a while
    
    art_data.to_csv("wikiart_paintings_with_artist_birthplaces.csv", index=False)
    art_data_with_birth_places = pd.read_csv("wikiart_paintings_with_artist_birthplaces.csv") #Reload, for safety
    #Manually add some missing birthplaces
    manual = pd.read_csv('artist_birth_work_places_manually_created.csv')
    for i, row in art_data_with_birth_places.iterrows():
        for j, row2 in manual.iterrows():
            if row['artist'] == row2['artist']:
                row['birth_place'] = row2['birth_place']
    #Clean
    art_data_cleaned = art_data_with_birth_places[(art_data_with_birth_places['birth_place'].notna())]
    art_data_cleaned.to_csv("wikiart_paintings_with_artist_birthplaces_cleaned.csv", index=False)