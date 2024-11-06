USE painterpalette;

-- ---------------------------- Process when a painting is added to the Paintings table ----------------------------

-- Steps:
-- 1. If the artistName is not null, check if the artist exists. If not, update the Artists table.
-- 2. Foreign key update (Paintings table)
-- 3. Add the styles if needed to the Styles table
-- 4. Update the PaintingStyles table
-- 5. Add the new instance into the analytical table

DROP TRIGGER IF EXISTS after_painting_insert;
DELIMITER //
CREATE TRIGGER after_painting_insert
    AFTER INSERT ON Paintings FOR EACH ROW
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
            SET artistId = LAST_INSERT_ID();
        END IF;

        -- 2)
        UPDATE Paintings
        SET artist_artistId = artistId
        WHERE paintingId = NEW.paintingId;
    END IF;

    -- Handle comma-separated styles
    IF NEW.style IS NOT NULL THEN
        WHILE LOCATE(',', NEW.style) > 0 DO
            SET styleName_ = TRIM(SUBSTRING_INDEX(NEW.style, ',', 1));
            SET NEW.style = TRIM(SUBSTRING(NEW.style FROM LOCATE(',', NEW.style) + 1)); -- We remove the first style from the string
            
            SELECT styleId INTO styleId_
            FROM Styles
            WHERE styleName = styleName_;

            -- 3) 
            IF styleId_ IS NULL THEN
                INSERT INTO Styles (styleName)
                VALUES (styleName_);
                SET styleId = LAST_INSERT_ID();
            END IF;
            --4)
            INSERT INTO PaintingStyles (paintingId, styleId)
            VALUES (NEW.paintingId, styleId_);
        END WHILE;
        -- One last (possibly the only) style, after the last comma

        SET styleName_ = TRIM(NEW.style);
        SELECT styleId INTO styleId_
        FROM Styles
        WHERE styleName = styleName_;
        IF styleId_ IS NULL THEN
            INSERT INTO Styles (styleName)
            VALUES (styleName_);
            SET styleId = LAST_INSERT_ID();
        END IF;
        INSERT INTO PaintingStyles (paintingId, styleId)
        VALUES (NEW.paintingId, styleId_);
    END IF;
END;
//
DELIMITER ;