require("util")

local blueprintHolder = table.deepcopy(data.raw["item-with-inventory"]["item-with-inventory"])
blueprintHolder.name = "BlueprintAlignment-blueprint-holder"
data:extend({blueprintHolder})
