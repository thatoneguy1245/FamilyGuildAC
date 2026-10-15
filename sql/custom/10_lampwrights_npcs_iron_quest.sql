-- Family Guild upgrades: quartermaster 900012, blessing NPC 900013, Iron promotion quest 900101.
-- Clones Halric (900011) and Mira (900010) so it fits this server's exact schema.
-- Safe to run twice. Undo: 90_undo_upgrades.sql
DELETE FROM creature_template WHERE entry IN (900012, 900013);
CREATE TEMPORARY TABLE fg_ct SELECT * FROM creature_template WHERE entry IN (900010, 900011);
UPDATE fg_ct SET entry = 900012, name = 'Bryn Ledger', subname = 'Lampwrights Quartermaster', npcflag = 128, gossip_menu_id = 0, ScriptName = '', AIName = '' WHERE entry = 900011;
UPDATE fg_ct SET entry = 900013, name = 'Sister Lumen', subname = 'Lampwrights Blessings', npcflag = 1, gossip_menu_id = 0, ScriptName = '', AIName = '' WHERE entry = 900010;
INSERT INTO creature_template SELECT * FROM fg_ct;
DROP TEMPORARY TABLE fg_ct;

-- Copy model rows too, if this build keeps models in creature_template_model.
SET @has_ctm = (SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = DATABASE() AND table_name = 'creature_template_model');
SET @q = IF(@has_ctm > 0, 'DELETE FROM creature_template_model WHERE CreatureID IN (900012, 900013)', 'DO 0');
PREPARE s FROM @q; EXECUTE s; DEALLOCATE PREPARE s;
SET @q = IF(@has_ctm > 0, 'CREATE TEMPORARY TABLE fg_ctm SELECT * FROM creature_template_model WHERE CreatureID IN (900010, 900011)', 'DO 0');
PREPARE s FROM @q; EXECUTE s; DEALLOCATE PREPARE s;
SET @q = IF(@has_ctm > 0, 'UPDATE fg_ctm SET CreatureID = IF(CreatureID = 900011, 900012, 900013)', 'DO 0');
PREPARE s FROM @q; EXECUTE s; DEALLOCATE PREPARE s;
SET @q = IF(@has_ctm > 0, 'INSERT INTO creature_template_model SELECT * FROM fg_ctm', 'DO 0');
PREPARE s FROM @q; EXECUTE s; DEALLOCATE PREPARE s;
SET @q = IF(@has_ctm > 0, 'DROP TEMPORARY TABLE fg_ctm', 'DO 0');
PREPARE s FROM @q; EXECUTE s; DEALLOCATE PREPARE s;

-- [Iron] Plate Promotion: from Halric, level 10, after Copper contract 900004.
DELETE FROM quest_template WHERE ID = 900101;
INSERT INTO quest_template (ID, QuestType, QuestLevel, MinLevel, QuestSortID, Flags, RewardMoney, LogTitle, LogDescription, QuestDescription, QuestCompletionLog)
VALUES (900101, 2, 10, 10, 4395, 0, 1000, '[Iron] Plate Promotion',
 'Speak with Halric Stone to receive your Iron plate.',
 'You have finished every Copper contract, $n. Copper plates belong to beginners. Take this Iron plate and wear it with pride. Bryn Ledger will now sell you Iron gear.',
 'Return to Halric Stone.');
DELETE FROM quest_template_addon WHERE ID = 900101;
INSERT INTO quest_template_addon (ID, PrevQuestID) VALUES (900101, 900004);
DELETE FROM quest_offer_reward WHERE ID = 900101;
INSERT INTO quest_offer_reward (ID, RewardText) VALUES (900101, 'Welcome to Iron rank, $n.');
DELETE FROM creature_queststarter WHERE quest = 900101;
DELETE FROM creature_questender WHERE quest = 900101;
INSERT INTO creature_queststarter (id, quest) VALUES (900011, 900101);
INSERT INTO creature_questender (id, quest) VALUES (900011, 900101);
