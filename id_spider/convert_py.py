from collections import defaultdict
import json

display_id_npc_id_dict = defaultdict(list)

with open("npc_id_display_id.json") as f:
    data = json.load(f)
    for npc_id in data:
        display_id = data[npc_id]["display_id"]
        npc_name = data[npc_id]["npc_name"]
        display_id_npc_id_dict[display_id].append(
            {"npc_id": npc_id, "npc_name": npc_name}
        )

with open("display_id_npc_id.json", "w") as f:
    f.write(json.dumps(display_id_npc_id_dict, indent=4))
