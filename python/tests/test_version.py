from sketchup_mcp_server.server import VERSION
from sketchup_mcp_server.version import __version__


def test_server_version_matches_package_version() -> None:
    assert VERSION == __version__
