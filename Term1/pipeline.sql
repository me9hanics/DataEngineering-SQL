USE painterpalette;

-- ---------------------------- New painting added to the Paintings table process ----------------------------

-- Steps:
-- 1. If the artistName is not null, check if the artist exists. If not, update the Artists table.
-- 2. Foreign key update (Paintings table)
-- 3. Add the styles if needed to the Styles table
-- 4. Update the PaintingStyles table
-- 5. Add the new instance into the analytical table

DROP TRIGGER IF EXISTS after_painting_insert;
DELIMITER //
CREATE TRIGGER after_painting_insert AFTER INSERT ON Paintings FOR EACH ROW
BEGIN
    DECLARE artistId_ INT;
    DECLARE styleName_ VARCHAR(255);
    DECLARE styleId_ INT;

    -- 1)
    IF NEW.artistName IS NOT NULL THEN
        SELECT artistId INTO artistId_ FROM Artists WHERE artistName = NEW.artistName;
        IF artistId_ IS NULL THEN
            -- Add artist
            INSERT INTO Artists (artistName, nationality)
            VALUES (NEW.artistName, NEW.nationality);
            SET artistId_ = LAST_INSERT_ID();
        END IF;

        -- 2)
        UPDATE Paintings
        SET artist_artistId = artistId_
        WHERE paintingId = NEW.paintingId;
    END IF;

    -- Handle comma-separated styles
    IF NEW.style IS NOT NULL THEN
        WHILE LOCATE(',', NEW.style) > 0 DO
            SET styleName_ = TRIM(SUBSTRING_INDEX(NEW.style, ',', 1));
            SET NEW.style = TRIM(SUBSTRING(NEW.style FROM LOCATE(',', NEW.style) + 1)); -- Remove the first style from the string
            
            SELECT styleId INTO styleId_
            FROM Styles
            WHERE styleName = styleName_;

            -- 3) 
            IF styleId_ IS NULL THEN
                INSERT INTO Styles (styleName)
                VALUES (styleName_);
                SET styleId_ = LAST_INSERT_ID();
            END IF;

            -- 4)
            INSERT INTO PaintingStyles (paintingId, styleId)
            VALUES (NEW.paintingId, styleId_);
        END WHILE;

        -- Handle the last (possibly only) style, the string after the last (if any) comma
        SET styleName_ = TRIM(NEW.style);
        SELECT styleId INTO styleId_
        FROM Styles
        WHERE styleName = styleName_;
        IF styleId_ IS NULL THEN
            INSERT INTO Styles (styleName)
            VALUES (styleName_);
            SET styleId_ = LAST_INSERT_ID();
        END IF;
        INSERT INTO PaintingStyles (paintingId, styleId)
        VALUES (NEW.paintingId, styleId_);
    END IF;

    -- 5) Update analytical table (possibly multiple instances for a painting)
    INSERT INTO PaintData (PaintingID, Year, Artist, Gender, BirthYear, Nationality, Citizenship, Movement, EarliestYearOfMovement, MovementOrigin, Institution, InstitutionLocation, Style, EarliestYearOfStyle, StyleOrigin, TagsOfPainting)
    SELECT  NEW.paintingId AS PaintingID,
            NEW.dateYear AS Year,
            a.artistName AS Artist,
            a.gender AS Gender,
            a.birthYear as BirthYear,
            a.nationality as Nationality,
            a.citizenship as Citizenship,
            m.movementName as Movement,
            m.periodStart as EarliestYearOfMovement,
            m.majorLocation as MovementOrigin,
            i.institutionName as Institution,
            i.institutionLocation as InstitutionLocation,
            s.styleName as Style,
            s.firstDate as EarliestYearOfStyle,
            s.majorLocation as StyleOrigin,
            NEW.tags as TagsOfPainting
    FROM Paintings p
    LEFT JOIN Artists a ON p.artist_artistId = a.artistId
    LEFT JOIN ArtistInstitutions ai ON a.artistId = ai.artistId
    LEFT JOIN Institutions i ON ai.institutionId = i.institutionId
    LEFT JOIN Movements m ON a.movementId = m.movementId
    LEFT JOIN PaintingStyles ps ON p.paintingId = ps.paintingId
    LEFT JOIN Styles s ON ps.styleId = s.styleId
    WHERE p.paintingId = NEW.paintingId;
END;
//
DELIMITER ;

-- ---------------------------- New painter added to the Paintings table process ----------------------------

-- Trigger steps:

-- 1) If movementName is not null, check if the movement exists. If not, add it to the Movements table.
-- 2) movementId foreign key update
-- 3) If institutionName is not null, check if the institution exists. If not, add it to the Institutions table.
-- 4) Update the ArtistInstitutions table

DROP TRIGGER IF EXISTS after_artist_insert;
DELIMITER //
CREATE TRIGGER after_artist_insert
AFTER INSERT ON Artists
FOR EACH ROW
BEGIN
    DECLARE movementId_ INT;
    DECLARE institutionName_ VARCHAR(255);
    DECLARE institutionId_ INT;

    IF NEW.movement IS NOT NULL THEN
        SELECT movementId INTO movementId_
        FROM Movements
        WHERE movementName = NEW.movement;
        
        -- 1)
        IF movementId_ IS NULL THEN
            INSERT INTO Movements (movementName)
            VALUES (NEW.movement);
            SET movementId_ = LAST_INSERT_ID();
        END IF;

        -- 2)
        UPDATE Artists
        SET movementId = movementId_
        WHERE artistId = NEW.artistId;
    END IF;

    -- Comma-separated institutions
    IF NEW.paintingSchool IS NOT NULL THEN
        WHILE LOCATE(',', NEW.paintingSchool) > 0 DO
            SET institutionName_ = TRIM(SUBSTRING_INDEX(NEW.paintingSchool, ',', 1));
            SET NEW.paintingSchool = TRIM(SUBSTRING(NEW.paintingSchool FROM LOCATE(',', NEW.paintingSchool) + 1)); -- Remove the first institution from the string
            
            SELECT institutionId INTO institutionId_
            FROM Institutions
            WHERE institutionName = institutionName_;

            -- 3)
            IF institutionId_ IS NULL THEN
                INSERT INTO Institutions (institutionName)
                VALUES (institutionName_);
                SET institutionId_ = LAST_INSERT_ID();
            END IF;

            -- 4)
            INSERT INTO ArtistInstitutions (artistId, institutionId)
            VALUES (NEW.artistId, institutionId_);
        END WHILE;

        -- Handle the last (possibly only) institution
        SET institutionName_ = TRIM(NEW.paintingSchool);
        SELECT institutionId INTO institutionId_
        FROM Institutions
        WHERE institutionName = institutionName_;
        IF institutionId_ IS NULL THEN
            INSERT INTO Institutions (institutionName)
            VALUES (institutionName_);
            SET institutionId_ = LAST_INSERT_ID();
        END IF;
        INSERT INTO ArtistInstitutions (artistId, institutionId)
        VALUES (NEW.artistId, institutionId_);
    END IF;
END;
//
DELIMITER ;