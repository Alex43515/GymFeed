#!/usr/bin/env python3
"""Inspect or enable HealthKit on GymFeed's existing Apple bundle ID.

Uses the existing App Store Connect key. Never logs keys or JWTs, changes
certificates/profiles, registers another bundle ID, or publishes an app.
Requires PyJWT with its cryptography dependency.
"""
import argparse
import json
import time
from urllib.error import HTTPError
from urllib.parse import urlencode
from urllib.request import Request, urlopen

import jwt


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--key-file', required=True)
    parser.add_argument('--key-id', required=True)
    parser.add_argument('--issuer-id', required=True)
    parser.add_argument('--enable', action='store_true')
    args = parser.parse_args()
    with open(args.key_file, encoding='utf-8') as key_file:
        key = key_file.read()
    now = int(time.time())
    token = jwt.encode({'iss': args.issuer_id, 'iat': now, 'exp': now + 300,
                        'aud': 'appstoreconnect-v1'}, key, algorithm='ES256',
                       headers={'kid': args.key_id})

    def request(path, body=None):
        req = Request('https://api.appstoreconnect.apple.com/v1' + path,
                      data=json.dumps(body).encode() if body else None,
                      headers={'Authorization': 'Bearer ' + token,
                               'Content-Type': 'application/json'},
                      method='POST' if body else 'GET')
        try:
            with urlopen(req, timeout=30) as response:
                return json.load(response)
        except HTTPError as error:
            raise RuntimeError('Apple API error ' + str(error.code) + ': ' +
                               error.read().decode()[:1500]) from None

    bundle_ids = request('/bundleIds?' + urlencode({
        'filter[identifier]': 'com.flutterflow.gymfeedofficial'}))['data']
    if len(bundle_ids) != 1:
        raise RuntimeError('Expected exactly one existing GymFeed bundle ID')
    bundle_id = bundle_ids[0]['id']
    path = '/bundleIds/' + bundle_id + '/bundleIdCapabilities?limit=200'
    capabilities = request(path)['data']
    enabled = any(c['attributes']['capabilityType'] == 'HEALTHKIT' for c in capabilities)
    print(json.dumps({'bundleId': 'com.flutterflow.gymfeedofficial',
                      'healthKitEnabled': enabled}))
    if args.enable and not enabled:
        request('/bundleIdCapabilities', {'data': {
            'type': 'bundleIdCapabilities',
            'attributes': {'capabilityType': 'HEALTHKIT'},
            'relationships': {'bundleId': {'data': {'type': 'bundleIds', 'id': bundle_id}}}}})
        enabled = any(c['attributes']['capabilityType'] == 'HEALTHKIT'
                      for c in request(path)['data'])
        if not enabled:
            raise RuntimeError('HealthKit did not appear after enabling it')
        print(json.dumps({'healthKitEnabled': True, 'changed': True}))


if __name__ == '__main__':
    main()
