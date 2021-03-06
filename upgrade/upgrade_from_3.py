if __name__ == '__main__':
    print("The upgrade script has changed. You need to execute the upgrade command again to update the data structure.")
    exit(0)

import hashlib
import hmac
import json
import tarfile
import time
import uuid
import os

from common import file


def add_page_id(list_item):
    list_item["uuid"] = str(uuid.uuid5(uuid.NAMESPACE_URL, list_item["name"]))
    if "time" in list_item:
        list_item["time"] = round(list_item["time"])
    return list_item


def add_menu_id(list_item):
    if "name" in list_item:
        return add_page_id(list_item)
    return list_item


def add_tar_file(tar, dir_name):
    for root, path, files in os.walk(dir_name):
        for file_name in files:
            full_path = os.path.join(root, file_name)
            tar.add(full_path)

def main():
    if not os.path.exists("./backup"):
        os.mkdir("./backup")
    tar = tarfile.open("./backup/backup-version_2-{}.tar.gz".format(time.strftime("%Y%m%d%H%M%S", time.localtime())),
                       "w:gz")
    add_tar_file(tar, "./config")
    add_tar_file(tar, "./document")
    add_tar_file(tar, "./templates")
    add_tar_file(tar, "./static_file")
    tar.close()
    page_list = json.loads(file.read_file("./config/page.json"))
    page_list = list(map(add_page_id, page_list))
    menu_list = json.loads(file.read_file("./config/menu.json"))
    menu_list = list(map(add_menu_id, menu_list))

    file.write_file("./config/page.json", file.json_format_dump(page_list))
    file.write_file("./config/menu.json", file.json_format_dump(menu_list))

    system_config = json.loads(file.read_file("./config/system.json"))
    control_config = dict()
    try:
        old_password_hash = json.loads(system_config["API_Password"])["hash_password"]
        control_config["password"] = hmac.new(str("SiLvErBlOg").encode('utf-8'), str(old_password_hash).encode('utf-8'),
                                              hashlib.sha256).hexdigest()
    except (ValueError, KeyError, TypeError):
        pass


    del system_config["API_Password"]
    system_config["Pinyin"] = True
    system_config["Use_CDN"] = True
    system_config["Lazyload"] = False
    file.write_file("./config/system.json", file.json_format_dump(system_config))
    file.write_file("./config/control.json", file.json_format_dump(control_config))
    if os.path.exists("./upgrade/last_fetch_time.json"):
        os.remove("./upgrade/last_fetch_time.json")