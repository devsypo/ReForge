local bit32 = bit32
local byte = string.byte
local char = string.char

local band = bit32.band
local lshift = bit32.lshift
local rshift = bit32.rshift

local B64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

local DECODE = table.create(256, -1)
for i = 1, 64 do
  DECODE[byte(B64, i)] = i - 1
end
DECODE[61] = 0

local function Base64Encode(Input: string): string
  local Len = #Input
  if Len == 0 then
    return ""
  end

  local OutLen = ((Len + 2) // 3) * 4
  local Out: table = table.create(OutLen)

  local O = 1
  local I = 1

  while I <= Len do
    local A = byte(Input, I) or 0
    local B = byte(Input, I + 1) or 0
    local C = byte(Input, I + 2) or 0

    local V = lshift(A, 16) + lshift(B, 8) + C

    Out[O]     = char(byte(B64, rshift(V, 18) + 1))
    Out[O + 1] = char(byte(B64, band(rshift(V, 12), 63) + 1))
    Out[O + 2] = (I + 1 <= Len)
      and char(byte(B64, band(rshift(V, 6), 63) + 1))
      or "="
    Out[O + 3] = (I + 2 <= Len)
      and char(byte(B64, band(V, 63) + 1))
      or "="

    O += 4
    I += 3
  end

  return table.concat(Out) :: string
end

local function Base64Decode(Input: string): string
  local Len = #Input
  if Len == 0 then
    return ""
  end

  local Pad = 0
  if Input:sub(-2) == "==" then
    Pad = 2
  elseif Input:sub(-1) == "=" then
    Pad = 1
  end

  local OutLen = (Len * 3 // 4) - Pad
  local Out: table = table.create(OutLen)

  local O = 1
  local I = 1

  while I <= Len do
    local A = DECODE[byte(Input, I)]
    local B = DECODE[byte(Input, I + 1)]
    local C = DECODE[byte(Input, I + 2)]
    local D = DECODE[byte(Input, I + 3)]

    local V = lshift(A, 18)
            + lshift(B, 12)
            + lshift(C, 6)
            + D

    if O <= OutLen then
      Out[O] = char(band(rshift(V, 16), 255))
      O += 1
    end
    if O <= OutLen then
      Out[O] = char(band(rshift(V, 8), 255))
      O += 1
    end
    if O <= OutLen then
      Out[O] = char(band(V, 255))
      O += 1
    end

    I += 4
  end

  return table.concat(Out) :: string
end

return { encode = Base64Encode, decode = Base64Decode }