-- capture_body.lua: read the request body and forward it in X-Body for the /validate auth_request.
--
-- BU change (see the fork's BU-AGENTS.md). Upstream forwards the whole body. Behind linkerd that breaks
-- every large tool call: bodies over nginx's 16 KB buffer spill to disk and /validate refuses them
-- (413 -> 500); bodies of ~11-16 KB push the header block past the linkerd proxy's 16 KB HTTP/1 header
-- limit (431/500). Measured in ai-eks-nonprod 2026-09-18 on office-docs.
--
-- Bodies up to X_BODY_MAX behave as upstream. Larger ones send no X-Body and no X-Body-Uninspectable:
-- /validate still authenticates the caller and checks server access, and the tool-level scope check
-- runs at the auth-server's /mcp-proxy/ hop on the real forwarded body (_authorize_forwarded_mcp_body),
-- which upstream already runs for every request. Only X-Tool-Name (metrics and rate-limit attribution)
-- is lost for those calls.
--
-- Drop this change when upstream stops refusing uninspectable bodies at /validate. On each upstream
-- merge, diff against the new upstream file and re-run the size sweep.

local X_BODY_MAX = 8 * 1024  -- bytes; other headers use ~4 KB of linkerd's 16 KB header limit

-- Strip any client-supplied copies of the headers this script owns so a caller cannot forge the
-- scope-decision inputs the auth server trusts. (Unchanged from upstream.)
ngx.req.clear_header("X-Body")
ngx.req.clear_header("X-Body-Uninspectable")

ngx.req.read_body()
local body_data = ngx.req.get_body_data()

if body_data == nil then
    if ngx.req.get_body_file() then
        ngx.log(ngx.INFO, "Request body spilled to a temp file; not forwarded in X-Body, "
            .. "tool authorization deferred to the auth-server /mcp-proxy/ hop")
    else
        ngx.log(ngx.INFO, "No request body found")
    end
    return
end

local size = #body_data
if size > X_BODY_MAX then
    ngx.log(ngx.INFO, "Request body (" .. size .. " bytes) exceeds X_BODY_MAX (" .. X_BODY_MAX
        .. "); not forwarded in X-Body, tool authorization deferred to the auth-server /mcp-proxy/ hop")
    return
end

-- Strip newlines to keep the header well-formed (JSON whitespace is insignificant per RFC 8259).
local clean_body = body_data:gsub("[\r\n]+", " ")
ngx.req.set_header("X-Body", clean_body)
ngx.log(ngx.INFO, "Captured request body (" .. size .. " bytes) for auth validation")
