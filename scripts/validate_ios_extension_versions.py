#!/usr/bin/env python3
"""Validate compiled notification extension metadata before Simulator install."""
import plistlib
import sys
from pathlib import Path


def validate(parent, extension):
    for key in ('CFBundleIdentifier', 'CFBundleExecutable', 'CFBundleShortVersionString', 'CFBundleVersion'):
        for label, info in (('Runner', parent), ('ImageNotification', extension)):
            value = info.get(key)
            if not isinstance(value, str) or not value.strip() or '$(' in value:
                raise ValueError(f'{label} has an empty or unresolved {key}')
    for key in ('CFBundleShortVersionString', 'CFBundleVersion'):
        if parent[key] != extension[key]:
            raise ValueError(f'Notification extension {key} does not match Runner')
    if not extension['CFBundleIdentifier'].startswith(parent['CFBundleIdentifier'] + '.'):
        raise ValueError('Notification extension identifier is not a child of Runner')
    if extension.get('NSExtension', {}).get('NSExtensionPointIdentifier') != 'com.apple.usernotifications.service':
        raise ValueError('Notification service extension point is missing')


def main():
    app = Path(sys.argv[1])
    with (app / 'Info.plist').open('rb') as stream:
        parent = plistlib.load(stream)
    with (app / 'PlugIns/ImageNotification.appex/Info.plist').open('rb') as stream:
        extension = plistlib.load(stream)
    validate(parent, extension)
    print(f"Validated Runner and notification extension {parent['CFBundleShortVersionString']} ({parent['CFBundleVersion']})")


if __name__ == '__main__':
    main()
