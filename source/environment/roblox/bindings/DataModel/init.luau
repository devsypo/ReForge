return {
  CreatorId = {
    Get = function()
      print("hi")
      -- Me too me optional
    end,
    Set = function()
      -- Set is optional!
    end,
    --Security = { Set = "None", Get = "None" }, > this too!
    Kind = "Property"
  },
  ExampleFunction = {
    Handler = function()
      
    end,
    Security = "None",
    Kind = "Method"
  },
  ExampleEvent = {
    Handler = {
      Connect = function() end
    },
    Security = "None",
    Kind = "Event"
  }
}