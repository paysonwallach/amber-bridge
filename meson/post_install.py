#!/usr/bin/env python3

import fileinput
import os
import shutil
import subprocess
import sys

EXECUTABLE_INSTALL_DIR = os.path.join(
    os.environ.get("DESTDIR", ""), os.environ["MESON_INSTALL_PREFIX"], "bin"
)
EXECUTABLE_NAME = "com.paysonwallach.amber.bridge"
MANIFEST_FILE_NAME = "com.paysonwallach.amber.bridge.json"

is_root = subprocess.run(["whoami"], capture_output=True) == "root"
kernel_name = subprocess.run(["uname", "-s"], capture_output=True)


def install_dir_for_target(target: str) -> str:
    if kernel_name == "Darwin":
        if is_root:
            return {
                "chrome": "/Library/Google/Chrome/NativeMessagingHosts",
                "chromium": "/Library/Application Support/Chromium/NativeMessagingHosts",
                "firefox": "/Library/Application Support/Mozilla/NativeMessagingHosts",
                "vivaldi": "/Library/Application Support/Vivaldi/NativeMessagingHosts",
            }.get(target, None)
        else:
            return {
                "chrome": os.path.join(
                    os.environ["HOME"],
                    "Library/Application Support/Google/Chrome/NativeMessagingHosts",
                ),
                "chromium": os.path.join(
                    os.environ["HOME"],
                    "Library/Application Support/Chromium/NativeMessagingHosts",
                ),
                "firefox": os.path.join(
                    os.environ["HOME"],
                    "Library/Application Support/Mozilla/NativeMessagingHosts",
                ),
                "vivaldi": os.path.join(
                    os.environ["HOME"],
                    "Library/Application Support/Vivaldi/NativeMessagingHosts",
                ),
            }.get(target, None)
    else:
        if is_root:
            return {
                "chrome": "/etc/opt/chrome/native-messaging-hosts",
                "chromium": "/etc/chromium/native-messaging-hosts",
                "firefox": "/usr/lib/mozilla/native-messaging-hosts",
                "vivaldi": "/etc/vivaldi/native-messaging-hosts",
            }.get(target, None)
        else:
            return {
                "chrome": os.path.join(
                    os.environ["HOME"],
                    ".config/google-chrome/NativeMessagingHosts",
                ),
                "chromium": os.path.join(
                    os.environ["HOME"],
                    ".config/chromium/NativeMessagingHosts",
                ),
                "firefox": os.path.join(
                    os.environ["HOME"],
                    ".mozilla/native-messaging-hosts",
                ),
                "vivaldi": os.path.join(
                    os.environ["HOME"],
                    ".config/vivaldi/NativeMessagingHosts",
                ),
            }.get(target, None)


target_dirs = map(install_dir_for_target, sys.argv[1:])

for target_dir in target_dirs:
    shutil.copyfile(
        os.path.join(
            os.environ["MESON_SOURCE_ROOT"], "data", MANIFEST_FILE_NAME
        ),
        os.path.join(target_dir, MANIFEST_FILE_NAME),
    )

    with fileinput.FileInput(
        os.path.join(target_dir, MANIFEST_FILE_NAME), inplace=True
    ) as file:
        for line in file:
            print(
                line.replace(
                    "@EXECUTABLE_PATH@",
                    os.path.join(EXECUTABLE_INSTALL_DIR, EXECUTABLE_NAME),
                ),
                end="",
            )
