// Saves a copy of the database to data/backups and keeps the newest seven.
import { DatabaseSync } from "node:sqlite";
import { existsSync, mkdirSync, readdirSync, rmSync } from "node:fs";
import { dirname, join } from "node:path";
const db = process.env.HEXBRAIN_DB || join(process.cwd(), "data", "hexbrain.db");
if (!existsSync(db)) { console.log("No database yet; nothing to back up."); process.exit(0); }
const dir = join(dirname(db), "backups"), file = join(dir, `hexbrain-${new Date().toISOString().slice(0, 10)}.db`);
mkdirSync(dir, { recursive: true });
rmSync(file, { force: true });
const d = new DatabaseSync(db); d.exec("PRAGMA busy_timeout = 20000;"); d.exec(`VACUUM INTO '${file.replace(/'/g, "''")}'`); d.close();
const old = readdirSync(dir).filter((f) => /^hexbrain-.*\.db$/.test(f)).sort().reverse().slice(7);
for (const f of old) rmSync(join(dir, f), { force: true });
console.log(`Backed up to ${file}; ${old.length} older copies removed.`);
