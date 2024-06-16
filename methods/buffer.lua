function dump(o)
    if type(o) == 'table' then
       local s = '{ '
       for k,v in pairs(o) do
          if type(k) ~= 'number' then k = '"'..k..'"' end
          s = s .. '['..k..'] = ' .. dump(v) .. ','
       end
       return s .. '} '
    else
       return tostring(o)
    end
end

local knownBuffers = {}

local original = {
    ["writestring"] = clonefunction(buffer.writestring),
    ["create"] = clonefunction(buffer.create)
}

function createKnownBuffer(buff, size)
    print("Buffer was created!", buff)
    size = size or buffer.len(buff)

    knownBuffers[buff] = table.create(size, "{}")

    return knownBuffers[buff]
end

function getBuffer(buff)
    local data = knownBuffers[buff]

    if not data then
        return createKnownBuffer(buff)
    end

    return data
end

function bufferCreate(len)
    local ret = original.create(len)
    createKnownBuffer(ret, len)

    return ret
end

function numberWrite(buff, offset, value)
    local buffKnown = getBuffer(buff)

    buffKnown[offset] = value
end

function onStringWrite(buff, offset, value, count)
    count = count or string.len(value)
    local ret = original.writestring(buff, offset, value, count)
    local buffKnown = getBuffer(buff)

    local pos = 1
    local til = offset + count

    for i=offset,til do
        buffKnown[i] = string.sub(value, pos, pos)
        pos += 1
    end

    return ret
end

hookfunction(buffer.create, bufferCreate)
hookfunction(buffer.writestring, onStringWrite)

local old
old = hookfunction(buffer.writei8, function(buff, offset, value)
    numberWrite(buff, offset, value)
    old(buff, offset, value)
end)

local old
old = hookfunction(buffer.writeu8, function(buff, offset, value)
    numberWrite(buff, offset, value)
    old(buff, offset, value)
end)

local old
old = hookfunction(buffer.writei16, function(buff, offset, value)
    numberWrite(buff, offset, value)
    old(buff, offset, value)
end)

local old
old = hookfunction(buffer.writeu16, function(buff, offset, value)
    numberWrite(buff, offset, value)
    old(buff, offset, value)
end)

local old
old = hookfunction(buffer.writei32, function(buff, offset, value)
    numberWrite(buff, offset, value)
    old(buff, offset, value)
end)

local old
old = hookfunction(buffer.writeu32, function(buff, offset, value)
    numberWrite(buff, offset, value)
    old(buff, offset, value)
end)

local old
old = hookfunction(buffer.writef32, function(buff, offset, value)
    numberWrite(buff, offset, value)
    old(buff, offset, value)
end)

local old
old = hookfunction(buffer.writef64, function(buff, offset, value)
    numberWrite(buff, offset, value)
    old(buff, offset, value)
end)

local old
old = hookfunction(buffer.fill, function(buff, offset, value, count)
    count = count or buffer.len(buff) - offset
    local til = offset + count

    local buffKnown = getBuffer(buff)

    for i=offset,til do
        buffKnown[i] = value
    end

    old(buff, offset, value, count)
end)

local old
old = hookfunction(buffer.copy, function(buff, targetOffset, s, sOffset, count)
    sOffset = sOffset or 0
    count = count or buffer.len(s) - sOffset

    local til = targetOffset + count

    local buffKnown = getBuffer(buff)
    local buffKnownS = getBuffer(s)

    local iS = sOffset
    local isTil = sOffset + count

    for i=targetOffset,til do
        if targetOffset > buffer.len(buff) then break end
        if iS > isTil then break end
        buffKnown[i] = buffKnownS[iS]
        iS += 1
    end

    old(buff, targetOffset, s, sOffset, count)
end)

local Buff = {}

function Buff.toString(data)
    local str = ""
    local buff = getBuffer(data)

    for i=1,#buff do
        if buff[i] == "{}" then continue end
        str = str..buff[i]
    end

    return str
end

return Buff