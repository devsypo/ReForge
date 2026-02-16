local Serde: table = require("@lune/serde")
local TypeMessage: string = "invalid argument #%d to '%s' (%s expected, got %s)"

return {
  JSONDecode = {
    Handler = function(self, Body: string): table
      assert(type(Body) == "string", TypeMessage:format(1, "HttpService.JSONDecode", "string", type(Body)))
      
      local Status: boolean, Json: table = pcall(Serde.decode, "json", Body)
      assert(Status, TypeMessage:format(1, "HttpService.JSONDecode", "valid json", "invalid json"))
      
      return Json :: table
    end,
    Kind = "Method"
  },
  JSONEncode = {
    Handler = function(self, Body: table): string
      assert(type(Body) == "table", TypeMessage:format(1, "HttpService.JSONEncode", "table", type(Body)))
      
      local Status: boolean, Json: string = pcall(Serde.encode, "json", Body)
      assert(Status, TypeMessage:format(1, "HttpService.JSONEncode", "valid json", "invalid json"))
      
      return Json :: string
    end,
    Kind = "Method"
  },
  GetUserAgent = {
    Handler = function() 
      return "ReForged"
    end,
    Kind = "Method"
  }
}