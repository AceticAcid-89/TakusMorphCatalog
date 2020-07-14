from apscheduler.schedulers.background import BackgroundScheduler
from collections import defaultdict
import html
import json
import re
import requests
import threading


MAX_NPC_ID = 120000
THREAD_NUM = 20
BASE_URL = "https://wowhead.com/npc=%d"
DISPLAY_REGEX = re.compile(r'^onclick.+\"displayId\":(\d+)\}\)')
NPC_NAME_REGEX = re.compile(r'<meta.+content=\"(.+)\">')
NPC_ID_DISPLAY_ID_DICT = defaultdict(list)
JSON_FILE = "npc_id_display_id.json"
INVALID_JSON_FILE = "invalid_npc_id_display_id.json"

# global dict
npc_display_dict = json.load(open(JSON_FILE))
invalid_npc_dict = json.load(open(INVALID_JSON_FILE))

# global_lock
valid_lock = threading.Lock()
invalid_lock = threading.Lock()


def get_display_id(response):
    lines = response.split()
    for line in lines:
        if "displayId" not in line:
            continue
        return re.match(DISPLAY_REGEX, line).group(1)
    else:
        return None


def get_npc_name(response):
    lines = response.split("\n")
    for line in lines:
        if '<meta property="twitter:title" content=' not in line:
            continue
        return re.match(NPC_NAME_REGEX, line).group(1)
    else:
        return "UNKNOWN"


def get_response(npc_id):
    full_url = BASE_URL % npc_id
    try:
        data = requests.get(full_url)
    except ConnectionError:
        print(full_url, "ConnectionError")
        return None
    except requests.exceptions.ProxyError:
        print(full_url, "requests.exceptions.ProxyError")
        return None
    except Exception:
        print(full_url, "unknown Exception")
        return None

    return html.unescape(data.content.decode())


def update_global_dict(index, thread_num):
    global npc_display_dict
    global invalid_npc_dict
    scope = MAX_NPC_ID // thread_num
    for npc_id in range(index * scope, index * scope + scope):
        if str(npc_id) in npc_display_dict:
            continue
        if str(npc_id) in invalid_npc_dict:
            continue

        resp = get_response(npc_id)
        if resp is None:
            set_data(npc_id, None, None, "invalid")
            continue

        skip_str = "NPC #%d doesn't exist. It may have" \
                   " been removed from the game." % npc_id
        if skip_str in resp:
            set_data(npc_id, None, None, "invalid")
            continue

        display_id = get_display_id(resp)
        npc_name = get_npc_name(resp)

        if display_id is None:
            continue
        print("success, npc_id %s" % npc_id)
        set_data(npc_id, display_id, npc_name, "valid")


def set_data(npc_id, display_id, npc_name, dict_type):
    global npc_display_dict
    global invalid_npc_dict
    if dict_type == "valid":
        with valid_lock:
            npc_display_dict.update(
                {
                    npc_id: {
                        "display_id": display_id,
                        "npc_name": npc_name
                    }
                }
            )
    else:
        with invalid_lock:
            invalid_npc_dict[npc_id] = {}


def update_file_to_disk():
    global npc_display_dict
    global invalid_npc_dict

    with valid_lock:
        with open(JSON_FILE, "w") as f:
            f.write(json.dumps(npc_display_dict, indent=4))
            # print(npc_display_dict)
            print("update %s ends" % JSON_FILE)

    with invalid_lock:
        with open(INVALID_JSON_FILE, "w") as f:
            f.write(json.dumps(invalid_npc_dict, indent=4))
            # print(invalid_npc_dict)
            print("update %s ends" % INVALID_JSON_FILE)


def main():
    # non blocking timer every 10s to update file on disk
    scheduler = BackgroundScheduler()
    scheduler.add_job(update_file_to_disk, 'interval', seconds=10)
    scheduler.start()

    # request thread job
    for i in range(THREAD_NUM):
        t = threading.Thread(target=update_global_dict, args=(i, THREAD_NUM))
        t.start()


if __name__ == '__main__':
    main()
