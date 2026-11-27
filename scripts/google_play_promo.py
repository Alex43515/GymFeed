"""Inspect or configure the real RevenueCat monthly product; never log credentials."""
import argparse
import copy
import json
from pathlib import Path

from google_play_release import API_ROOT, _json, _session

PRODUCT = 'subscription_1_month'
BASE = 'subscription-1month'
OFFER = 'gymfeedstart'
END = '2027-01-15T08:00:00Z'
PRICES = {'US': {'currencyCode': 'USD', 'units': '25'},
          'RS': {'currencyCode': 'RSD', 'units': '1999'}}


def revised_subscription(subscription):
    result = copy.deepcopy(subscription)
    base = next(p for p in result['basePlans'] if p['basePlanId'] == BASE)
    if base.get('state') != 'ACTIVE' or base.get('autoRenewingBasePlanType', {}).get('billingPeriodDuration') != 'P1M':
        raise ValueError('Expected an active, auto-renewing monthly base plan')
    regions = {r['regionCode']: r for r in base['regionalConfigs']}
    for region, price in PRICES.items():
        if region not in regions or not regions[region].get('newSubscriberAvailability'):
            raise ValueError(f'{region} is not available: refusing to change availability')
        regions[region]['price'] = price.copy()
    return result


def offer_body(package):
    return {
        'packageName': package, 'productId': PRODUCT, 'basePlanId': BASE,
        'offerId': OFFER, 'endTime': END,
        'targeting': {'acquisitionRule': {'scope': {'anySubscriptionInApp': {}}}},
        'offerTags': [{'tag': 'rc-ignore-offer'}, {'tag': OFFER}],
        'regionalConfigs': [{'regionCode': r, 'newSubscriberAvailability': True} for r in PRICES],
        'otherRegionsConfig': {'otherRegionsNewSubscriberAvailability': False},
        'phases': [{'duration': 'P1M', 'recurrenceCount': 1,
                    'regionalConfigs': [{'regionCode': r, 'relativeDiscount': 0.1} for r in PRICES]}],
    }


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--credentials', type=Path, required=True)
    parser.add_argument('--package', required=True)
    parser.add_argument('--apply', action='store_true')
    args = parser.parse_args()
    session = _session(args.credentials)
    url = f'{API_ROOT}/applications/{args.package}/subscriptions/{PRODUCT}'
    offers_url = f'{url}/basePlans/{BASE}/offers'
    current = _json(session.get(url, timeout=60), 'read monthly product')
    base = next(p for p in current['basePlans'] if p['basePlanId'] == BASE)
    print(json.dumps({'product': PRODUCT, 'base': BASE, 'state': base.get('state'),
                      'regions': [r for r in base['regionalConfigs'] if r['regionCode'] in PRICES]}))
    offers = _json(session.get(offers_url, timeout=60), 'read offers').get('subscriptionOffers', [])
    print(json.dumps({'existingOffers': offers}))
    if not args.apply:
        return
    updated = revised_subscription(current)
    converted = _json(session.post(f'{API_ROOT}/applications/{args.package}/pricing:convertRegionPrices',
                                  json={'price': PRICES['US']}, timeout=60), 'read regions version')
    version = converted['regionVersion']['version']
    _json(session.patch(url, params={'updateMask': 'basePlans', 'regionsVersion.version': version},
                        json={'packageName': args.package, 'productId': PRODUCT, 'basePlans': updated['basePlans']},
                        timeout=60), 'update US and Serbia prices')
    desired = offer_body(args.package)
    existing = next((o for o in offers if o['offerId'] == OFFER), None)
    if existing:
        _json(session.patch(f'{offers_url}/{OFFER}',
                            params={'updateMask': 'phases,targeting,offerTags,regionalConfigs,otherRegionsConfig,endTime',
                                    'regionsVersion.version': version}, json=desired, timeout=60), 'update offer')
    else:
        _json(session.post(offers_url, params={'offerId': OFFER, 'regionsVersion.version': version},
                           json=desired, timeout=60), 'create offer')
    if not existing or existing.get('state') != 'ACTIVE':
        _json(session.post(f'{offers_url}/{OFFER}:activate', json={}, timeout=60), 'activate offer')
    actual = _json(session.get(f'{offers_url}/{OFFER}', timeout=60), 'verify offer')
    actual_prices = _json(session.get(url, timeout=60), 'verify prices')
    verified = next(p for p in actual_prices['basePlans'] if p['basePlanId'] == BASE)
    for region, expected in PRICES.items():
        price = next(r['price'] for r in verified['regionalConfigs'] if r['regionCode'] == region)
        assert price['currencyCode'] == expected['currencyCode'] and price['units'] == expected['units'] and not price.get('nanos')
    assert actual['state'] == 'ACTIVE' and actual['endTime'] == END
    phase, = actual['phases']
    assert phase['duration'] == 'P1M' and phase['recurrenceCount'] == 1
    assert all(r['relativeDiscount'] == 0.1 for r in phase['regionalConfigs'])
    print(json.dumps({'verified': True, 'offer': actual, 'prices': PRICES}))


if __name__ == '__main__':
    main()
