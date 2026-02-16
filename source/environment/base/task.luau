local LuneTask: table = require("@lune/task")
local Manager: table = require("@env/manager")
local Task: table = Manager.create()

Task:define("cancel", function(Thread: thread): ()
  Task:checktype(1, Thread, "thread")
  
  return LuneTask.cancel(Thread)
end)

Task:define("defer", function(Callback: () -> ()): thread
  Task:checktype(1, Callback, "function")
  
  return LuneTask.defer(Callback)
end)

Task:define("delay", function(Delay: number, Callback: () -> ()): thread
  Task:checktype(1, Delay, "number")
  Task:checktype(2, Callback, "function")
  
  return LuneTask.delay(Delay, Callback)
end)

Task:define("desynchronize", function(): ()
  LuneTask.wait(Duration)
end)

Task:define("spawn", function(Callback: () -> ()): thread
  Task:checktype(1, Callback, "function")
  
  return LuneTask.spawn(Callback)
end)

Task:define("synchronize", function(): ()
  
end)

Task:define("wait", function(Duration: number?): number
  return LuneTask.wait(Duration)
end)

return Task:export() :: table