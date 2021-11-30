equipmentCategories = { "armor" }

for k,v in pairs(data.raw["equipment-category"]) do
	table.insert(equipmentCategories, k)
end
