"""Minimal WDBC (WoW 3.3.5a) reader/writer. Records are lists of uint32."""
import struct

class DBC:
    def __init__(self, fields, records, strings):
        self.fields, self.records, self.strings = fields, records, bytearray(strings)

    @classmethod
    def load(cls, path):
        data = open(path, "rb").read()
        magic, n, f, size, ssize = struct.unpack_from("<4s4I", data)
        if magic != b"WDBC" or size != f * 4:
            raise ValueError("not a WDBC file with uint32 fields")
        recs, off = [], 20
        for _ in range(n):
            recs.append(list(struct.unpack_from(f"<{f}I", data, off))); off += size
        return cls(f, recs, data[off:off + ssize])

    def save(self, path):
        with open(path, "wb") as fh:
            fh.write(struct.pack("<4s4I", b"WDBC", len(self.records), self.fields,
                                 self.fields * 4, len(self.strings)))
            for r in self.records:
                fh.write(struct.pack(f"<{self.fields}I", *r))
            fh.write(bytes(self.strings))

    def get_string(self, off):
        end = self.strings.index(0, off)
        return self.strings[off:end].decode("utf-8")

    def add_string(self, s):
        if not s:
            return 0
        off = len(self.strings)
        self.strings += s.encode("utf-8") + b"\0"
        return off

    def find(self, rid):
        return next((r for r in self.records if r[0] == rid), None)
