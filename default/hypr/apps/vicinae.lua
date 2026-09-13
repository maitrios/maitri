-- The Vicinae launcher: no layer animation, compositor blur behind its
-- translucent window, and ignore_alpha so the blur stops at the rounded panel
-- instead of filling the whole layer surface.
hl.layer_rule({ match = { namespace = "vicinae" }, no_anim = true, animation = "none", blur = true, ignore_alpha = 0.5 })
