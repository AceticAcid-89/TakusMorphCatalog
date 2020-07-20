# coding=utf-8

import configparser
import html
import json
import os
import re
import requests
import threading

from apscheduler.schedulers.background import BackgroundScheduler


class Spider(object):

    def __init__(self):
        spider_type = input().strip()
        parser = configparser.RawConfigParser()
        parser.read("config.ini")
        spider_dict = dict(parser.items(spider_type))
        for k, v in spider_dict.items():
            if v.isdigit():
                self.__setattr__(k, int(v))
            elif v in ["false", "FALSE", "False"]:
                self.__setattr__(k, False)
            elif v in ["true", "TRUE", "True"]:
                self.__setattr__(k, True)
            else:
                self.__setattr__(k, v)

        if not hasattr(self, "max_id"):
            self.source_data = json.load(open(self.source_file))
            self.max_id = len(self.source_data)

        # global lock
        self.valid_lock = threading.Lock()
        self.invalid_lock = threading.Lock()

        self.valid_dict = self.get_cur_ret_dict("valid")
        self.invalid_dict = self.get_cur_ret_dict("invalid")

    def get_cur_ret_dict(self, file_type):
        if file_type == "valid":
            file_path = self.valid_target
        else:
            file_path = self.invalid_target

        if os.path.exists(file_path):
            return json.load(open(file_path, encoding="utf-8"))
        else:
            with open(file_path, "w") as f:
                f.write(json.dumps({}))
            return {}

    def get_display_id(self, response):
        lines = response.splitlines()
        for line in lines:
            if "displayId" not in line:
                continue
            re_ret = re.findall(self.display_id_regex, line)
            if re_ret:
                return re_ret[0]
        else:
            return None

    def get_name(self, response):
        lines = response.splitlines()
        en_name, cn_name = "", ""
        for line in lines:
            if '<link rel="alternate" hreflang=' not in line:
                continue
            # print(line)
            for item in line.split(">"):
                # print(item)
                en_name_ret = re.findall(self.en_name_regex, item)
                if en_name_ret:
                    en_name = en_name_ret[0].replace("-", " ")
                cn_name_ret = re.findall(self.zh_name_regex, item)
                if cn_name_ret:
                    cn_name = cn_name_ret[0].replace("-", " ")
                if en_name and cn_name:
                    break
        return en_name, cn_name

    def get_response(self, catch_id):
        full_url = self.base_url % catch_id
        if self.debug:
            print(full_url)
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

    def update_global_dict(self, index):
        scope = (self.max_id - self.offset) // self.thread_num
        start = index * scope + self.offset
        end = (index + 1) * scope + self.offset
        for catch_id in range(start, end):
            if self.debug:
                print(catch_id)
            if hasattr(self, "source_data"):
                catch_id = self.source_data[catch_id]
            if str(catch_id) in self.valid_dict:
                if self.debug:
                    print("%s in %s, skip" % (catch_id, self.valid_target))
                continue
            if str(catch_id) in self.invalid_dict:
                if self.debug:
                    print("%s in %s, skip" % (catch_id, self.invalid_target))
                continue

            resp = self.get_response(catch_id)
            if resp is None:
                continue

            skip_str = "It may have been removed from the game."
            if skip_str in resp:
                self.set_data(catch_id, "invalid")
                continue

            display_id = self.get_display_id(resp)
            if display_id is None:
                self.set_data(catch_id, "invalid")
                continue
            en_name, cn_name = self.get_name(resp)
            # if self.debug:
            print("result", display_id, en_name, cn_name)

            print("success, catch_id %s" % catch_id)
            self.set_data(catch_id, "valid", display_id, (en_name, cn_name))

    def set_data(self, catch_id, dict_type,
                 display_id=None, names=(None, None)):
        en_name, cn_name = names
        if dict_type == "valid":
            with self.valid_lock:
                self.valid_dict.update({
                    catch_id: {
                        "display_id": display_id,
                        "en_name": en_name,
                        "cn_name": cn_name}
                })
        else:
            with self.invalid_lock:
                self.invalid_dict[catch_id] = {}

    def update_file_to_disk(self):
        with self.valid_lock:
            with open(self.valid_target, "w", encoding='utf-8') as f:
                f.write(json.dumps(
                    self.valid_dict, indent=4, ensure_ascii=False))
                print("update %s ends" % self.valid_target)

        with self.invalid_lock:
            with open(self.invalid_target, "w", encoding='utf-8') as f:
                f.write(json.dumps(
                    self.invalid_dict, indent=4, ensure_ascii=False))
                print("update %s ends" % self.invalid_target)

    def main(self):
        # non blocking timer every 10s to update file on disk
        scheduler = BackgroundScheduler()
        scheduler.add_job(self.update_file_to_disk, 'interval', seconds=10)
        scheduler.start()

        # request thread job
        for i in range(self.thread_num):
            t = threading.Thread(target=self.update_global_dict, args=(i,))
            t.start()


if __name__ == '__main__':
    job = Spider()
    job.main()
