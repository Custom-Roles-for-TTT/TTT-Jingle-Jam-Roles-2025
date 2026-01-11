local ROLE = {}

ROLE.nameraw = "chef"
ROLE.name = "Chef"
ROLE.nameplural = "Chefs"
ROLE.nameext = "a Chef"
ROLE.nameshort = "chf"

ROLE.desc = [[You are {role}!
]]
ROLE.shortdesc = ""

ROLE.team = ROLE_TEAM_INNOCENT

ROLE.convars =
{
}

ROLE.translations = {
    ["english"] = {
        ["chf_stove_name"] = "Stove",
        ["chf_stove_name_health"] = "Stove ({current}/{max})",
        ["chf_stove_hint_start"] = "Press {usekey} to start cooking",
        ["chf_stove_hint_progress"] = "Cooking: {time} remaining",
        ["chf_stove_hint_retrieve_2"] = "Press {usekey} to retrieve cooked food before it burns in {time}!",
        ["chf_stove_hint_retrieve_3"] = "Press {usekey} to retrieve burnt food",
        ["chf_stove_damaged"] = "Your Stove has been damaged!",
        ["chf_stove_help_pri"] = "Use {primaryfire} to place your Stove on the ground",
        ["chf_stove_help_sec"] = "Use {secondaryfire} to change the food and buff type",
        ["chf_stove_type_label"] = "Stove Type: ",
        ["chf_stove_type_0"] = "None",
        ["chf_stove_type_1"] = "Burger",
        ["chf_stove_type_2"] = "Hot Dog",
        ["chf_stove_type_3"] = "Fish",
        ["chf_buff_type_label"] = "Buff Type: ",
        ["chf_buff_type_0"] = "None",
        -- TODO
        ["chf_buff_type_1"] = "BURG",
        ["chf_buff_type_2"] = "DOG",
        ["chf_buff_type_3"] = "HSIF"
    }
}

RegisterRole(ROLE)

-- Role features
CHEF_FOOD_TYPE_NONE = 0
CHEF_FOOD_TYPE_BURGER = 1
CHEF_FOOD_TYPE_HOTDOG = 2
CHEF_FOOD_TYPE_FISH = 3