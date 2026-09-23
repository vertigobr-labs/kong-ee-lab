local typedefs = require "kong.db.schema.typedefs"

return {
  name = "my-plugin",  -- Replace with the name of your plugin
  fields = {
    {
      -- this plugin will only be applied to Services or Routes
      consumer = typedefs.no_consumer
    },
    {
      -- this plugin will only run within Nginx HTTP module
      protocols = typedefs.protocols_http
    },
    { 
      config = {
        type = "record",
        fields = {
          { 
            my_parameter = { 
              type = "string",
              required = true,
              default = "default_value",
            },
          },
          -- You can add more parameters here
        },
      },
    },
  },
}
