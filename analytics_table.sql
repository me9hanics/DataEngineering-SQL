-- We already filled up the separate tables with "mined" data (e.g. finding years from the style string, comma separations),
-- so most of the preparation is done
-- Here we create a table for analytics, with various dimensions to support analysis


-- Analytics table: All analytics should run on one normalized table, the "analytical layer" table.
-- In this case, every instance in the table correspond to a painting, a painting added is the "fact" - a new painting is the source of a new instance.

-- These are the other dimensions of information:
-- painter: name, gender, birthyear, nationality, citizenship,
-- Movement (of painter): earliest appearance of a work from the movement, origin location
-- Institutions (of painter): names, locations
-- Styles (of painting): origin locations

-- It's better to not have separate instances for a painting per style or artist institution (they can be multiple), hence I store
-- one instance per painting, having the distinct styles and institutions concatenated, separated by commas in the "Institutions" and "Styles" column.

USE painterpalette;

SET SESSION sort_buffer_size = 1024 * 1024 * 16; -- 16MB, MySQL limits this to 256kB by default
SET SESSION group_concat_max_len = 1024 * 1024 * 16;

DROP TABLE IF EXISTS PaintData;
CREATE TABLE PaintData AS
SELECT  p.paintingId AS PaintingID, 
        a.artistName AS Artist,
        a.gender AS Gender,
        a.birthYear as BirthYear,
        a.nationality as Nationality,
        a.citizenship as Citizenship,
        m.movementName as Movement,
        m.periodStart as EarliestYearOfMovement,
        m.majorLocation as MovementOrigin,
        GROUP_CONCAT(DISTINCT i.institutionName ORDER BY i.institutionName SEPARATOR ', ') as Institutions, -- Institution1, Institution2, ...
        GROUP_CONCAT(DISTINCT i.institutionLocation ORDER BY i.institutionLocation SEPARATOR ', ') as InstitutionLocations,
        GROUP_CONCAT(DISTINCT s.styleName ORDER BY s.styleName SEPARATOR ', ') as Styles,
        GROUP_CONCAT(DISTINCT s.majorLocation ORDER BY s.majorLocation SEPARATOR ', ') as StyleOrigins,
        p.tags as TagsOfPainting        
FROM Paintings p
LEFT JOIN Artists a
ON p.artist_artistId = a.artistId
LEFT JOIN ArtistInstitutions ai
ON a.artistId = ai.artistId
LEFT JOIN Institutions i
ON ai.institutionId = i.institutionId
LEFT JOIN Movements m
ON a.movementId = m.movementId
LEFT JOIN PaintingStyles ps
ON p.paintingId = ps.paintingId
LEFT JOIN Styles s
ON ps.styleId = s.styleId
-- Group by everything except institutions and styles, those are used for concatenation above
GROUP BY p.paintingId, a.artistName, a.gender, a.birthYear, a.nationality, a.citizenship, m.movementName, m.periodStart, m.majorLocation, p.tags
ORDER BY p.paintingId;

SELECT * FROM PaintData WHERE Styles LIKE "%,%" LIMIT 20;