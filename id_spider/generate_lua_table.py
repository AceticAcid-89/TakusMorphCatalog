import os
import json

JSON_FILE = "npc_id_display_id.json"
target_lua = "..\\npc.lua"

with open(JSON_FILE) as f:
    data = json.load(f)

full_list = []

for npc_id in data:
    display_id = data[npc_id]["display_id"]
    npc_name = data[npc_id]["npc_name"]
    if '"' in npc_name:
        npc_name = npc_name.replace('"', '')
    npc_str = '    npc_id_%s = {display_id = "%s", name = "%s"}' % \
              (npc_id, display_id, npc_name)
    full_list.append(npc_str)

full_content = "local _, ns = ...\nns.npc_id_table = {\n"

with open(target_lua, "w") as f:
    f.write(full_content + ",\n".join(full_list) + "}")
