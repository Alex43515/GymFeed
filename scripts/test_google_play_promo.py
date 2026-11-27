import copy
import unittest
from google_play_promo import BASE, END, offer_body, revised_subscription


class PromoTests(unittest.TestCase):
    def setUp(self):
        self.subscription = {'basePlans': [{
            'basePlanId': BASE, 'state': 'ACTIVE',
            'autoRenewingBasePlanType': {'billingPeriodDuration': 'P1M'},
            'regionalConfigs': [
                {'regionCode': 'US', 'newSubscriberAvailability': True, 'price': {'units': '10'}},
                {'regionCode': 'RS', 'newSubscriberAvailability': True, 'price': {'units': '1199'}},
                {'regionCode': 'DE', 'newSubscriberAvailability': False, 'price': {'currencyCode': 'EUR', 'units': '12'}},
            ],
        }, {'basePlanId': 'other', 'state': 'ACTIVE', 'regionalConfigs': []}]}

    def test_changes_only_authorized_prices(self):
        original = copy.deepcopy(self.subscription)
        updated = revised_subscription(self.subscription)
        self.assertEqual(self.subscription, original)
        self.assertEqual(updated['basePlans'][1], original['basePlans'][1])
        self.assertEqual(updated['basePlans'][0]['regionalConfigs'][2], original['basePlans'][0]['regionalConfigs'][2])
        self.assertEqual(updated['basePlans'][0]['regionalConfigs'][0]['price'], {'currencyCode': 'USD', 'units': '25'})
        self.assertEqual(updated['basePlans'][0]['regionalConfigs'][1]['price'], {'currencyCode': 'RSD', 'units': '1999'})

    def test_refuses_to_add_sales_regions(self):
        self.subscription['basePlans'][0]['regionalConfigs'][0]['newSubscriberAvailability'] = False
        with self.assertRaises(ValueError):
            revised_subscription(self.subscription)

    def test_offer_is_ten_percent_once_for_new_users_and_not_auto_selected(self):
        offer = offer_body('package')
        self.assertEqual(offer['endTime'], END)
        self.assertIn({'tag': 'rc-ignore-offer'}, offer['offerTags'])
        self.assertEqual(offer['targeting']['acquisitionRule']['scope'], {'anySubscriptionInApp': {}})
        phase, = offer['phases']
        self.assertEqual((phase['recurrenceCount'], phase['duration']), (1, 'P1M'))
        self.assertEqual({r['regionCode'] for r in phase['regionalConfigs']}, {'US', 'RS'})
        self.assertTrue(all(r['relativeDiscount'] == .1 for r in phase['regionalConfigs']))


if __name__ == '__main__':
    unittest.main()
