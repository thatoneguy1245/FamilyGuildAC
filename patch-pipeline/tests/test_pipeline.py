"""Runs the pipeline on a synthetic 234-field Spell.dbc (no Blizzard data)."""
import os, shutil, subprocess, sys, tempfile, unittest
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))
import build_patch as bp
from wdbc import DBC

def synthetic(path, ids=(133, 116)):
    d = DBC(bp.SPELL_FIELDS, [], b"\0")
    for i in ids:
        r = [0] * bp.SPELL_FIELDS; r[0] = i
        r[bp.F_NAME] = d.add_string("Fireball" if i == 133 else "Frostbolt")
        r[bp.F_BASEPTS] = 13; r[bp.F_DIESIDES] = 9; r[71] = 2  # SCHOOL_DAMAGE
        d.records.append(r)
    d.save(path)

class T(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.mkdtemp(); self.src = os.path.join(self.tmp, "Spell.dbc")
        synthetic(self.src); self.sql = os.path.join(self.tmp, "flare.sql")
    def tearDown(self): shutil.rmtree(self.tmp)

    def run_build(self, *extra):
        bp.main(["--spell-dbc", self.src, "--out", os.path.join(self.tmp, "b"), "--sql-out", self.sql, *extra])

    def test_flare_added_and_source_untouched(self):
        before = open(self.src, "rb").read()
        self.run_build("--no-mpq")
        self.assertEqual(before, open(self.src, "rb").read())
        d = DBC.load(os.path.join(self.tmp, "b", "stage", "DBFilesClient", "Spell.dbc"))
        f, fb = d.find(90001), d.find(133)
        self.assertEqual(d.get_string(f[bp.F_NAME]), "Flare")
        self.assertEqual((f[bp.F_BASEPTS], f[bp.F_DIESIDES]), (19, 9))
        self.assertEqual(f[71], fb[71])  # effect cloned from Fireball
        self.assertEqual(fb[bp.F_BASEPTS], 13)
        sql = open(self.sql).read()
        self.assertIn("'Flare'", sql); self.assertEqual(sql.count("INSERT"), 1)
        ins = [l for l in sql.splitlines() if l.startswith("INSERT")][0]
        import re; self.assertEqual(re.sub(r"'(?:[^']|'')*'", "S", ins).count(",") + 1, bp.SPELL_FIELDS)

    def test_rejects_used_id(self):
        synthetic(self.src, ids=(133, 90001))
        with self.assertRaises(SystemExit): self.run_build("--no-mpq")

    @unittest.skipUnless(os.path.exists(bp.os.path.join(bp.HERE, "tools", "mpqcli")) or shutil.which("mpqcli"), "mpqcli missing")
    def test_mpq_contains_spell_dbc(self):
        self.run_build()
        mpq = os.path.join(self.tmp, "b", "Patch-A.MPQ")
        cli = shutil.which("mpqcli") or os.path.join(bp.HERE, "tools", "mpqcli")
        out = subprocess.run([cli, "list", mpq], capture_output=True, text=True, check=True).stdout
        self.assertIn("DBFilesClient\\Spell.dbc", out.replace("/", "\\"))

if __name__ == "__main__": unittest.main()
