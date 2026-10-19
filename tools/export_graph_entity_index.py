"""Match the existing backend's convert_changan_generated.py UUID contract."""
import json
from pathlib import Path
from uuid import NAMESPACE_URL, uuid5

root = Path(__file__).resolve().parents[1]
entities = json.loads((root / "data/generated/entities.json").read_text(encoding="utf-8"))["entities"]
items = [{"key": e["key"], "id": str(uuid5(NAMESPACE_URL, f"tang-changan:entity:{e['key']}")),
          "name": e["name"], "type": e["type"], "aliases": e.get("aliases", [])}
         for e in entities]
(root / "data/graph_entity_index.json").write_text(
    json.dumps({"entities": items}, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
print(f"Indexed {len(items)} entities; no database changes")
