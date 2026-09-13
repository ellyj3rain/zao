-- ZAO_Binding.lua - the local development key binding.
-- The final key is the operator's; this one exists so the state surface can
-- be opened in a game now.

local bind = {}
bind.value = "[ZAO]"
table.insert(keyBinding, bind)

bind = {}
bind.value = "ZAOInspect"
bind.key = Keyboard.KEY_O
table.insert(keyBinding, bind)
