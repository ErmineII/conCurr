

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
}

cons.__add = cons
cons.__div = cons.assoc

setmetatable(cons, {__call = function(_, l, r)
  return setmetatable({l=l, r=r}, cons)
end})

return cons
