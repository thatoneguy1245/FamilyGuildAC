-- Removes everything added by 10_ and 20_ (spawned NPCs too).
DELETE FROM conditions WHERE SourceTypeOrReferenceId = 23 AND SourceGroup = 900012;
DELETE FROM npc_vendor WHERE entry = 900012;
DELETE FROM item_template WHERE entry BETWEEN 900201 AND 900233;
DELETE FROM creature_queststarter WHERE quest = 900101;
DELETE FROM creature_questender WHERE quest = 900101;
DELETE FROM quest_offer_reward WHERE ID = 900101;
DELETE FROM quest_template_addon WHERE ID = 900101;
DELETE FROM quest_template WHERE ID = 900101;
SET @c = (SELECT COLUMN_NAME FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'creature' AND COLUMN_NAME IN ('id', 'id1') LIMIT 1);
SET @q = CONCAT('DELETE FROM creature WHERE ', @c, ' IN (900012, 900013, 190010)');
PREPARE s FROM @q; EXECUTE s; DEALLOCATE PREPARE s;
SET @has_ctm = (SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = DATABASE() AND table_name = 'creature_template_model');
SET @q = IF(@has_ctm > 0, 'DELETE FROM creature_template_model WHERE CreatureID IN (900012, 900013)', 'DO 0');
PREPARE s FROM @q; EXECUTE s; DEALLOCATE PREPARE s;
DELETE FROM creature_template WHERE entry IN (900012, 900013);
