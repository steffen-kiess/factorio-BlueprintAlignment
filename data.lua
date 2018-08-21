require("util")

local blueprintHolder = table.deepcopy(data.raw["item-with-inventory"]["item-with-inventory"])
blueprintHolder.name = "BlueprintAlignment-blueprint-holder"
data:extend({blueprintHolder})

local graphicsDir = "__BlueprintAlignment__/graphics/"
--local graphicsDir = "__BlueprintAlignmentTest__/graphics/"

data:extend({{
  type = "item",
  name = "BlueprintAlignment-InfoItem",
  icon = graphicsDir .. "icon-128.png",
  icon_size = 128,
  flags = { "hidden" },
  subgroup = "circuit-network",
  order = "a",
  place_result = "BlueprintAlignment-Info",
  stack_size = 1
}})

local empty = {
  filename = "__core__/graphics/empty.png",
  priority = "extra-high",
  line_length = 1,
  width = 0,
  height = 0,
  frame_count = 1,
  direction_count = 1,
  animation_speed = 1,
}

local sprite = {
  filename = graphicsDir .. "cross-64.png",
  priority = "extra-high",
  width = 64,
  height = 64,
}

local blueprintAlignmentInfo = {
  type = "programmable-speaker",
  name = "BlueprintAlignment-Info",
  icon = graphicsDir .. "icon-128.png",
  icon_size = 128,
  flags = { "player-creation", "placeable-off-grid", "not-deconstructable", "not-repairable", "not-on-map" },
  max_health = 1,
  selectable_in_game = false,
  collision_mask = {},
  collision_box = {{-0.5, -0.5}, {0.5, 0.5}},
  energy_source = {
    type = "electric",
    usage_priority = "secondary-input",
    input_flow_limit = "0W",
    render_no_network_icon = false,
    render_no_power_icon = false,
  },
  energy_usage_per_tick = "0W",
  sprite = sprite,
  audible_distance_modifier = 0,
  maximum_polyphony = 0,
  instruments = {},
  placeable_by = { item = "BlueprintAlignment-InfoItem", count = 1 },
}
data:extend({blueprintAlignmentInfo})
