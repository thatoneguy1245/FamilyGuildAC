# Upgrades 1-4: ready to apply

Nothing here has been applied yet. Do the parts in order. Every block starts with `cd /mnt/user/Rompecuori/FamilyGuild`; paste each block into the Unraid web Terminal.

Before step 3, apply Copper quest 900004 (its own page). The Iron promotion needs it.

## 0a. Back up the database (always do this first)

```
cd /mnt/user/Rompecuori/FamilyGuild
mkdir -p backups
DBPW=$(grep ^DOCKER_DB_ROOT_PASSWORD= .env | cut -d= -f2)
docker compose exec -T ac-database mysqldump -uroot -p"$DBPW" --databases acore_auth acore_characters acore_world > backups/fg-$(date +%F-%H%M).sql
ls -lh backups
```

The newest file should be bigger than 100 MB. **Restore (rollback for anything below):**

```
cd /mnt/user/Rompecuori/FamilyGuild
DBPW=$(grep ^DOCKER_DB_ROOT_PASSWORD= .env | cut -d= -f2)
docker compose stop ac-worldserver
docker compose exec -T ac-database mysql -uroot -p"$DBPW" < backups/PUT-FILE-NAME-HERE.sql
docker compose start ac-worldserver
```

## 0b. New passwords

Pick two new passwords, using only letters and numbers. Replace NEW_DB_PASSWORD below with yours.

Database root password:

```
cd /mnt/user/Rompecuori/FamilyGuild
DBPW=$(grep ^DOCKER_DB_ROOT_PASSWORD= .env | cut -d= -f2)
docker compose exec -T ac-database mysql -uroot -p"$DBPW" -e "ALTER USER 'root'@'%' IDENTIFIED BY 'NEW_DB_PASSWORD'; ALTER USER 'root'@'localhost' IDENTIFIED BY 'NEW_DB_PASSWORD';"
cp .env .env.before-password
sed -i 's/^DOCKER_DB_ROOT_PASSWORD=.*/DOCKER_DB_ROOT_PASSWORD=NEW_DB_PASSWORD/' .env
docker compose up -d
DBPW=$(grep ^DOCKER_DB_ROOT_PASSWORD= .env | cut -d= -f2)
docker compose exec -T ac-database mysql -uroot -p"$DBPW" -e "SET GLOBAL innodb_flush_log_at_trx_commit=2; SET GLOBAL sync_binlog=0;"
```

phpMyAdmin also uses the new password now. **Rollback:** run the same ALTER USER line again with the old password, then run `cp .env.before-password .env` and `docker compose up -d`.

GM account: log in as familyadmin and type this in game chat (put your new password in twice):
`.account set password familyadmin NEW_GM_PASSWORD NEW_GM_PASSWORD`

## Get the files onto Unraid

This only adds the new folders. It doesn't change .env or the compose files.

```
cd /mnt/user/Rompecuori/FamilyGuild
wget -O /tmp/fg.tar.gz https://github.com/thatoneguy1245/FamilyGuildAC/archive/refs/heads/server-upgrades-1-4.tar.gz
tar -xzf /tmp/fg.tar.gz --strip-components=1 FamilyGuildAC-server-upgrades-1-4/scripts/lua/familyguild FamilyGuildAC-server-upgrades-1-4/sql/custom FamilyGuildAC-server-upgrades-1-4/build
ls scripts/lua/familyguild sql/custom build
```

## 1 + 2. Lua scripts and plate gear (works on the current server)

What you get:
- **Sister Lumen** (900013) gives buffs that match your level: Fortitude, Mark of the Wild, Arcane Intellect, and Kings from level 20.
- **Bryn Ledger** (900012) is the quartermaster. He sells 13 Copper items (level 5) and 13 Iron items (level 15) in cloth, leather and mail, plus weapons and a shield.
- Iron items only show up after **[Iron] Plate Promotion** (quest 900101). Halric gives it at level 10, once Copper contract 900004 is done, and announces each promotion.
- Your plate is shown when you log in and whenever you type `#plate` in chat. Copper players also see their Job Board progress.

```
cd /mnt/user/Rompecuori/FamilyGuild
DBPW=$(grep ^DOCKER_DB_ROOT_PASSWORD= .env | cut -d= -f2)
docker compose exec -T ac-database mysql -uroot -p"$DBPW" acore_world < sql/custom/10_lampwrights_npcs_iron_quest.sql
docker compose exec -T ac-database mysql -uroot -p"$DBPW" acore_world < sql/custom/20_plate_gear.sql
docker compose restart ac-worldserver
```

Wait 2 minutes and delete the WoW `Cache` folder. Then, in game as GM, stand inside the Lounge and place the NPCs:
- Near Mira's desk: `.npc add 900013`
- By the wall near Halric: `.npc add 900012`
- To fix the facing, stand where the NPC should look and type `.npc set facing` while it's selected.

**Tests:**
1. Logging in shows "[Lampwrights] Your plate: Copper." If it doesn't, Lua isn't loading; send the output of `docker compose logs ac-worldserver | grep -i -E "ale|eluna|lua" | tail -20`.
2. Talking to Sister Lumen gives you buffs.
3. Bryn shows only the Copper items.
4. Take a level 10 character that has finished 900001-900004. Halric offers the Iron promotion, yells when you turn it in, and Bryn then shows the Iron items.

**Rollback:**

```
cd /mnt/user/Rompecuori/FamilyGuild
DBPW=$(grep ^DOCKER_DB_ROOT_PASSWORD= .env | cut -d= -f2)
docker compose exec -T ac-database mysql -uroot -p"$DBPW" acore_world < sql/custom/90_undo_upgrades.sql
mv scripts/lua/familyguild /tmp/familyguild-lua-off
docker compose restart ac-worldserver
```

## 3 + 4. Custom build with modules and Playerbots

This is one build from the Playerbots fork of AzerothCore. It adds Playerbots, ALE (Lua), AutoBalance, Transmog, Learn Spells, AH Bot, Account Mounts, Random Enchants and Skip DK Start.

- **Time:** about 45-90 minutes, longer on a weak CPU.
- **Space:** about 20 GB free disk and 8 GB RAM.
- The server keeps running while it builds. Your stock `:master` images stay on the machine, so switching back takes one line.

Back up first (step 0a). Then build:

```
cd /mnt/user/Rompecuori/FamilyGuild
bash build/build-familyguild.sh 2>&1 | tee build/build.log
```

It's finished when you see "Done. Images tagged :familyguild are ready." If it stops with an error, send the last 40 lines (`tail -40 build/build.log`). Usually one module doesn't match the fork yet. I'll tell you which folder under `build/src/modules/` to remove, and then you run the same command again.

Switch to the new build:

```
cd /mnt/user/Rompecuori/FamilyGuild
DBPW=$(grep ^DOCKER_DB_ROOT_PASSWORD= .env | cut -d= -f2)
docker compose exec -T ac-database mysql -uroot -p"$DBPW" -e "CREATE DATABASE IF NOT EXISTS acore_playerbots;"
cp docker-compose.override.yml docker-compose.override.stock.yml
cp build/docker-compose.override.familyguild.yml docker-compose.override.yml
cp .env .env.stock
sed -i 's/^DOCKER_IMAGE_TAG=.*/DOCKER_IMAGE_TAG=familyguild/' .env
docker compose up -d
docker compose logs -f ac-db-import
```

db-import applies each module's database changes by itself. Press Ctrl+C once it says it's done. The first worldserver start takes a few minutes while it creates about 40 bot players. Module settings come from the override file, so there are no .conf files to edit.

**AH Bot (one time):**
1. In game as GM, type `.account create ahbot AHBOT_PASSWORD`.
2. Log in as ahbot, make one character (any name, e.g. Lampmarket), and log out.
3. Run:

```
cd /mnt/user/Rompecuori/FamilyGuild
DBPW=$(grep ^DOCKER_DB_ROOT_PASSWORD= .env | cut -d= -f2)
docker compose exec -T ac-database mysql -uroot -p"$DBPW" -e "SELECT a.id AS account, c.guid FROM acore_auth.account a JOIN acore_characters.characters c ON c.account = a.id WHERE a.username = 'AHBOT';"
```

4. Put the two numbers in place of ACC and GUID below:

```
cd /mnt/user/Rompecuori/FamilyGuild
sed -i 's/AC_AUCTION_HOUSE_BOT_ACCOUNT: "0"/AC_AUCTION_HOUSE_BOT_ACCOUNT: "ACC"/; s/AC_AUCTION_HOUSE_BOT_GUID: "0"/AC_AUCTION_HOUSE_BOT_GUID: "GUID"/; s/AC_AUCTION_HOUSE_BOT_ENABLE_SELLER: "0"/AC_AUCTION_HOUSE_BOT_ENABLE_SELLER: "1"/' docker-compose.override.yml
docker compose up -d
```

**Transmog NPC:** in the Lounge, type `.npc add 190010`.

**Tests:**
1. `.server info` works and the server stays up.
2. The Dalaran Auction House fills up within about an hour.
3. Leveling up teaches your new class spells automatically.
4. The Transmog NPC opens its menu.
5. Dungeons feel the right size for 1-3 players.
6. Bots work (see below).
7. Your login plate message still shows.

**Rollback to stock:**

```
cd /mnt/user/Rompecuori/FamilyGuild
cp .env.stock .env
cp docker-compose.override.stock.yml docker-compose.override.yml
docker compose up -d
```

If the stock worldserver complains about the database after switching back, restore the backup from 0a.

## How to use the bots (Playerbots)

**Your own characters as helpers.** Log in on one character and type `.playerbots bot add OtherCharName` in chat. Your other character on the same account joins as a bot. Invite it to your party with `/invite OtherCharName`, and send it away again with `.playerbots bot remove OtherCharName`.

**Quick helper of a class.** Type `.playerbots bot addclass priest`; it also works with warrior, mage and the other classes.

**Orders.** Type these in party chat (/p):
- `follow`: come with me
- `stay`: wait here
- `attack`: attack my target
- `flee`: run away
- `summon`: come to me
- `leave`: leave the party

**Random bots.** About 20-40 bots wander the world and can be invited like players. Their chat broadcasts are off. To have none, set both RANDOM_BOTS numbers in `docker-compose.override.yml` to "0" and run `docker compose up -d`.

**Optional:** the MultiBot addon gives bot buttons instead of typed commands. It's a normal addon, not a client patch.
