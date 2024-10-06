import pandas as pd
import requests
import time

#Get the birth year of the artist from Wikidata
def get_birth_year(artist_name, artist_birth_years, retries=3, delay=1):
    endpoint_url="https://query.wikidata.org/sparql"

    if artist_name in artist_birth_years:
        return artist_birth_years[artist_name]

    #SPARQL query to fetch the birth year. See: https://www.mediawiki.org/wiki/API:Main_page#Endpoint
    query = '''
    SELECT ?artist ?artistLabel ?dateOfBirth WHERE {
      ?artist ?label "%s"@en.
      ?artist wdt:P569 ?dateOfBirth.
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
                #Success, return the birth year
                date_of_birth = results[0].get('dateOfBirth', {}).get('value', None)
                artist_birth_years[artist_name] = date_of_birth  # Store the birth year
                return date_of_birth
            break #(won't break into else, breaks out of the loop) 
        else:
            print(f"Error fetching data for {artist_name}, status code: {response.status_code}. Attempt {attempt + 1} of {retries}.")
            if response.status_code in [429, 500, 502, 503, 504]:
                time.sleep(delay * (attempt + 1)) #Increasing delay backoff, seems to help
            else:
                break #Don't try again on non-retryable error

    #Failed to get the birth place
    artist_birth_years[artist_name] = None
    return None