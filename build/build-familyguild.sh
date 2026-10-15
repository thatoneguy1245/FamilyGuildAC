#!/bin/bash
# Builds Family Guild server images (Playerbots fork + modules) on Unraid.
# Run from the FamilyGuild folder:  bash build/build-familyguild.sh
# Makes images tagged :familyguild. Stock :master images are not touched.
set -euo pipefail
cd "$(dirname "$0")/.."
SRC=build/src
git_() { docker run --rm -v "$PWD/build:/git" -w /git alpine/git "$@"; }

if [ ! -d "$SRC/.git" ]; then
  git_ clone --depth 1 -b Playerbot https://github.com/mod-playerbots/azerothcore-wotlk.git src
else
  git_ -C src pull --ff-only
fi

for repo in \
  mod-playerbots/mod-playerbots \
  azerothcore/mod-ale \
  azerothcore/mod-autobalance \
  azerothcore/mod-transmog \
  azerothcore/mod-learn-spells \
  azerothcore/mod-ah-bot \
  azerothcore/mod-account-mounts \
  azerothcore/mod-random-enchants \
  azerothcore/mod-skip-dk-starting-area; do
  name=${repo#*/}
  if [ -d "$SRC/modules/$name" ]; then git_ -C "src/modules/$name" pull --ff-only
  else git_ clone --depth 1 "https://github.com/$repo.git" "src/modules/$name"; fi
done

cd "$SRC"
DOCKER_IMAGE_TAG=familyguild docker compose build ac-db-import ac-worldserver ac-authserver
docker tag acore/ac-wotlk-client-data:master acore/ac-wotlk-client-data:familyguild
echo "Done. Images tagged :familyguild are ready."
