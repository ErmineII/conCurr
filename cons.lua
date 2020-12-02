

local cons
cons = {
  assoc = function(lookup, key)
    while lookup do
      if lookup.r.l == key then
        return lookup.r
      else
        lookup = lookup.l
      end
    end
    return nil
  end,
  is = function(obj) return getmetatable(obj) == cons end,
  __index = function (self, index)
    if index == "car" then return self[1]
    elseif index == "cdr" then return self[2]
    elseif index == "l" then return self[1]
    elseif index == "r" then return self[2]
    else error() end
  end
}

cons.__add = cons
cons.__div = cons.assoc

setmetatable(cons, {__call = function(_, l, r)
  return setmetatable({[1]=l, [2]=r}, cons)
end})

return cons
