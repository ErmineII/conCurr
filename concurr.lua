
--[[
 ConCurr, a logo-inspired functional language


]]--

local cnc = {}

local cons = {
  __div = function(lookup, key)
    while lookup do
      if lookup.r.l == key then
        return lookup.r.r, 'T'
      else
        lookup = lookup.l
      end
    end
    return nil, nil
  end,
}
cons.__add = cons
setmetatable(cons, {__call = function(_, l, r)
  return setmetatable({l=l, r=r}, cons)
end})
cnc.cons = cons

local function asStream(obj)
  if type(obj) == 'string' then
    return {
      src = obj,
      char = 1,
      peek = function(self)
        assert(self.char <= self.src:len(),
          ('EOF while reading from string %q'):format(self.src))
        return self.src:sub(self.char, self.char)
      end,
      next = function(self)
        self.char = self.char + 1
        return self.src:sub(self.char-1, self.char-1)
      end,
      atEnd = function(self)
        return self.char == #self.src+1
      end,
    }
  elseif type(obj) == 'userdata' or obj == nil then
    obj = obj or io.input()
    return {
      src = obj,
      _peek = false,
      peek = function(self)
        self._peek = self._peek or self.src:read(1) or
          error('EOF while reading file')
        return self._peek
      end,
      next = function(self)
        local next = self._peek
        self._peek = false
        return next
      end,
      atEnd = function(self)
        local pos = self.src:seek()
        if self.src:read(1) == nil then
          self.src:seek(pos)
          return true
        else
          self.src:seek(pos)
          return false
        end
      end,
    }
  else
    return obj
  end
end

cnc.read = function(s, strict)
  local consume, skipWS, skipComment, inpAtom, inpQatom,
        inpStruct, inpStructBody, inpExpr, fmt

  s = asStream(s)

  function fmt(msg)
    return (s.char and ('string %q char %i:'):format(s.src, s.char) or '')
       ..msg
  end

  function consume(ch)
    return (not s:atEnd()) and (s:peek() == ch and s:next() or false)
  end

  local function isWS(c) return c:find('[ \n\t#]') end
  local function isDL(c) return c:find('[[%]()":]') end
    -- is whitespace or delimiter?

-- ws <- (' ' | '\n' | '\t' | '#' comment)*
  function skipWS()
    while not(s:atEnd()) and isWS(s:peek()) do
      if s:next() == '#' then
        skipComment()
      end
    end
  end

-- comment <- '!' (char | '#' comment)* '!#'
--          | (!'\n' char)* '\n'
  function skipComment()
    if consume('!') then
      while not(consume('!') and consume('#')) do
        if s:next() == '#' then
          skipComment()
        end
      end
    else
      while not consume('\n') do s:next() end
    end
  end

-- atom <- !ws !( '(' | ')' | '[' | ']' | ':' | '"' ) char*
  function inpAtom()
    local atom = ''
    while not(s:atEnd() or isWS(s:peek()) or isDL(s:peek())) do
      atom = atom .. s:next()
    end
    assert(atom ~= '', fmt 'Atom expected.')
    return atom
  end

  function inpQatom()
    local atom = ''
    assert(consume('"'))
    while not consume('"') do
      if consume('\\') then
        if consume('n') then
          atom = atom .. '\n'
        elseif consume('t') then
          atom = atom .. '\t'
        else
          atom = atom .. s:next()
        end
      else
        atom = atom .. s:next()
      end
    end
    return cons(nil, atom)
  end

-- sBody <- ':'? (ws expr)*
  function inpStructBody()
    local struct = nil
    if consume(':') then
      skipWS()
      struct = inpExpr()
    end
    skipWS()
    while not (s:atEnd() or s:peek():find('[%])]')) do
      struct = cons(struct, inpExpr())
      skipWS()
    end
    return struct
  end

-- struct <- '$' sBody | ':' sBody | '(' sBody ')'? | '[' sBody ']'?
  function inpStruct()
    if consume('$') then
      return inpStructBody()
    elseif consume(':') then
      return cons(nil, inpStructBody())
    elseif consume('(') then
      local tmp = inpStructBody()
      assert(consume(')') or not strict, fmt "unterminated parentheses")
      -- note that this is not mandatory except for in strict mode:
      -- [+ 1 (* 2 3] is equivalent to [+ 1 (* 2 3)]
      return tmp
    elseif consume('[') then
      local tmp = inpStructBody()
      assert(consume(']') or not strict, fmt "unterminated brackets")
      return cons(nil, tmp)
    else
      error(fmt "Structural ( [] or () ) expression expected")
    end
  end

-- expr <- qatom | struct | atom
  function inpExpr()
    if s:peek() == '"' then
      return inpQatom()
    elseif s:peek():find('[$[(:]') then
      return inpStruct()
    else return inpAtom() end
  end

  skipWS()
  return inpExpr()
end

local function isCons(o) return getmetatable(o) == cons end

function cnc.str(obj)
  if isCons(obj) then
    if obj.l == nil then
      if isCons(obj.r) then
        return '['..cnc.parenlessStr(obj.r, true)..']'
      else
        return cnc.qatomstr(obj.r)
      end
    else
      return '('..cnc.parenlessStr(obj, true)..')'
    end
  elseif obj == nil then
    return '()'
  elseif type(obj) == 'number' or type(obj) == 'string' then
    return obj..''
  else
   return '#! lua: '..tostring(obj)..' !#'
  end
end

function cnc.parenlessStr(obj, root)
  if isCons(obj) then
    if (not isCons(obj.l)) and obj.l then
      return ': ' .. cnc.str(obj.l) .. ' ' .. cnc.str(obj.r)
    elseif obj.l == nil then
      return cnc.str(obj.r)
    elseif root and isCons(obj.r) then
      return cnc.parenlessStr(obj.l) .. ' $ '
          .. cnc.parenlessStr(obj.r, true)
    else
      return cnc.parenlessStr(obj.l) .. ' ' .. cnc.str(obj.r)
    end
  else
    return ': ' .. cnc.str(obj)
  end
end

function cnc.run(s, strict)
  s = asStream(s)
  local runner = require('cncrun.'..cnc.read(s, strict))
  return runner(cnc.read(s))
end

return cnc
