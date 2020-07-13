from collections import defaultdict
import html
import re
import requests
import json
import threading


MAX_NPC_ID = 120000
BASE_URL = "https://classic.wowhead.com/npc=%d"
DISPLAY_REGEX = re.compile(r'^onclick.+\"displayId\":(\d+)\}\)')
NPC_NAME_REGEX = re.compile(r'\<meta.+content=\"(.+)\"\>')
NPC_ID_DISPLAY_ID_DICT = defaultdict(list)
JSON_FILE = "npc_id_display_id.json"

update_lock = threading.Lock()


def get_display_id(response):
    xx = html.unescape(response.decode()).split()
    for x in xx:
        if "displayId" not in x:
            continue
        return re.match(DISPLAY_REGEX, html.unescape(x)).group(1)
    else:
        return None


def get_npc_name(response):
    xx = html.unescape(response.decode()).split("\n")
    for x in xx:
        if '<meta property="twitter:title" content=' not in x:
            continue
        return re.match(NPC_NAME_REGEX, html.unescape(x)).group(1)
    else:
        return "UNKNOWN"


def get_response(npc_id):
    full_url = BASE_URL % npc_id
    print(full_url)
    try:
        data = requests.get(full_url)
    except ConnectionError:
        return None
    except requests.exceptions.ProxyError:
        return None
    skip_str = "NPC #%d doesn't exist. It may have" \
               " been removed from the game." % npc_id
    if skip_str in data:
        return None
    return data.content


def update_ret_file(index, thread_num):
    global update_lock
    scope = MAX_NPC_ID // thread_num
    for k in range(index * scope, index * scope + scope):
        exist_data = get_data()
        if k in exist_data:
            continue

        resp = get_response(k)
        if resp is None:
            continue

        display_id = get_display_id(resp)
        npc_name = get_npc_name(resp)

        if display_id is None:
            continue
        set_data(k, display_id, npc_name)


def get_data():
    global update_lock
    with update_lock:
        with open(JSON_FILE) as f:
            return json.load(f)


def set_data(npc_id, display_id, npc_name):
    global update_lock
    with update_lock:
        with open(JSON_FILE, "r") as f:
            data = json.load(f)
        with open(JSON_FILE, "w") as f:
            data.update(
                {
                    npc_id: {
                        "display_id": display_id,
                        "npc_name": npc_name
                    }
                }
            )
            f.write(json.dumps(data, indent=4))


def main():
    thread_num = 100
    for i in range(thread_num):
        t = threading.Thread(target=update_ret_file, args=(i, thread_num))
        t.start()


if __name__ == '__main__':
    main()
