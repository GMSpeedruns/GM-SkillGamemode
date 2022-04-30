local admin = {}

-- Admin roles
admin.Roles = {
  None = 0,
  Moderation = 1,
  Zones = 2,
  Maps = 4,
  Times = 8,
  Players = 16,
  Server = 32,
  Authority = 64
}

-- Admin actions
admin.Actions = {
  ["Moderation"] = {
    "Strip weapons"
  },

  ["Zones"] = {
    "Add",
    "Remove"
  },

  ["Maps"] = {
    "Set tier"
  },

  ["Times"] = {
    "Edit"
  },

  ["Players"] = {
    "Ban",
    "Unban"
  },
}

return admin
