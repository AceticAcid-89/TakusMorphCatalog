# coding=utf-8

import json

NPC_JSON_FILE = "npc_id_display_id.json"
MOUNT_JSON_FILE = "mount_spell_id_display_id.json"
target_lua = "..\\database\\npc_%s.lua"

with open(NPC_JSON_FILE, encoding="utf-8") as f:
    data = json.load(f)

with open(MOUNT_JSON_FILE, encoding="utf-8") as f:
    data.update(json.load(f))


full_list = []

for npc_id in data:
    display_id = data[npc_id]["display_id"]
    en_name = data[npc_id]["en_name"]
    if '"' in en_name:
        en_name = en_name.replace('"', '')
    cn_name = data[npc_id]["cn_name"]
    if '"' in cn_name:
        cn_name = cn_name.replace('"', '')
    npc_str = '    npc_id_%s = {display_id = "%s",' \
              ' en_name = "%s", cn_name = "%s"}' % \
              (npc_id, display_id, en_name, cn_name)
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
    with open(file_name, "w", encoding="utf-8") as f:
        f.write(prefix + ",\n".join(part_list) + "}")
