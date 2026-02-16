local Parser: table = require("@std/syntax/parser")
local FileSystem: table = require("@lute/fs")
local Process = require("@lute/process")
local Library: table = {
  Func = {
    Stack = {},
    Id = 0,
    WhileId = 0
  }
}

function Library:GetUpvalueIndex(name: string): number
  local Frame = self.Func.Stack[#self.Func.Stack]
  if not Frame then return 0 end

  for i, v in ipairs(Frame.Upvalues) do
    if v == name then
      return i
    end
  end

  return 0
end

function Library:EnterFunc(): number
  self.Func.Id += 1

  local Frame = {
    Id = self.Func.Id,
    WhileId = 0,
    Upvalues = {}
  }

  table.insert(self.Func.Stack, Frame)
  return Frame.Id
end

function Library:LeaveFunc()
  return table.remove(self.Func.Stack)
end

function Library:CurrentFrame()
  return self.Func.Stack[#self.Func.Stack]
end

function Library:EnterFunc(): number
  self.Func.Id += 1

  local Frame = {
    Id = self.Func.Id,
    Upvalues = {}
  }

  table.insert(self.Func.Stack, Frame)
  return Frame.Id
end

function Library:LeaveFunc()
  return table.remove(self.Func.Stack)
end

local Arguments = Process.env
local InputPath = Arguments.InputPath
local OutputPath = Arguments.OutputPath

function Library:Construct(Statement: table): table
  if Statement.istoken then
    return {
      Class = "cons"
    }
  end
  
  local Kind = Statement.kind
  
  if Kind == "stat" then
    return {
      Class = "stat",
      Kind = Statement.tag
    }
  elseif Kind == "expr" then
    return {
      Class = "expr",
      Kind = Statement.tag
    }
  end
  
  return {
    Class = "other"
  }
end

function Library:Parameters(Body: table): string
  local Code: string = "("
  
  for i, Parameter in ipairs(Body.parameters) do
    Code ..= (i > 1 and ", " or "") .. Parameter.node.name.text
  end
  
  if Body.vararg then
    Code ..= (#Body.parameters == 0 and "" or ", ") .. "..."
  end
  
  return Code .. ")"
end

function Library:DetectDo(Block: table): boolean
  if Block.location then
    local line = Lines[Block.location.begin.line + 1] or ""
    local col = Block.location.begin.column
    
    return line:sub(col + 1):match("^%s*do") ~= nil
  end
  
  return false
end

function Library:Block(Block: table): string
  local HasDo: boolean = self:DetectDo(Block)
  local Output: table = table.create(#Block.statements)
  local Index: number = 1
  
  if HasDo then
    Output[1] = "do "
    Index += 1
  end
  
  for i, Statement in ipairs(Block.statements) do
    local StatementText = self:Statement(Statement)
    local ShouldAddSemicolon = true
    local Tag = Statement.tag
    
    if i == #Block.statements then
      ShouldAddSemicolon = false
    elseif Tag == "block" or Tag == "conditional" or Tag == "while" or Tag == "for" or Tag == "forin" or Tag == "repeat" or Tag == "function" or Tag == "localfunction" then
      ShouldAddSemicolon = false
    end
    
    if ShouldAddSemicolon then
      StatementText = StatementText .. ";"
    end
    
    Output[Index] = StatementText
    Index += 1
  end
  
  if HasDo then
    Output[Index] = " end"
  end
  
  return table.concat(Output, " ")
end

function Library:Expression(Expression: table): string
  local Info = self:Construct(Expression)
  local Tag = Expression.tag
  
  if Tag == "local" then
    local Name = Expression.token.text
    if Expression.upvalue then
      local Frame = self:CurrentFrame()
      if Frame and not table.find(Frame.Upvalues, Name) then
        table.insert(Frame.Upvalues, Name)
      end
    end
    
    return Name
  end
  
  if Tag == "global" then
    local Name = Expression.name.text
    
    return Name
  end
  
  if Tag == "binary" then
    return string.format("%s %s %s", self:Expression(Expression.lhsoperand), Expression.operator.text, self:Expression(Expression.rhsoperand))
  end
  
  if Tag == "unary" then
    return string.format("%s %s", Expression.operator.text, self:Expression(Expression.operand))
  end
  
  if Tag == "group" then
    return string.format("(%s)", self:Expression(Expression.expression))
  end
  
  if Tag == "call" then
    local Func: string = self:Expression(Expression.func)
    
    local Arguments = ""
    for i, Argument in Expression.arguments do
      Arguments ..= (i > 1 and ", " or "") .. self:Expression(Argument.node)
    end
    
    local Extra = Arguments ~= "" and (", " .. Arguments) or ""
    
    if Expression.func.tag == "group" then
      return string.format("CALL(%q, %s%s)", "anon", Func, Extra)
    end
    
    if Expression.self then
      return string.format("NAMECALL(%s, %q%s)", self:Expression(Expression.func.expression), Expression.func.index.text, Extra)
    else
      return string.format("CALL(%q, %s%s)", Func, Func, Extra)
    end
  end
  
  if Tag == "table" then
    local Code = "{"
    local Length = #Expression.entries
    
    for i, Entry in Expression.entries do
      local Key = Entry.key
      if Key then
        if Entry.value.tag == "reference" then
          Code = Code .. string.format("%s: %s%s", Key.text, self:Expression(Entry.value), (i ~= Length and ", " or ""))
          continue
        end
        Code = Code .. string.format("[%s]=", self:Expression(Key))
      end
      Code ..= self:Expression(Entry.value) .. (i ~= Length and ", " or "")
    end
    
    Code ..= "}"
    
    return Code
  end
  
  if Tag == "indexname" then
    local Table = self:Expression(Expression.expression)
    local Accessor = Expression.accessor.text
    local Index = Expression.index.text
    
    return string.format("%s%s%s", Table, Accessor, Index)
  end
  
  if Tag == "index" then
    local Table: string = self:Expression(Expression.expression)
    local Index: string = self:Expression(Expression.index)
    
    return string.format("%s[%s]", Table, Index)
  end
  
  if Tag == "function" then
    local ID = self:EnterFunc()
    
    local Parameters = self:Parameters(Expression.body)
    local Body = self:Block(Expression.body.body)
    
    local Frame = self:LeaveFunc()
    local Upvalues = "{" .. table.concat(Frame.Upvalues, ", ") .. "}"
    
    local Code: string = string.format("DEFINE(%q, %d, function%s %s end, %s)", "anon", ID, Parameters, Body, Upvalues)
    
    return Code
  end
  
  if Tag == "conditional" then
    local Code: string = string.format("if %s then %s ", self:Expression(Expression.condition), self:Expression(Expression.thenexpr, true))
    
    for _, elif in Expression.elseifs do
      Code ..= string.format("elseif %s then %s ", self:Expression(elif.condition), self:Expression(elif.thenexpr))
    end
    
    Code ..= string.format("else %s", self:Expression(Expression.elseexpr))
    
    return Code
  end
  
  if Tag == "cast" then
    return "", print("cast")
  end
  
  if Tag == "reference" then
    return Epression.name.text
  end
  
  if Info.Class == "cons" then
    if Tag == "number" then
      return Expression.text
    end
    
    if Tag == "string" then
      local Style = Expression.quotestyle
      if Style == "block" then
        local Equals = string.rep("=", Expression.blockdepth)
        return string.format("[%s[%s]%s]", Equals, Expression.text, Equals)
      else
        local Quote = (Style == "double" and '"') or (Style == "single" and "'")
        return string.format("%s%s%s", Quote, Expression.text, Quote)
      end
    end
    
    if Tag == "boolean" then
      return Expression.text
    end
    
    if Tag == "nil" then
      return "nil"
    end
    
    if Tag == "vararg" then
      return "..."
    end
    
    if Tag == "continue" then
      return "continue"
    end
    
    if Tag == "break" then
      return "break"
    end
    
    if Expression.istoken then
      return string.format('"%s"', Expression.text)
    end
  end
  
  error(Info.Class .. " " .. (Tag or ""))
end

function Library:Statement(Statement: table): string
  local Info = self:Construct(Statement)
  local Tag = Statement.tag
  
  if Info.Class == "cons" then
    return self:Expression(Statement)
  end
  
  assert(Info.Class == "stat", "Unparser.Statement: cannot pass " .. Info.Class .. " to a statement unparser!")
  
  if Tag == "local" then
    local Code: string = "local "
    
    for i, NameNode in ipairs(Statement.variables) do
      Code ..= NameNode.node.name.text
      if i < #Statement.variables then
        Code ..= ", "
      end
    end
    
    if #Statement.values == 0 then
      return Code
    end
    
    Code ..= " = "
    
    for i, ExpressionNode in ipairs(Statement.values) do
      Code ..= self:Expression(ExpressionNode.node)
      if i < #Statement.values then
        Code ..= ", "
      end
    end
    
    return Code
  end
  
  if Tag == "assign" then
    local Code: string = ""
    
    for i, NameNode in ipairs(Statement.variables) do
      Code ..= self:Expression(NameNode.node)
      if i < #Statement.variables then
        Code ..= ", "
      end
    end
    
    if #Statement.values == 0 then
      return Code
    end
    
    Code ..= " = "
    
    for i, ExpressionNode in ipairs(Statement.values) do
      Code ..= self:Expression(ExpressionNode.node)
      if i < #Statement.values then
        Code ..= ", "
      end
    end
    
    return Code
  end
  
  if Tag == "compoundassign" then
    return string.format("%s %s %s", self:Expression(Statement.variable), Statement.operand.text, self:Expression(Statement.value))
  end
  
  if Tag == "expression" then
    return self:Expression(Statement.expression)
  end
  
  if Tag == "function" then
    local ID = self:EnterFunc()
    
    local Name = self:Expression(Statement.name)
    local Parameters = self:Parameters(Statement.body)
    local Body = self:Block(Statement.body.body)
    
    local Frame = self:LeaveFunc()
    local Upvalues = "{" .. table.concat(Frame.Upvalues, ", ") .. "}"
    
    local Code: string = string.format("%s = nil; %s = DEFINE(%q, %d, function%s %s end, %s)", Name, Name, Name, ID, Parameters, Body, Upvalues)
    
    return Code
  end
  
  if Tag == "block" then
    return self:Block(Statement)
  end
  
  if Tag == "localfunction" then
    local ID = self:EnterFunc()
    
    local Name = Statement.name.name.text
    local Parameters = self:Parameters(Statement.body)
    local Body = self:Block(Statement.body.body)
    
    local Frame = self:LeaveFunc()
    local Upvalues = "{" .. table.concat(Frame.Upvalues, ", ") .. "}"
    
    local Code: string = string.format("local %s; %s = DEFINE(%q, %d, function%s %s end, %s)", Name, Name, Name, ID, Parameters, Body, Upvalues)
    
    return Code
  end
  
  if Tag == "conditional" then
    local Code = string.format("if %s then %s ", self:Expression(Statement.condition), self:Block(Statement.thenblock))
    
    for _, Elseif in Statement.elseifs do
      Code ..= string.format("elseif %s then %s ", self:Expression(Elseif.condition), self:Block(Elseif.thenblock))
    end
    
    if Statement.elseblock then
      Code ..= string.format("else %s ", self:Block(Statement.elseblock))
    end
    
    Code ..= "end"
    return Code
  end
  
  if Tag == "while" then
    return string.format("while %s do %s end", self:Expression(Statement.condition), self:Block(Statement.body))
  end
  
  if Tag == "forin" then
    local Variables: string = ""
    
    for i, NameNode in Statement.variables do
      Variables ..= (i > 1 and ", " or "") .. NameNode.node.name.text
    end
    
    local Values: string = ""
    
    
    for i, ExprNode in Statement.values do
      Values ..= (i > 1 and ", " or "") .. self:Expression(ExprNode.node)
    end
    
    return string.format("for %s in %s do %s end", Variables, Values, self:Block(Statement.body))
  end
  
  if Tag == "for" then
    local Step: string? = Statement.step
    Step = Step and self:Expression(Step) or "1"
    
    local From: string = self:Expression(Statement.from)
    local To: string = self:Expression(Statement.to)
    local Variable: string = Statement.variable.name.text
    
    return string.format("for %s = %s, %s, %s do %s end", Variable, From, To, Step, self:Block(Statement.body))
  end
  
  if Tag == "return" then
    local ID
    local Frame = self:CurrentFrame()
    if Frame then
      ID = Frame.Id
    end
    
    local Code: string = string.format("return RET(%d%s", ID or 0, (#Statement.expressions > 0 and ", ") or "")
    for i, ExpressionNode in ipairs(Statement.expressions) do
      Code ..= self:Expression(ExpressionNode.node)
      if i < #Statement.expressions then
        Code ..= ", "
      end
    end
    
    return Code .. ")"
  end
  
  if Tag == "repeat" then
    return string.format("repeat %s until %s", self:Block(Statement.body), self:Expression(Statement.condition))
  end
  
  if Tag == "typealias" then
    error("no export")
  end
  
  error("Unsupported statement type: " .. Tag)
end

function Library:Unparse(Source: string): string
  local AST = Parser.parse(Source)
  
  return self:Block(AST.root)
end

do
  local Source = FileSystem.readfiletostring(InputPath)
  Lines = Source:split("\n")
  
  local Result = Library:Unparse(Source)
  FileSystem.writestringtofile(OutputPath, Result)
end