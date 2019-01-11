local function TreasurePoolObj(file,patchString,poolHasXPDrop,poolBlackList)
  local self = {};
  self.File = file;
  self.PatchString = patchString;
  self.PoolHasXPDrop = poolHasXPDrop;
  self.PoolBlacklist = poolBlackList;
  return self;
end
 
local function GetPatchingPools()
  return {
    TreasurePoolObj("/treasure/cropharvest.treasurepools",
    [[
    [{
      "op": "test",
      "path": "/#treasurePoolName#",
      "inverse": false
    },{
      "op": "test",
      "path": "/#treasurePoolName#/0/1/fill",
      "inverse": false
    }, {
      "op": "add",
      "path": "/#treasurePoolName#/0/1/fill/-",
      "value": {
        "item": ["experienceorb", 5]
      }
    }],
    [{
      "op": "test",
      "path": "/#treasurePoolName#",
      "inverse": false
    },{
      "op": "test",
      "path": "/#treasurePoolName#/0/1/fill",
      "inverse": true
    }, {
      "op": "add",
      "path": "/#treasurePoolName#/0/1/fill",
      "value": [{
        "item": ["experienceorb", 5]
      }
      ]
    }] ]],
    function (pool)
      local toReturn = false;
      if pool.pool == "experienceorbpool" then
        toReturn = true;
      end
      if pool.item then
        if pool.item[1] == "experienceorb" then
          toReturn = true;
        end
      end
      return toReturn;
    end,{}),
    TreasurePoolObj("/treasure/hunting.treasurepools",
    [[
    [{
      "op": "test",
      "path": "/#treasurePoolName#",
      "inverse": false
    },{
      "op": "test",
      "path": "/#treasurePoolName#/0/1/fill",
      "inverse": false
    },
    {
      "op": "add",
      "path": "/#treasurePoolName#/0/1/fill/-",
      "value": {
        "pool": "experienceorbpool"
      }
    }],
    [{
      "op": "test",
      "path": "/#treasurePoolName#",
      "inverse": false
    },{
      "op": "test",
      "path": "/#treasurePoolName#/0/1/fill",
      "inverse": true
    },
    {
      "op": "add",
      "path": "/#treasurePoolName#/0/1/fill",
      "value": [{
        "pool": "experienceorbpool"
      }]
    }] ]],
    function (pool)
      local toReturn = false;
      if pool.pool == "experienceorbpool" then
        toReturn = true;
      end
      if pool.item then
        if pool.item[1] == "experienceorb" then
          toReturn = true;
        end
      end
      return toReturn;
    end,{smallfishtreasure = true,tentagnatHunting = true}),
    TreasurePoolObj("/treasure/monster.treasurepools",
    [[
    [{
      "op": "test",
      "path": "/#treasurePoolName#",
      "inverse": false
    },{
      "op": "test",
      "path": "/#treasurePoolName#/0/1/fill",
      "inverse": false
    },
    {
      "op": "add",
      "path": "/#treasurePoolName#/0/1/fill/-",
      "value": {
        "pool": "experienceorbpool"
      }
    }],
    [{
      "op": "test",
      "path": "/#treasurePoolName#",
      "inverse": false
    },{
      "op": "test",
      "path": "/#treasurePoolName#/0/1/fill",
      "inverse": true
    },
    {
      "op": "add",
      "path": "/#treasurePoolName#/0/1/fill",
      "value": [{
        "pool": "experienceorbpool"
      }]
    }] ]],
    function (pool)
      local toReturn = false;
      if pool.pool == "experienceorbpool" then
        toReturn = true;
      end
      if pool.item then
        if pool.item[1] == "experienceorb" then
          toReturn = true;
        end
      end
      return toReturn;
    end,{smallfishtreasure = true,tentagnatHunting = true}),
    TreasurePoolObj("/treasure/npcdrops.treasurepools",
    [[
    [{
      "op": "test",
      "path": "/#treasurePoolName#",
      "inverse": false
    },{
      "op": "test",
      "path": "/#treasurePoolName#/0/1/fill",
      "inverse": false
    },
    {
      "op": "add",
      "path": "/#treasurePoolName#/0/1/fill/-",
      "value": {
        "pool": "experienceorbpool"
      }
    }],
    [{
      "op": "test",
      "path": "/#treasurePoolName#",
      "inverse": false
    },{
      "op": "test",
      "path": "/#treasurePoolName#/0/1/fill",
      "inverse": true
    },
    {
      "op": "add",
      "path": "/#treasurePoolName#/0/1/fill",
      "value": [{
        "pool": "experienceorbpool"
      }]
    }] ]],
    function (pool)
      local toReturn = false;
      if pool.pool == "experienceorbpool" then
        toReturn = true;
      end
      if pool.item then
        if pool.item[1] == "experienceorb" then
          toReturn = true;
        end
      end
      return toReturn;
    end,{smallfishtreasure = true,tentagnatHunting = true})
  };
end
 
local function CheckPool(pool,validator)
  local fill = pool[1][2].fill;
  if not fill then
    return false;
  end
  for i=1,#fill do
    if validator(fill[i]) then
      return true;
    end
  end
  return false;
end
 
function PatchRPGPools()
  sb.logInfo("Generating RPG Growth treasurepools patches");
  local filesToPatch = GetPatchingPools();
  for i=1,#filesToPatch do
    local fileToPatch = filesToPatch[i];
    local generatedPatches = {};
    local treasurePools = root.assetJson(fileToPatch.File);
    for poolName,pool in pairs(treasurePools) do
      if not fileToPatch.PoolBlacklist[poolName] then
        if not CheckPool(pool,fileToPatch.PoolHasXPDrop) then
          generatedPatches[#generatedPatches + 1] = string.gsub(fileToPatch.PatchString, "#treasurePoolName#", poolName);
        end
      end
    end
    if #generatedPatches ~= 0 then
       sb.logInfo(string.format("Patches generated for file %s: \n %s",fileToPatch.File,table.concat(generatedPatches,",\n")))
    end
  end
end