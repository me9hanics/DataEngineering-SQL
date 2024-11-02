-- C:\GitHubRepo\ArtProject\PainterPalette\datasets
drop schema IF EXISTS painterpalette;
create schema painterpalette;
USE painterpalette;

-- Naming conventions: Tables with first letter capital, columns with camelCase

-- ---------------------------- Painters ----------------------------

-- Load painters (from the PainterPalette project)
DROP TABLE IF EXISTS Artists; -- this was partially generated
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
  occupationType            VARCHAR(255),
  movementId                INT NULL DEFAULT NULL,
  INDEX idx_artists_artistName (artistName)
);

LOAD DATA INFILE 'C:/GitHubRepo/DataEngineering-SQL/datasets/artists_indexed_new.csv'
INTO TABLE Artists
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

-- It is important that no artists appear twice, else painter-painting joins will have multiple instances for one painting (wrong).
-- There should be none (can be checked with SELECT artistname FROM Artists group by artistname having count(artistname)>1;) but just in case
-- Remove duplicates
WITH DuplicateArtists AS (
  SELECT MIN(artistId) as artistIdToKeep
  FROM Artists
  GROUP BY artistName
)
DELETE FROM Artists
WHERE artistId NOT IN (SELECT artistIdToKeep FROM DuplicateArtists);

-- It makes more sense to load the paintings and the painting data first, but as that is large, don't want to modify it after loading with foreign key constraints (MySQL timeouts); Better to create style and movement tables first

-- ---------------------------- Movements, Styles, Institutions tables & ArtistInstitutions ----------------------------

-- Movements: related to the artist (e.g. Impressionist), styles: related to the painting (e.g. Impressionistic painting)
CREATE TABLE Movements (
    movementId INT AUTO_INCREMENT PRIMARY KEY,
    movementName VARCHAR(255), -- UNIQUE
    periodStart INT, -- roughly start of the period year
    periodEnd INT,
    majorLocation VARCHAR(255) -- e.g. France
);
-- Add artist foreign key
ALTER TABLE Artists
ADD CONSTRAINT fk_movementId FOREIGN KEY (movementId) REFERENCES Movements(movementId);

CREATE TABLE Styles (
    styleId INT AUTO_INCREMENT PRIMARY KEY,
    styleName VARCHAR(255), -- UNIQUE
    firstDate INT, -- earliest appearance in the painting dataset
    lastDate INT,
    majorLocation VARCHAR(255),
    INDEX idx_styles_styleName (styleName),
    INDEX idx_styles_styleId (styleId)
);
-- We add style constraints in the painting table definition)

-- Institutions
CREATE TABLE Institutions (
    institutionId INT AUTO_INCREMENT PRIMARY KEY,
    institutionName TEXT, -- UNIQUE
    institutionLocation VARCHAR(255)
);
-- N:M relationship inbetween table (like in class)
CREATE TABLE ArtistInstitutions (
    artistId INT,
    institutionId INT,
    PRIMARY KEY (artistId, institutionId),
    FOREIGN KEY (artistId) REFERENCES Artists(artistId),
    FOREIGN KEY (institutionId) REFERENCES Institutions(institutionId)
);

-- ---------------------------- Paintings: Combined, WikiArt, Art500k & PaintingStyles ----------------------------
-- Paintings: we first load two datasets, then join them together for a combined table

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

SELECT * FROM WikiartPaintings LIMIT 10;

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

SELECT * FROM Art500kPaintings LIMIT 10;

-- Combination of the two datasets
CREATE TABLE IF NOT EXISTS Paintings (
  paintingId INT AUTO_INCREMENT PRIMARY KEY,
  artistName VARCHAR(255),
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

  INDEX idx_paintings_artist_artistId (artist_artistId ASC) VISIBLE,
  INDEX idx_paintings_artistName (artistName),
  INDEX idx_paintings_style (style),

  CONSTRAINT fk_combinedpaintings_artist
    FOREIGN KEY (artist_artistId)
    REFERENCES painterpalette.Artists (artistId)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
);

-- Inbetween M:N table
CREATE TABLE IF NOT EXISTS PaintingStyles (
  paintingId INT,
  styleId INT,
  PRIMARY KEY (paintingId, styleId),
  FOREIGN KEY (paintingId) REFERENCES Paintings(paintingId),
  FOREIGN KEY (styleId) REFERENCES Styles(styleId)
);

-- To not insert IDs (those might overlap between the two datasets), we just use auto increment (set)
INSERT INTO Paintings (artistName, style, genre, movement, tags)
SELECT artistName, style, genre, movement, tags
FROM WikiartPaintings;
INSERT INTO Paintings (artistName, genre, style, nationality, paintingSchool, movement, dateYear, influencedBy, influencedOn, tags, pupils, locations, teachers, friendsAndCoworkers)
SELECT authorName, genre, style, nationality, paintingSchool, artMovement, dateYear, influencedBy, influencedOn, tag, pupils, locations, teachers, friendsAndCoworkers
FROM Art500kPaintings;

-- Drop basis tables for memory (might not be good to drop)
-- DROP TABLE Art500kPaintings;
-- DROP TABLE WikiartPaintings;

-- ---------------------------- Fill up default (major) columns ----------------------------

INSERT INTO Movements (movementName)
SELECT DISTINCT movement
FROM Artists;

-- Styles: separated by comma
-- Comma separated values: We can check in one cell how many separate values (styles, later institutions) are, by seeing how many
-- commas are in it - this is easily done by with checking how many characters we lose when removing commas
-- Like this:     CHAR_LENGTH(style) - CHAR_LENGTH(REPLACE(style, ',', ''))     the value of this tells how many styles are in the string

-- The maximum amount of styles per painting is 3: SELECT MAX(CHAR_LENGTH(style) - CHAR_LENGTH(REPLACE(style, ',', '')) + 1) FROM Paintings;
-- To check separately the styles when there are more than one in a cell, we need to select each substring one by one
-- SUBSTRING_INDEX(SUBSTRING_INDEX(style, ',', numbers.n), ',', -1) gives the n-th value in the comma separated list
-- The first substring_index crops the first n values, then the second one gives the last value only

INSERT INTO Styles (styleName)
SELECT DISTINCT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(style, ',', numbers.n), ',', -1)) AS substring
FROM Paintings
JOIN (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3) numbers -- Just numbers 1, 2, 3
ON CHAR_LENGTH(style) - CHAR_LENGTH(REPLACE(style, ',', '')) >= numbers.n - 1
WHERE substring != '';

-- If we run this:

-- SELECT DISTINCT style, TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(style, ',', numbers.n), ',', -1)) AS value
-- FROM Paintings
-- JOIN (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3) numbers -- Just numbers 1, 2, 3
-- ON CHAR_LENGTH(style) - CHAR_LENGTH(REPLACE(style, ',', '')) >= numbers.n - 1 
-- where CHAR_LENGTH(style) - CHAR_LENGTH(REPLACE(style, ',', ''))>0;

-- We'd get something like this
-- style 							    value
-- Abstract Art,Abstract Expressionism	Abstract Expressionism
-- Abstract Art,Abstract Expressionism	Abstract Art
-- Abstract Art,Color Field Painting	Color Field Painting
-- Abstract Art,Color Field Painting	Abstract Art
-- ...

-- N:M relationship: we need to find all pairs
INSERT INTO PaintingStyles (paintingId, styleId)
SELECT DISTINCT p.paintingId, s.styleId
FROM Paintings p
JOIN Styles s
ON FIND_IN_SET(s.styleName, p.style)
WHERE (p.paintingId, s.styleId) NOT IN ( -- Probably unneccessary
    SELECT paintingId, styleId
    FROM PaintingStyles
);

-- This returns 6: SELECT MAX(CHAR_LENGTH(PaintingSchool) - CHAR_LENGTH(REPLACE(PaintingSchool, ',', '')) + 1) FROM Artists;
INSERT INTO Institutions (institutionName)
SELECT DISTINCT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(PaintingSchool, ',', nums.n), ',', -1)) AS value
FROM Artists
JOIN (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6) nums
ON CHAR_LENGTH(PaintingSchool) - CHAR_LENGTH(REPLACE(PaintingSchool, ',', '')) >= nums.n - 1;

-- N:M relationship
INSERT INTO ArtistInstitutions (artistId, institutionId)
SELECT a.artistId, i.institutionId
FROM Artists
JOIN Institutions i
ON FIND_IN_SET(i.institutionName, a.PaintingSchool);

-- ---------------------------- Fill up foreign key columns ----------------------------
-- Add the ID values based on the artistName, movementName, styleName (can be null)
UPDATE Paintings p
JOIN Artists a ON p.artistName = a.artistName
SET p.artist_artistId = a.artistId;

UPDATE Artists a
JOIN Movements m ON a.Movement = m.movementName
SET a.movementId = m.movementId;

-- ---------------------------- Fill up other columns ----------------------------

-- This query finds the first year in every string, and selects the minimum group by styleId
-- SELECT s.styleId, MIN(CAST(SUBSTRING(p.dateYear, LOCATE(' ', p.dateYear) + 1, 4) AS UNSIGNED)) AS minYear
-- FROM Paintings p JOIN PaintingStyles ps ON p.paintingId = ps.paintingId JOIN Styles s ON ps.styleId = s.styleId
-- WHERE p.dateYear REGEXP '[0-9]{4}' GROUP BY s.styleId;

-- Styles
UPDATE Styles s
JOIN (
    SELECT s.styleId, MIN(CAST(SUBSTRING(p.dateYear, LOCATE(' ', p.dateYear) + 1, 4) AS UNSIGNED)) AS minYear
    FROM Paintings p
    JOIN PaintingStyles ps ON p.paintingId = ps.paintingId
    JOIN Styles s ON ps.styleId = s.styleId
    WHERE p.dateYear REGEXP '[0-9]{4}'
    GROUP BY s.styleId
) AS minYears ON s.styleId = minYears.styleId
SET s.firstDate = minYears.minYear;

-- Correct the 0s to null
UPDATE Styles s
SET s.firstDate = null
WHERE s.firstDate = 0;

UPDATE Styles s
JOIN (
    SELECT s.styleId, MAX(CAST(SUBSTRING(p.dateYear, LOCATE(' ', p.dateYear) + 1, 4) AS UNSIGNED)) AS maxYear
    FROM Paintings p
    JOIN PaintingStyles ps ON p.paintingId = ps.paintingId
    JOIN Styles s ON ps.styleId = s.styleId
    WHERE p.dateYear REGEXP '[0-9]{4}'
    GROUP BY s.styleId
) AS maxYears ON s.styleId = maxYears.styleId
SET s.lastDate = maxYears.maxYear;

-- Correct the 0s to null
UPDATE Styles s
SET s.lastDate = null
WHERE s.lastDate = 0;

-- TODO majorLocation

-- Movements

-- periodStart, periodEnd, majorLocation
UPDATE Movements m
JOIN (
    SELECT m.movementId, MIN(CAST(SUBSTRING(p.dateYear, LOCATE(' ', p.dateYear) + 1, 4) AS UNSIGNED)) AS minYear
    FROM Paintings p
    JOIN Artists a ON p.artistName = a.artistName
    JOIN Movements m ON a.Movement = m.movementName
    WHERE p.dateYear REGEXP '[0-9]{4}'
    GROUP BY m.movementId
) AS minYears ON m.movementId = minYears.movementId
SET m.periodStart = minYears.minYear;

-- Correct the 0s to null
UPDATE Movements m
SET m.periodStart = null
WHERE m.periodStart = 0;

UPDATE Movements m
JOIN (
    SELECT m.movementId, MAX(CAST(SUBSTRING(p.dateYear, LOCATE(' ', p.dateYear) + 1, 4) AS UNSIGNED)) AS maxYear
    FROM Paintings p
    JOIN Artists a ON p.artistName = a.artistName
    JOIN Movements m ON a.Movement = m.movementName
    WHERE p.dateYear REGEXP '[0-9]{4}'
    GROUP BY m.movementId
) AS maxYears ON m.movementId = maxYears.movementId
SET m.periodEnd = maxYears.maxYear;

-- Correct the 0s to null
UPDATE Movements m
SET m.periodEnd = null
WHERE m.periodEnd = 0;

-- TODO majorLocation

-- Institutions

-- TODO institutionLocation

-- TODO add the data for other columns (e.g. periodStart, periodEnd, majorLocation)

-- ---------------------------- Check data ----------------------------

SELECT * FROM Paintings LIMIT 100;
SELECT * FROM Artists LIMIT 100;
SELECT * FROM Movements LIMIT 100;
SELECT * FROM Styles LIMIT 100;
SELECT * FROM PaintingStyles LIMIT 100;
SELECT * FROM Institutions LIMIT 100;
SELECT * FROM ArtistInstitutions LIMIT 100;
-- TODO
-- Reorder code?
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