import importlib.util
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch
from types import SimpleNamespace

spec = importlib.util.spec_from_file_location('fetch_mirror', Path(__file__).parents[1] / 'scripts/fetch_mirror.py')
fetch = importlib.util.module_from_spec(spec)
spec.loader.exec_module(fetch)


class FetchTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.path = Path(self.temp.name) / 'page.html'
        self.env = patch.dict(fetch.os.environ, {'EXEC': 'https://example.test/exec', 'UA': 'test'})
        self.env.start()
        self.addCleanup(self.env.stop)

    def test_valid_wrapper_is_accepted(self):
        self.path.write_bytes(b'userHtml' + b'x' * 21000)
        with patch.object(fetch.subprocess, 'run', return_value=SimpleNamespace(returncode=0)) as run:
            fetch.fetch_page('page', '?p=home', self.path)
        self.assertEqual(run.call_count, 1)

    def test_large_error_page_is_not_published(self):
        self.path.write_bytes(b'x' * 21000)
        with patch.object(fetch.subprocess, 'run', return_value=SimpleNamespace(returncode=0)) as run, patch.object(fetch.time, 'sleep'):
            with self.assertRaises(RuntimeError):
                fetch.fetch_page('page', '?p=home', self.path)
        self.assertEqual(run.call_count, 3)

    def test_network_failure_does_not_accept_stale_file(self):
        self.path.write_bytes(b'userHtml' + b'x' * 21000)
        with patch.object(fetch.subprocess, 'run', return_value=SimpleNamespace(returncode=28)), patch.object(fetch.time, 'sleep'):
            with self.assertRaises(RuntimeError):
                fetch.fetch_page('page', '?p=home', self.path)

    def test_transient_failure_recovers(self):
        self.path.write_bytes(b'userHtml' + b'x' * 21000)
        with patch.object(fetch.subprocess, 'run', side_effect=[SimpleNamespace(returncode=28), SimpleNamespace(returncode=0)]), patch.object(fetch.time, 'sleep') as sleep:
            fetch.fetch_page('page', '?p=home', self.path)
        sleep.assert_called_once_with(20)
