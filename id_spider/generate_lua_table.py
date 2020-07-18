import os
import json

JSON_FILE = "npc_id_display_id.json"
target_lua = "..\\npc_%s.lua"

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

full_content = "local _, ns = ...\nns.npc_id_table_%s = {\n"

# for wow interface constants memory limit, split to 3 tables
parts = 3
nums = len(full_list) // parts
for i in range(0, parts):
    if i == parts - 1:
        part_list = full_list[i * nums: (i + 2) * nums]
    else:
        part_list = full_list[i * nums: (i + 1) * nums]
    file_name = target_lua % i
    prefix = full_content % i
    with open(file_name, "w") as f:
        f.write(prefix + ",\n".join(part_list) + "}")
