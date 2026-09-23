local access = require "kong.plugins.kong-oidc-auth.access"

local KongOidcAuth = {
	VERSION  = "0.1.0",
	PRIORITY = 1049,
}

function KongOidcAuth:access(conf)
	access.run(conf)
end

return KongOidcAuth
