-- Need a script to update the corresponding tables (e.g. the combined paintings table)

-- New painting to PaintingWikiart
INSERT INTO PaintingWikiart (artistName, style, genre, movement, tags)
VALUES ('New Artist', 'New Style', 'New Genre', 'New Movement', 'New Tags');

-- Script to update CombinedPaintings (trigger)
INSERT INTO CombinedPaintings (artistName, style, genre, movement, tags)
VALUES ('New Artist', 'New Style', 'New Genre', 'New Movement', 'New Tags');