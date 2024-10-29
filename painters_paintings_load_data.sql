-- C:\GitHubRepo\ArtProject\PainterPalette\datasets
drop schema IF EXISTS painterpalette;
create schema painterpalette;
USE painterpalette;

-- Naming conventions: Tables with first letter capital, columns with camelCase

-- Load painters (from the PainterPalette project)
DROP TABLE IF EXISTS Artists;
CREATE TABLE Artists (
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
CREATE INDEX idx_artist_artistName ON Artists (artistName);

-- LOAD DATA INFILE 'C:/GitHubRepo/DataEngineering-SQL/datasets/artists_dollar_separator.csv'
LOAD DATA INFILE 'C:/GitHubRepo/DataEngineering-SQL/datasets/artists_indexed_new.csv'
INTO TABLE Artists
-- FIELDS TERMINATED BY '$'
FIELDS TERMINATED BY ','  
OPTIONALLY ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(artistId, artistName, nationality, citizenship, gender, styles, movement, art500kMovements, birthPlace, deathPlace,
birthYear, deathYear, firstYear, lastYear, wikiartPicturesCount, locations, locationsWithYears, stylesExtended, stylesCount,
stylesYears, occupations, paintingsExhibitedAt, paintingsExhibitedAtCount, paintingSchool, influencedBy, influencedOn,
pupils, teachers, friendsAndCoworkers, contemporary, artMovement, occupationType)
SET deathYear = CASE WHEN deathYear = '' THEN NULL ELSE deathYear END,
    birthYear = CASE WHEN birthYear = '' THEN NULL ELSE birthYear END,
    firstYear = CASE WHEN firstYear = '' THEN NULL ELSE firstYear END,
    lastYear = CASE WHEN lastYear = '' THEN NULL ELSE lastYear END,
    wikiartPicturesCount = CASE WHEN wikiartPicturesCount = '' THEN NULL ELSE wikiartPicturesCount END;
    
-- Set auto increment after loading, from the last index    
SET @max_id = (SELECT MAX(artistId) FROM Artists);
-- Appearantly, DDL (Data Definition Language) statements like ALTER TABLE, not even inside a stored procedure, so had to do the following

SET @sql = CONCAT('ALTER TABLE Artists AUTO_INCREMENT = ', @max_id + 1); -- dynamic SQL statement
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Check the table
select * from Artists;


-- Load WikiArt paintings dataset
CREATE TABLE IF NOT EXISTS WikiartPaintings (
  paintingId INT NOT NULL PRIMARY KEY,
  artistName VARCHAR(255),
  style VARCHAR(255),
  genre VARCHAR(255),
  movement VARCHAR(255),
  tags TEXT
);

LOAD DATA INFILE 'C:/GitHubRepo/DataEngineering-SQL/datasets/paintings_wikiart_indexed.csv'
INTO TABLE WikiartPaintings
FIELDS TERMINATED BY ','  
OPTIONALLY ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(paintingId, artistName, style, genre, movement, tags);

SET @max_id = (SELECT MAX(paintingId) FROM WikiartPaintings);
SET @sql = CONCAT('ALTER TABLE WikiartPaintings AUTO_INCREMENT = ', @max_id + 1); -- dynamic SQL statement
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SELECT * FROM WikiartPaintings;

-- Load Art500k paintings dataset

CREATE TABLE IF NOT EXISTS Art500kPaintings (
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
INTO TABLE Art500kPaintings
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(paintingId, authorName, genre, style, nationality, paintingSchool, artMovement, dateYear, influencedBy, influencedOn, tag, pupils, locations, teachers, friendsAndCoworkers);

SET @max_id = (SELECT MAX(paintingId) FROM Art500kPaintings);
SET @sql = CONCAT('ALTER TABLE Art500kPaintings AUTO_INCREMENT = ', @max_id + 1); -- dynamic SQL statement
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SELECT COUNT(paintingId) FROM Art500kPaintings;

-- Join paintings: WikiArt and Art500k

CREATE TABLE IF NOT EXISTS Paintings (
  paintingId INT AUTO_INCREMENT PRIMARY KEY,
  artistName VARCHAR(255), -- Index on artist name?
  style VARCHAR(255),
  genre VARCHAR(255),
  movement VARCHAR(255),
  tags TEXT,
  nationality VARCHAR(255),
  paintingSchool VARCHAR(255),
  -- artMovement VARCHAR(255),
  dateYear VARCHAR(255),
  influencedBy VARCHAR(255),
  influencedOn VARCHAR(255),
  -- tag VARCHAR(255),
  pupils VARCHAR(255),
  locations VARCHAR(255),
  teachers VARCHAR(255),
  friendsAndCoworkers VARCHAR(255),
  artist_artistId INT NULL DEFAULT NULL,
  INDEX fk_combinedpaintings_artist_idx (artist_artistId ASC) VISIBLE,
  CONSTRAINT fk_combinedpaintings_artist
    FOREIGN KEY (artist_artistId)
    REFERENCES painterpalette.Artists (artistId)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION -- partially generated using MySQL Workbench
);
CREATE INDEX idx_combinedpaintings_artistName ON Paintings (artistName);

-- To not insert IDs (those might overlap between the two datasets), we just use auto increment
INSERT INTO Paintings (artistName, style, genre, movement, tags)
SELECT artistName, style, genre, movement, tags
FROM WikiartPaintings;
INSERT INTO Paintings (artistName, genre, style, nationality, paintingSchool, movement, dateYear, influencedBy, influencedOn, tags, pupils, locations, teachers, friendsAndCoworkers)
SELECT authorName, genre, style, nationality, paintingSchool, artMovement, dateYear, influencedBy, influencedOn, tag, pupils, locations, teachers, friendsAndCoworkers
FROM Art500kPaintings;

-- Drop basis tables for memory (might not be good to drop)
DROP TABLE Art500kPaintings;
DROP TABLE WikiartPaintings;

-- Remove duplicates
WITH DuplicateArtists AS (
  SELECT MIN(artistId) as artistIdToKeep
  FROM Artists
  GROUP BY artistName
)
DELETE FROM Artists
WHERE artistId NOT IN (SELECT artistIdToKeep FROM DuplicateArtists);

-- Here, it is important that no artists appear twice, else joins will have multiple pairs for one artist.
-- This can be checked via comparing the two results:
-- SELECT count(*) FROM Paintings;
-- SELECT count(*) FROM Paintings cp LEFT JOIN painterpalette.Artists a ON cp.artistName = a.artistName;
-- Or SELECT artistname FROM Artists group by artistname having count(artistname)>1;

-- Add the ID values based on the artistName (can be null possibly)
UPDATE Paintings cp
JOIN Artists a ON cp.artistName = a.artistName
SET cp.artist_artistId = a.artistId;

SELECT * FROM Paintings;
SELECT * FROM Artists;

-- Movements
CREATE TABLE Movements (
    movementId INT AUTO_INCREMENT PRIMARY KEY,
    movementName VARCHAR(255) -- UNIQUE
);

-- Add foreign key
ALTER TABLE Artists -- should move this into the Artists table creation
ADD movementId INT;
ALTER TABLE Artists
ADD CONSTRAINT fk_movementId FOREIGN KEY (movementId) REFERENCES Movements(movementId);

-- Styles
CREATE TABLE Styles (
    styleId INT AUTO_INCREMENT PRIMARY KEY,
    styleName VARCHAR(255) -- UNIQUE
    -- e.g. date ranges: min-max,
    -- most common country (nationality)
);

-- Add foreign key
ALTER TABLE Paintings
ADD styleId INT;
ALTER TABLE Paintings -- will have to index 
ADD CONSTRAINT fk_styleId FOREIGN KEY (styleId) REFERENCES Styles(styleId);

-- Institutions
CREATE TABLE Institutions (
    institutionId INT AUTO_INCREMENT PRIMARY KEY,
    institutionName TEXT -- UNIQUE
    -- location
);

-- N:M relationship inbetween table (e.g. like in class)
CREATE TABLE ArtistInstitutions (
    artistId INT,
    institutionId INT,
    PRIMARY KEY (artistId, institutionId),
    FOREIGN KEY (artistId) REFERENCES Artists(artistId),
    FOREIGN KEY (institutionId) REFERENCES Institutions(institutionId)
);

-- TODO add the data for the movements, styles, institutions


-- TODO
-- Movements (painter), styles (painting) further data - fill with data e.g. dates
-- e.g. date ranges: min-max, 
-- maybe most common nationalities
-- Locations: separated by comma | Should have an origin of country, maybe computed by NLP somehow or Wiki



-- Analytics:
-- All analytics should run on one (normalized) table. Analytical layer table.
-- E.g. new painting added is a "fact", these are some dimensions of information: painter: name, gender, nationality, citizenship,
-- movement of painter: e.g. most common period
-- institution of painter: e.g. location, etc.
-- style of painting: period, common in which country/movement
-- location as dimension? location and its country, /painter's birthplace?/. (Time, movement of time, style)

-- Using this we can construct an analytics plan:
-- Styles per painting school/institution etc. Can check what is the most common for each institution
-- Most common movements for styles, most common style per movement, but exclude the style==movement counts
-- Maybe: Something with painters, where count matters

-- Data marts for these specific queries

-- EDW (ETL Pipeline): When a painting is added, trigger events etc. (possibly add a new painter if the painter doesn't exist and so on... update first last years etc.)