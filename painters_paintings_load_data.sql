-- C:\GitHubRepo\ArtProject\PainterPalette\datasets
drop schema IF EXISTS painterpalette;
create schema IF NOT EXISTS painterpalette;
USE painterpalette;

CREATE TABLE IF NOT EXISTS artisttable(
  id						 INT NOT NULL PRIMARY KEY
  ,artist                    VARCHAR(255)
  ,Nationality               VARCHAR(255)
  ,citizenship               VARCHAR(255)
  ,gender                    VARCHAR(255)
  ,styles                    TEXT
  ,movement                  VARCHAR(255)
  ,Art500k_Movements         TEXT
  ,birth_place               VARCHAR(255)
  ,death_place               VARCHAR(255)
  ,birth_year                INT NULL
  ,death_year                INT NULL
  ,FirstYear                 INT NULL
  ,LastYear                  INT NULL
  ,wikiart_pictures_count    INT NULL
  ,locations                 TEXT
  ,locations_with_years      TEXT
  ,styles_extended           TEXT
  ,StylesCount               TEXT
  ,StylesYears               TEXT
  ,occupations               TEXT
  ,PaintingsExhibitedAt      TEXT
  ,PaintingsExhibitedAtCount TEXT
  ,PaintingSchool            TEXT
  ,Influencedby              TEXT
  ,Influencedon              TEXT
  ,Pupils                    TEXT
  ,Teachers                  TEXT
  ,FriendsandCoworkers       TEXT
  ,Contemporary              VARCHAR(255)
  ,ArtMovement               TEXT
  ,Type                      VARCHAR(255)
  -- foreign keys?
);

-- LOAD DATA INFILE 'C:/GitHubRepo/DataEngineering-SQL/datasets/artists_dollar_separator.csv'
LOAD DATA INFILE 'C:/GitHubRepo/DataEngineering-SQL/datasets/artists_indexed.csv'
INTO TABLE artisttable
-- FIELDS TERMINATED BY '$'
FIELDS TERMINATED BY ','  
OPTIONALLY ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(id, artist, Nationality, citizenship, gender, styles, movement, Art500k_Movements, birth_place, death_place, birth_year, death_year, FirstYear, LastYear, wikiart_pictures_count, locations, locations_with_years, styles_extended, StylesCount, StylesYears, occupations, PaintingsExhibitedAt, PaintingsExhibitedAtCount, PaintingSchool, Influencedby, Influencedon, Pupils, Teachers, FriendsandCoworkers, Contemporary, ArtMovement, Type)
SET death_year = CASE WHEN death_year = '' THEN NULL ELSE death_year END,
    birth_year = CASE WHEN birth_year = '' THEN NULL ELSE birth_year END,
    FirstYear = CASE WHEN FirstYear = '' THEN NULL ELSE FirstYear END,
    LastYear = CASE WHEN LastYear = '' THEN NULL ELSE LastYear END,
    wikiart_pictures_count = CASE WHEN wikiart_pictures_count = '' THEN NULL ELSE wikiart_pictures_count END;
    
-- Set auto increment, from the last index    
SET @max_id = (SELECT MAX(id) FROM artisttable);
-- Appearantly, DDL (Data Definition Language) statements like ALTER TABLE, not even inside a stored procedure, so had to do the following

SET @sql = CONCAT('ALTER TABLE artisttable AUTO_INCREMENT = ', @max_id + 1); -- dynamic SQL statement
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Check the table

select * from artisttable;


-- Create painting dataset