-- C:\GitHubRepo\ArtProject\PainterPalette\datasets
drop schema IF EXISTS painterpalette;
create schema IF NOT EXISTS painterpalette;
USE painterpalette;

-- Load painters (from the PainterPalette project)
DROP TABLE IF EXISTS Artist;
CREATE TABLE Artist (
  artistId                  INT NOT NULL PRIMARY KEY,
  artistName                VARCHAR(255),
  nationality               VARCHAR(255),
  citizenship               VARCHAR(255),
  gender                    VARCHAR(255),
  styles                    TEXT,
  movement                  VARCHAR(255),
  art500kMovements          TEXT,
  birthPlace                VARCHAR(255),
  deathPlace                VARCHAR(255),
  birthYear                 INT NULL,
  deathYear                 INT NULL,
  firstYear                 INT NULL,
  lastYear                  INT NULL,
  wikiartPicturesCount      INT NULL,
  locations                 TEXT,
  locationsWithYears        TEXT,
  stylesExtended            TEXT,
  stylesCount               TEXT,
  stylesYears               TEXT,
  occupations               TEXT,
  paintingsExhibitedAt      TEXT,
  paintingsExhibitedAtCount TEXT,
  paintingSchool            TEXT,
  influencedBy              TEXT,
  influencedOn              TEXT,
  pupils                    TEXT,
  teachers                  TEXT,
  friendsAndCoworkers       TEXT,
  contemporary              VARCHAR(255),
  artMovement               TEXT,
  occupationType            VARCHAR(255)
  -- foreign keys?
);

-- LOAD DATA INFILE 'C:/GitHubRepo/DataEngineering-SQL/datasets/artists_dollar_separator.csv'
LOAD DATA INFILE 'C:/GitHubRepo/DataEngineering-SQL/datasets/artists_indexed.csv'
INTO TABLE Artist
-- FIELDS TERMINATED BY '$'
FIELDS TERMINATED BY ','  
OPTIONALLY ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(artistId, artistName, nationality, citizenship, gender, styles, movement, art500kMovements, birthPlace, deathPlace,
birthYear, deathYear, firstYear, lastYear, wikiartPicturesCount, locations, locationsWithYears, stylesExtended, stylesCount,
stylesYears, occupations, paintingsExhibitedAt, paintingsExhibitedAtCount, paintingSchool, influencedBy, influencedOn,
pupils, teachers, friendsAndCoworkers, contemporary, artMovement, occupationType)
SET death_year = CASE WHEN death_year = '' THEN NULL ELSE death_year END,
    birth_year = CASE WHEN birth_year = '' THEN NULL ELSE birth_year END,
    FirstYear = CASE WHEN FirstYear = '' THEN NULL ELSE FirstYear END,
    LastYear = CASE WHEN LastYear = '' THEN NULL ELSE LastYear END,
    wikiart_pictures_count = CASE WHEN wikiart_pictures_count = '' THEN NULL ELSE wikiart_pictures_count END;
    
-- Set auto increment, from the last index    
SET @max_id = (SELECT MAX(id) FROM Artist);
-- Appearantly, DDL (Data Definition Language) statements like ALTER TABLE, not even inside a stored procedure, so had to do the following

SET @sql = CONCAT('ALTER TABLE Artist AUTO_INCREMENT = ', @max_id + 1); -- dynamic SQL statement
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Check the table
select * from Artist;


-- Load WikiArt paintings dataset
CREATE TABLE IF NOT EXISTS PaintingWikiart (
  paintingId INT NOT NULL PRIMARY KEY,
  artistName VARCHAR(255),
  style VARCHAR(255),
  genre VARCHAR(255),
  movement VARCHAR(255),
  tags TEXT
);

LOAD DATA INFILE 'C:/GitHubRepo/DataEngineering-SQL/datasets/paintings_wikiart_indexed.csv'
INTO TABLE PaintingWikiart
FIELDS TERMINATED BY ','  
OPTIONALLY ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(paintingId, artistName, style, genre, movement, tags);

SET @max_id = (SELECT MAX(paintingId) FROM PaintingWikiart);
SET @sql = CONCAT('ALTER TABLE PaintingWikiart AUTO_INCREMENT = ', @max_id + 1); -- dynamic SQL statement
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SELECT * FROM PaintingWikiart;

-- Load Art500k paintings dataset

CREATE TABLE IF NOT EXISTS PaintingArt500k (
  paintingId INT NOT NULL PRIMARY KEY,
  authorName VARCHAR(255),
  genre VARCHAR(255),
  style VARCHAR(255),
  nationality VARCHAR(255),
  paintingSchool VARCHAR(255),
  artMovement VARCHAR(255),
  dateYear VARCHAR(255), -- This is a string, because of cases like "c. 1590"
  influencedBy VARCHAR(255),
  influencedOn VARCHAR(255),
  tag VARCHAR(255), -- text?
  pupils VARCHAR(255),
  locations VARCHAR(255),
  teachers VARCHAR(255),
  friendsAndCoworkers VARCHAR(255)
);

LOAD DATA INFILE 'C:/GitHubRepo/DataEngineering-SQL/datasets/paintings_art500k_indexed.csv'
INTO TABLE PaintingArt500k
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(paintingId, authorName, genre, style, nationality, paintingSchool, artMovement, dateYear, influencedBy, influencedOn, tag, pupils, locations, teachers, friendsAndCoworkers);

SELECT COUNT(paintingId) FROM PaintingArt500k;


-- Add foreign keys
ALTER TABLE PaintingWikiart
ADD FOREIGN KEY (artistName) REFERENCES Artist(artistName); -- Rather ID

-- Need to add ID foreign key, and add the values based on the artistName (can be null maybe)