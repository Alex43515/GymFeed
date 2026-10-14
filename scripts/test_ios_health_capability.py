"""Read-only fixtures for the exact existing Apple App ID lookup."""
import unittest
from ios_health_capability import find_existing_bundle


IDENTIFIER = 'com.flutterflow.gymfeedofficial'


def bundle(identifier=IDENTIFIER, resource_id='existing'):
    return {'id': resource_id, 'attributes': {'identifier': identifier}}


class BundleLookupTest(unittest.TestCase):
    def test_exact_filtered_match(self):
        self.assertEqual(find_existing_bundle(
            lambda path: {'data': [bundle()]}, IDENTIFIER), 'existing')

    def test_empty_filter_falls_back_to_list(self):
        def request(path):
            return {'data': [] if 'filter' in path else [
                bundle(IDENTIFIER + '.ImageNotification', 'extension'), bundle()]}
        self.assertEqual(find_existing_bundle(request, IDENTIFIER), 'existing')

    def test_list_pagination(self):
        calls = []
        def request(path):
            calls.append(path)
            if 'filter' in path:
                return {'data': []}
            if 'cursor' in path:
                return {'data': [bundle()]}
            return {'data': [], 'links': {'next':
                'https://api.appstoreconnect.apple.com/v1/bundleIds?cursor=next'}}
        self.assertEqual(find_existing_bundle(request, IDENTIFIER), 'existing')
        self.assertEqual(len(calls), 3)

    def test_missing_or_ambiguous_ids_fail_closed(self):
        for data in ([], [bundle(), bundle(resource_id='duplicate')]):
            with self.subTest(data=data), self.assertRaises(RuntimeError):
                find_existing_bundle(lambda path: {'data': data}, IDENTIFIER)

    def test_untrusted_pagination_is_not_requested(self):
        calls = []
        def request(path):
            calls.append(path)
            return {'data': [], 'links': {'next': 'https://example.com/steal'}}
        with self.assertRaises(RuntimeError):
            find_existing_bundle(request, IDENTIFIER)
        self.assertEqual(len(calls), 2)


if __name__ == '__main__':
    unittest.main()
