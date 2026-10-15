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
  # SKIP_MODULES="mod-a mod-b": module did not compile; park it outside modules/.
  if [[ " ${SKIP_MODULES:-} " == *" $name "* ]]; then
    if [ -d "$SRC/modules/$name" ]; then
      mkdir -p build/skipped-modules
      rm -rf "build/skipped-modules/$name"
      mv "$SRC/modules/$name" "build/skipped-modules/$name"
    fi
    echo "Skipping $name (SKIP_MODULES)."
    continue
  fi
  if [ -d "$SRC/modules/$name" ]; then git_ -C "src/modules/$name" pull --ff-only
  else git_ clone --depth 1 "https://github.com/$repo.git" "src/modules/$name"; fi
done

cd "$SRC"
# Tower has no SSD and docker.img sits on a parity HDD (~20 MB/s), so apt and
# compile I/O in the default builder takes hours. Build in a throwaway BuildKit
# container whose state lives in RAM (tmpfs), capped in CPU and memory so the
# live server keeps its share. Only the finished images are written to disk.
BK=fg-buildkit
BK_CPUS=${BK_CPUS:-0-11}
BK_MEM=${BK_MEM:-36g}
BK_TMPFS=${BK_TMPFS:-28g}
stop_bk() { docker stop "$BK" >/dev/null 2>&1 || true; }  # --rm: stopping also removes it
trap stop_bk EXIT
if ! docker ps --format '{{.Names}}' | grep -qx "$BK"; then
  docker run -d --rm --privileged --name "$BK" \
    --cpuset-cpus "$BK_CPUS" --memory "$BK_MEM" \
    --tmpfs "/var/lib/buildkit:rw,size=$BK_TMPFS" \
    moby/buildkit:buildx-stable-1
fi
docker buildx inspect fg-ram >/dev/null 2>&1 || \
  docker buildx create --name fg-ram --driver remote "docker-container://$BK"
for _ in $(seq 1 30); do docker buildx inspect --bootstrap fg-ram >/dev/null 2>&1 && break; sleep 2; done
docker buildx inspect fg-ram | grep -E "Status|Driver" || true
echo "RAM builder ready (cpus $BK_CPUS, mem $BK_MEM, tmpfs $BK_TMPFS)."

export BUILDX_BUILDER=fg-ram
DOCKER_IMAGE_TAG=familyguild docker compose build --builder fg-ram \
  --build-arg CTYPE=Release --build-arg CTOOLS_BUILD=db-only \
  ac-db-import ac-worldserver ac-authserver
docker tag acore/ac-wotlk-client-data:master acore/ac-wotlk-client-data:familyguild
echo "Done. Images tagged :familyguild are ready."
