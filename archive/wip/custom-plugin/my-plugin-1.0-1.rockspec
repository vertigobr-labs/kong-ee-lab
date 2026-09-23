package = "my-plugin"
version = "1.0-1"
source = {
  url = "http://example.com/example-1.0.tar.gz"
}
description = {
    summary = "A minimal Kong plugin",
    detailed = [[
        A minimal Kong plugin that can be used to get started quickly.
    ]],
    license = "Apache 2.0"
}
dependencies = {
}
build = {
    type = "builtin",
    modules = {
        ["kong.plugins.my-plugin.handler"] = "src/handler.lua",
        ["kong.plugins.my-plugin.schema"] = "src/schema.lua",
    }
}
