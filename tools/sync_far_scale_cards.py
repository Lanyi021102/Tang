"""Copy the V3 web prototype's JSON payload into Godot's data format."""
import json
from pathlib import Path

root = Path(__file__).resolve().parents[1]
source = root / "prototypes/far-view-scale-cards-v3/cards-data.js"
text = source.read_text(encoding="utf-8-sig").strip()
prefix = "window.CHANGAN_SCALE_CARDS = "
if not text.startswith(prefix) or not text.endswith(";"):
    raise ValueError("Unexpected V3 data wrapper")
cards = json.loads(text[len(prefix):-1])
assert len({card["id"] for card in cards}) == len(cards)
assert all(card["type"] in ("Fang", "Road") for card in cards)
(root / "data/far_scale_cards.json").write_text(
    json.dumps({"cards": cards}, ensure_ascii=False, indent=2) + "\n",
    encoding="utf-8",
)
print(f"Synced {len(cards)} V3 cards")
