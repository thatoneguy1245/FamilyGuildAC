# Custom patch pipeline (Phase 1: Flare)

Builds the client patch and matching server SQL from `custom/spells.yaml`.

1. Install mpqcli v0.13.0 (MIT) into `patch-pipeline/tools/mpqcli` (git-ignored).
2. Extract Spell.dbc from your own 3.3.5a client (never commit it):
   `mpqcli extract -o ~/fg-extract "Data/enUS/patch-enUS-3.MPQ" "DBFilesClient\Spell.dbc"`
   (if missing there, try patch-enUS-2.MPQ, then locale-enUS.MPQ; highest patch wins).
3. `./build_patch.sh --spell-dbc ~/fg-extract/DBFilesClient/Spell.dbc`
   -> `build/Patch-A.MPQ` (copy to client `Data/`) and `sql/custom/spell_dbc_flare.sql`.
4. Tests (synthetic DBC, no Blizzard data): `python3 -m unittest discover -s tests`

The generated SQL is only committed after it is built from a real Spell.dbc and reviewed.
Field offsets assume Spell.dbc 3.3.5a (234 fields); verify the spell_dbc column order before applying.
