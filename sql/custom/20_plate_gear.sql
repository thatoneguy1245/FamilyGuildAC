-- Family Guild plate gear: Copper 900201-900213 (level 5), Iron 900221-900233 (level 15).
-- Each item clones a stock item (keeps its look, armor and damage) and sets Lampwright stats.
-- Sold by Bryn Ledger (900012). Iron items need quest 900101. Safe to run twice.
DELETE FROM item_template WHERE entry BETWEEN 900201 AND 900233;
CREATE TEMPORARY TABLE fg_map (new_entry INT, base INT, name VARCHAR(100), ilvl INT, req INT, st1 INT, st2 INT, sv INT, price INT);
INSERT INTO fg_map VALUES
(900201,2572,'Lampwright Copper Robe',10,5,5,7,2,2500),
(900202,2958,'Lampwright Copper Trousers',10,5,5,7,2,2500),
(900203,3000,'Lampwright Copper Jerkin',10,5,3,7,2,2500),
(900204,2962,'Lampwright Copper Breeches',10,5,3,7,2,2500),
(900205,3471,'Lampwright Copper Hauberk',10,5,4,7,2,2500),
(900206,2966,'Lampwright Copper Legguards',10,5,4,7,2,2500),
(900207,727,'Lampwright Copper Shortsword',10,5,4,7,2,2500),
(900208,4562,'Lampwright Copper Greataxe',10,5,4,7,2,2500),
(900209,4566,'Lampwright Copper Staff',10,5,5,7,2,2500),
(900210,1917,'Lampwright Copper Dagger',10,5,3,7,2,2500),
(900211,8180,'Lampwright Copper Longbow',10,5,3,7,2,2500),
(900212,11287,'Lampwright Copper Wand',10,5,5,7,2,2500),
(900213,7108,'Lampwright Copper Shield',10,5,4,7,2,2500),
(900221,6263,'Lampwright Iron Robe',20,15,5,7,4,10000),
(900222,2982,'Lampwright Iron Trousers',20,15,5,7,4,10000),
(900223,2317,'Lampwright Iron Jerkin',20,15,3,7,4,10000),
(900224,1934,'Lampwright Iron Breeches',20,15,3,7,4,10000),
(900225,6731,'Lampwright Iron Hauberk',20,15,4,7,4,10000),
(900226,2166,'Lampwright Iron Legguards',20,15,4,7,4,10000),
(900227,29583,'Lampwright Iron Shortsword',20,15,4,7,4,10000),
(900228,1220,'Lampwright Iron Greataxe',20,15,4,7,4,10000),
(900229,1300,'Lampwright Iron Staff',20,15,5,7,4,10000),
(900230,3184,'Lampwright Iron Dagger',20,15,3,7,4,10000),
(900231,4576,'Lampwright Iron Longbow',20,15,3,7,4,10000),
(900232,5207,'Lampwright Iron Wand',20,15,5,7,4,10000),
(900233,9778,'Lampwright Iron Shield',20,15,4,7,4,10000);
CREATE TEMPORARY TABLE fg_items SELECT i.* FROM item_template i JOIN fg_map m ON m.base = i.entry;
UPDATE fg_items i JOIN fg_map m ON m.base = i.entry SET i.entry = m.new_entry, i.name = m.name, i.Quality = 2, i.ItemLevel = m.ilvl, i.RequiredLevel = m.req,
  i.BuyPrice = m.price, i.SellPrice = m.price DIV 4, i.bonding = 1, i.AllowableClass = -1, i.AllowableRace = -1, i.Flags = 0,
  i.stat_type1 = m.st1, i.stat_value1 = m.sv, i.stat_type2 = m.st2, i.stat_value2 = m.sv,
  i.stat_type3 = 0, i.stat_value3 = 0, i.stat_type4 = 0, i.stat_value4 = 0, i.stat_type5 = 0, i.stat_value5 = 0,
  i.spellid_1 = 0, i.spellid_2 = 0, i.spellid_3 = 0, i.RandomProperty = 0, i.RandomSuffix = 0, i.itemset = 0,
  i.startquest = 0, i.ScriptName = '', i.description = 'Issued by the Lampwrights guild.';
INSERT INTO item_template SELECT * FROM fg_items;
DELETE FROM npc_vendor WHERE entry = 900012;
INSERT INTO npc_vendor (entry, slot, item) SELECT 900012, 0, new_entry FROM fg_map;
-- Iron gear only shows for players who finished the Iron promotion (condition type 8 = quest rewarded).
DELETE FROM conditions WHERE SourceTypeOrReferenceId = 23 AND SourceGroup = 900012;
INSERT INTO conditions (SourceTypeOrReferenceId, SourceGroup, SourceEntry, ConditionTypeOrReference, ConditionValue1, Comment)
  SELECT 23, 900012, new_entry, 8, 900101, 'Lampwrights: Iron gear needs Iron plate' FROM fg_map WHERE new_entry >= 900221;
DROP TEMPORARY TABLE fg_items;
DROP TEMPORARY TABLE fg_map;
