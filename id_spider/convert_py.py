# coding=utf-8

from collections import defaultdict
import json

NPC_JSON_FILE = "npc_id_display_id.json"
MOUNT_JSON_FILE = "mount_spell_id_display_id.json"

with open(NPC_JSON_FILE, encoding="utf-8") as f:
    data = json.load(f)

with open(MOUNT_JSON_FILE, encoding="utf-8") as f:
    data.update(json.load(f))

display_id_npc_id_dict = defaultdict(list)

for npc_id in data:
    display_id = data[npc_id]["display_id"]
    en_name = data[npc_id]["en_name"]
    cn_name = data[npc_id]["cn_name"]
    display_id_npc_id_dict[display_id].append(
        {"npc_id": npc_id, "en_name": en_name, "cn_name": cn_name}
    )

with open("display_id_npc_id.json", "w",  encoding="utf-8") as f:
    f.write(json.dumps(display_id_npc_id_dict, indent=4, ensure_ascii=False))

target_lua = "..\\display_%s.lua"

full_list = []

# t = {display = {{npc_id = 22, en_name = "xx", cn_name = "xx"}, {}}}

for display_id in display_id_npc_id_dict:
    display_list = []
    for item in display_id_npc_id_dict[display_id]:
        npc_id = item["npc_id"]
        en_name = item["en_name"]
        cn_name = item["cn_name"]

        display_list.append(
            '{npc_id = "%s", en_name = "%s", cn_name = "%s"}' %
            (npc_id, en_name, cn_name)
        )
    display_str = ", ".join(display_list)
    full_list.append(
        'display_id_%s = {%s}' % (display_id, display_str)
    )

full_content = "local _, ns = ...\nns.display_id_table_%s = {\n"

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
