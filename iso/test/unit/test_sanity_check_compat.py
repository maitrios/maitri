#!/usr/bin/python

"""The install must run on the archinstall the ISO was built with.

archinstall 4.4 takes `offline` on Installer.sanity_check and 4.5 removed it,
which aborted every install from a 4.5 ISO with a TypeError. The adapter passes
`offline` only where the installed signature has it.
"""

import sys
import unittest
from pathlib import Path
from unittest import mock

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "configs/airootfs/usr/share/maitri-iso"))

# The adapter imports the archinstall library at module scope; it only exists
# on the live ISO.
for name in (
    "archinstall",
    "archinstall.lib",
    "archinstall.lib.args",
    "archinstall.lib.authentication",
    "archinstall.lib.authentication.authentication_handler",
    "archinstall.lib.disk",
    "archinstall.lib.disk.filesystem",
    "archinstall.lib.disk.utils",
    "archinstall.lib.hardware",
    "archinstall.lib.installer",
    "archinstall.lib.mirror",
    "archinstall.lib.mirror.mirror_handler",
    "archinstall.lib.models",
    "archinstall.lib.models.device",
    "archinstall.lib.models.users",
):
    sys.modules.setdefault(name, mock.MagicMock())

# Other suites register an empty stand-in for the adapter; this one needs the real module.
sys.modules.pop("orchestrator.archinstall_adapter", None)
from orchestrator import archinstall_adapter  # noqa: E402


class SanityCheckCompat(unittest.TestCase):
    def test_archinstall_44_gets_offline(self):
        calls = []

        class Installer44:
            def sanity_check(self, offline=False, skip_ntp=False, skip_wkd=False):
                calls.append((offline, skip_ntp, skip_wkd))

        archinstall_adapter.sanity_check(Installer44(), skip_ntp=True, skip_wkd=True)
        self.assertEqual(calls, [(True, True, True)])

    def test_archinstall_45_is_not_passed_offline(self):
        calls = []

        class Installer45:
            def sanity_check(self, skip_ntp=False, skip_wkd=False):
                calls.append((skip_ntp, skip_wkd))

        archinstall_adapter.sanity_check(Installer45(), skip_ntp=True, skip_wkd=True)
        self.assertEqual(calls, [(True, True)])


if __name__ == "__main__":
    unittest.main()
