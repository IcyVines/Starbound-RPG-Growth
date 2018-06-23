function joinMaps(table1, table2)
  if not table1 then
    if not table2 then return nil
    else return table2 end
  else
    if not table2 then return table1
    else
      for k,v in pairs(table2) do
        table1[k] = v
      end
      return table1
    end
  end
end

function getArrayFromType(t, atype)
  local returnT = {}
  for k,v in ipairs(t) do
    if v.type == atype then
      for x,y in ipairs(v.apply) do
         table.insert(returnT, y)
      end
    end
  end
  return returnT
end

function getDictionaryFromType(t, atype)
  local returnT = nil
  for k,v in ipairs(t) do
    if v.type == atype then
      if not returnT then returnT = {} end
      for x,y in pairs(v.apply) do
         returnT[x] = y
      end
    end
  end
  return returnT
end