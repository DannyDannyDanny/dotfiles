# Gmail MCP server for Hara.
#
# Path 1 implementation: IMAP for read/sort, SMTP for reply.
# Slated for replacement by an OAuth2 + Gmail API + Calendar API server later.
{ python3Packages }:

python3Packages.buildPythonApplication {
  pname = "hara-gmail-mcp";
  version = "0.1.0";
  pyproject = true;
  src = ./.;
  nativeBuildInputs = [ python3Packages.setuptools ];
  propagatedBuildInputs = [ python3Packages.mcp ];

  # The server is launched via stdio by Claude Code; no tests yet.
  doCheck = false;

  meta = {
    description = "Gmail MCP server for Hara (IMAP+SMTP, throwaway pre-OAuth2)";
    mainProgram = "hara-gmail-mcp";
  };
}
