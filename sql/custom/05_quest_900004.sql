-- Family Guild: Copper field quest 900004 "[Copper] Clear the Training Ring"
-- Starts at the Lampwrights Job Board (gameobject 900100), ends at Halric Stone (900011).
-- Goal: defeat 8 Copper Shardlings (900050) in the training ring below Dalaran.
-- Unlocks after 900003 "Learn the Plate Rules".
-- Also gives Halric a "take me to the training ring" gossip option (menu 900030, option 9).
-- Safe to run twice: it only removes and re-adds its own 900004 / option 9 rows.
SET NAMES utf8mb4;

DELETE FROM quest_template          WHERE ID = 900004;
DELETE FROM quest_template_addon    WHERE ID = 900004;
DELETE FROM quest_request_items     WHERE ID = 900004;
DELETE FROM quest_offer_reward      WHERE ID = 900004;
DELETE FROM gameobject_queststarter WHERE quest = 900004;
DELETE FROM creature_questender     WHERE quest = 900004;

INSERT INTO quest_template
  (ID, QuestType, QuestLevel, MinLevel, QuestSortID, RewardXPDifficulty, RewardMoney, Flags,
   RequiredNpcOrGo1, RequiredNpcOrGoCount1,
   LogTitle, LogDescription, QuestDescription, AreaDescription, QuestCompletionLog,
   ObjectiveText1, ObjectiveText2, ObjectiveText3, ObjectiveText4, VerifiedBuild)
VALUES
  (900004, 2, 2, 1, 4395, 5, 50, 0,
   900050, 8,
   '[Copper] Clear the Training Ring',
   'Defeat 8 Copper Shardlings at the training ring below Dalaran, then report to Halric Stone in the Legerdemain Lounge.',
   'Copper plates learn by doing. The guild keeps a ring of Copper Shardlings on the ground below Dalaran so new members can practice where it is safe.$B$BAsk Guild Master Halric Stone to send you down to the ring. Break 8 Shardlings, then come back to him. Your hearthstone will bring you home.$B$BBring a friend if you like. Lampwrights work better together.',
   '',
   'Return to Halric Stone in the Legerdemain Lounge.',
   '', '', '', '', 0);

INSERT INTO quest_template_addon (ID, PrevQuestID) VALUES (900004, 900003);

INSERT INTO quest_request_items (ID, EmoteOnComplete, EmoteOnIncomplete, CompletionText, VerifiedBuild)
VALUES (900004, 1, 1, 'Back from the ring already? Show me how many Shardlings you broke.', 0);

INSERT INTO quest_offer_reward (ID, Emote1, RewardText, VerifiedBuild)
VALUES (900004, 4, 'Eight Shardlings, broken clean. That is real field work, $N. Keep this up and your Copper plate will turn to Iron before you know it.', 0);

INSERT INTO gameobject_queststarter (id, quest) VALUES (900100, 900004);
INSERT INTO creature_questender    (id, quest) VALUES (900011, 900004);

-- Halric's ride down to the ring
DELETE FROM gossip_menu_option WHERE MenuID = 900030 AND OptionID = 9;
INSERT INTO gossip_menu_option
  (MenuID, OptionID, OptionIcon, OptionText, OptionBroadcastTextID, OptionType, OptionNpcFlag,
   ActionMenuID, ActionPoiID, BoxCoded, BoxMoney, BoxText, BoxBroadcastTextID, VerifiedBuild)
VALUES
  (900030, 9, 2, 'Send me down to the training ring.', 0, 1, 1, 0, 0, 0, 0, '', 0, 0);

UPDATE creature_template SET AIName = 'SmartAI' WHERE entry = 900011 AND (ScriptName = '' OR ScriptName IS NULL);

DELETE FROM smart_scripts WHERE entryorguid = 900011 AND source_type = 0 AND id IN (0, 1);
INSERT INTO smart_scripts
  (entryorguid, source_type, id, link, event_type, event_phase_mask, event_chance, event_flags,
   event_param1, event_param2, event_param3, event_param4, event_param5, event_param6,
   action_type, action_param1, action_param2, action_param3, action_param4, action_param5, action_param6,
   target_type, target_param1, target_param2, target_param3, target_param4,
   target_x, target_y, target_z, target_o, comment)
VALUES
  (900011, 0, 0, 1, 62, 0, 100, 0,  900030, 9, 0, 0, 0, 0,  72, 0, 0, 0, 0, 0, 0,  7, 0, 0, 0, 0,  0, 0, 0, 0,
   'Halric Stone - On gossip option 9 selected - Close gossip'),
  (900011, 0, 1, 0, 61, 0, 100, 0,  0, 0, 0, 0, 0, 0,  62, 571, 0, 0, 0, 0, 0,  7, 0, 0, 0, 0,  5770, 480, 201, 0,
   'Halric Stone - Linked - Teleport invoker to Copper Shardling training ring');

-- Show the result
SELECT ID, LogTitle FROM quest_template WHERE ID = 900004;
SELECT MenuID, OptionID, OptionText FROM gossip_menu_option WHERE MenuID = 900030;
SELECT entry, AIName FROM creature_template WHERE entry = 900011;
