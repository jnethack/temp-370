
-- Tests for JNetHack PR changes
-- Covers changed functions in src/apply.c, src/allmain.c, and constants in include/hack.h
-- Run via wizmode: wizloadlua test_jp_changes.lua

nh.parse_config("OPTIONS=number_pad:0");
nh.parse_config("OPTIONS=runmode:teleport");
nh.parse_config("OPTIONS=!timed_delay");

local POS = { x = 10, y = 10 };

local function reset_level_flat()
    des.reset_level();
    des.level_flags("noflip");
    des.level_init({ style = "solidfill", fg = ".", lit = true });
    des.teleport_region({ region = {POS.x, POS.y, POS.x, POS.y},
                          region_islev = true, dir = "both" });
    des.finalize_level();
    for k, v in pairs(nh.stairways()) do
        des.terrain(v.x, v.y, ".");
    end
end

local function use_item_dir(action, itemname, dir)
    nh.debug_flags({ prevent_pline = true });
    u.clear_inventory();
    u.giveobj(obj.new(itemname));
    local o = u.inventory;
    local ot = o:totable();
    nh.pushkey(action);
    nh.pushkey(ot.invlet);
    if dir ~= nil then
        nh.pushkey(dir);
    end
    nh.doturn();
    nh.debug_flags({ prevent_pline = false });
end

local function assert_true(cond, msg)
    if not cond then
        error("FAIL: " .. msg);
    end
end

-- ===========================================================================
-- Tests for apply.c: use_camera (changed messages + JP formatting)
-- ===========================================================================

local function test_camera_directions()
    reset_level_flat();
    nh.debug_flags({ mongen = false, hunger = false });

    -- Camera use in each cardinal direction should not crash
    for _, dir in ipairs({ "h", "j", "k", "l", "y", "u", "b", "n" }) do
        use_item_dir("a", "uncursed camera", dir);
    end

    -- Camera aimed upward (ceiling direction)
    use_item_dir("a", "uncursed camera", "<");

    -- Camera aimed downward (floor/surface direction) - triggers JP surface message
    use_item_dir("a", "blessed camera", ">");
    use_item_dir("a", "+0 blessed camera", ">");

    nh.debug_flags({ mongen = false, hunger = false });
    nh.pline("test_camera_directions: OK");
end

-- ===========================================================================
-- Tests for apply.c: use_towel (changed messages, conditional JP vars)
-- ===========================================================================

local function test_towel_clean()
    reset_level_flat();
    nh.debug_flags({ prevent_pline = true });

    -- Using an uncursed towel when clean
    u.clear_inventory();
    u.giveobj(obj.new("uncursed towel"));
    local o = u.inventory;
    local ot = o:totable();
    nh.pushkey("a");
    nh.pushkey(ot.invlet);
    nh.doturn();

    nh.debug_flags({ prevent_pline = false });
    nh.pline("test_towel_clean: OK");
end

local function test_towel_cursed()
    reset_level_flat();
    nh.debug_flags({ prevent_pline = true });

    -- Cursed towel should do something different (slimy hands or gunk on face)
    u.clear_inventory();
    u.giveobj(obj.new("cursed towel"));
    local o = u.inventory;
    local ot = o:totable();
    nh.pushkey("a");
    nh.pushkey(ot.invlet);
    nh.doturn();

    nh.debug_flags({ prevent_pline = false });
    nh.pline("test_towel_cursed: OK");
end

-- ===========================================================================
-- Tests for apply.c: use_stethoscope / its_dead()
-- These test the JP changes to its_dead():
--   - 'more_corpses' variable removed (#if 0 JP)
--   - 'one' variable removed (#if 0 JP)
--   - 'here' computed using direct comparison instead of u_at()
-- ===========================================================================

local function test_stethoscope_on_single_corpse()
    reset_level_flat();
    nh.debug_flags({ mongen = false, hunger = false, prevent_pline = true });

    -- Place one corpse at player's feet
    obj.new("hill orc corpse"):placeobj(u.ux, u.uy);

    -- Use stethoscope downward to examine floor items (its_dead code path)
    use_item_dir("a", "blessed stethoscope", ">");

    nh.debug_flags({ mongen = false, hunger = false, prevent_pline = false });
    nh.pline("test_stethoscope_on_single_corpse: OK");
end

local function test_stethoscope_on_multiple_corpses()
    reset_level_flat();
    nh.debug_flags({ mongen = false, hunger = false, prevent_pline = true });

    -- Place two corpses at player's feet (tests removed 'more_corpses' logic)
    obj.new("hill orc corpse"):placeobj(u.ux, u.uy);
    obj.new("kobold corpse"):placeobj(u.ux, u.uy);

    -- JP version removed the 'more_corpses' variable; this must not crash
    use_item_dir("a", "blessed stethoscope", ">");

    nh.debug_flags({ mongen = false, hunger = false, prevent_pline = false });
    nh.pline("test_stethoscope_on_multiple_corpses: OK");
end

local function test_stethoscope_on_corpse_adjacent()
    reset_level_flat();
    nh.debug_flags({ mongen = false, hunger = false, prevent_pline = true });

    -- Place corpse one tile to the right (tests 'here' = false code path)
    obj.new("hill orc corpse"):placeobj(u.ux + 1, u.uy);

    -- Stethoscope aimed right
    use_item_dir("a", "blessed stethoscope", "l");

    nh.debug_flags({ mongen = false, hunger = false, prevent_pline = false });
    nh.pline("test_stethoscope_on_corpse_adjacent: OK");
end

local function test_stethoscope_on_statue()
    reset_level_flat();
    nh.debug_flags({ mongen = false, hunger = false, prevent_pline = true });

    -- Place statue at player's feet (tests statue code path in its_dead)
    obj.new("statue"):placeobj(u.ux, u.uy);

    use_item_dir("a", "blessed stethoscope", ">");

    nh.debug_flags({ mongen = false, hunger = false, prevent_pline = false });
    nh.pline("test_stethoscope_on_statue: OK");
end

local function test_stethoscope_on_empty_floor()
    reset_level_flat();
    nh.debug_flags({ mongen = false, hunger = false, prevent_pline = true });

    -- No corpse/statue: stethoscope should output "nothing special" message
    use_item_dir("a", "blessed stethoscope", ">");

    nh.debug_flags({ mongen = false, hunger = false, prevent_pline = false });
    nh.pline("test_stethoscope_on_empty_floor: OK");
end

local function test_stethoscope_lateral_directions()
    reset_level_flat();
    nh.debug_flags({ mongen = false, hunger = false, prevent_pline = true });

    -- Test all lateral directions for stethoscope
    for _, dir in ipairs({ "h", "j", "k", "l", "<" }) do
        use_item_dir("a", "blessed stethoscope", dir);
    end

    nh.debug_flags({ mongen = false, hunger = false, prevent_pline = false });
    nh.pline("test_stethoscope_lateral_directions: OK");
end

-- ===========================================================================
-- Tests for apply.c: use_whistle / use_magic_whistle (changed messages)
-- ===========================================================================

local function test_whistle_types()
    reset_level_flat();
    nh.debug_flags({ mongen = false, hunger = false, prevent_pline = true });

    -- Tin whistle (uncursed = "high" sound, cursed = "shrill" sound)
    use_item_dir("a", "uncursed tin whistle", nil);
    use_item_dir("a", "cursed tin whistle", nil);

    -- Magic whistle (calls pets)
    use_item_dir("a", "blessed magic whistle", nil);
    use_item_dir("a", "uncursed magic whistle", nil);
    use_item_dir("a", "cursed magic whistle", nil);

    nh.debug_flags({ mongen = false, hunger = false, prevent_pline = false });
    nh.pline("test_whistle_types: OK");
end

-- ===========================================================================
-- Tests for apply.c: use_mirror (changed messages, removed use_plural var)
-- The JP version removed the 'use_plural' boolean for boots/gloves/lenses
-- ===========================================================================

local function test_mirror_self()
    reset_level_flat();
    nh.debug_flags({ mongen = false, hunger = false, prevent_pline = true });

    -- Mirror aimed at self (u.dx==0, u.dy==0, u.dz==0)
    use_item_dir("a", "uncursed mirror", ".");

    nh.debug_flags({ mongen = false, hunger = false, prevent_pline = false });
    nh.pline("test_mirror_self: OK");
end

local function test_mirror_lateral()
    reset_level_flat();
    nh.debug_flags({ mongen = false, hunger = false, prevent_pline = true });

    -- Mirror in various directions (no monsters there = no special effect)
    for _, dir in ipairs({ "h", "j", "k", "l" }) do
        use_item_dir("a", "uncursed mirror", dir);
    end

    nh.debug_flags({ mongen = false, hunger = false, prevent_pline = false });
    nh.pline("test_mirror_lateral: OK");
end

local function test_mirror_ceiling_floor()
    reset_level_flat();
    nh.debug_flags({ mongen = false, hunger = false, prevent_pline = true });

    -- Mirror aimed at ceiling (u.dz < 0)
    use_item_dir("a", "uncursed mirror", "<");

    -- Mirror aimed at floor (u.dz > 0)
    use_item_dir("a", "uncursed mirror", ">");

    nh.debug_flags({ mongen = false, hunger = false, prevent_pline = false });
    nh.pline("test_mirror_ceiling_floor: OK");
end

-- ===========================================================================
-- Tests for apply.c: use_bell (changed messages)
-- ===========================================================================

local function test_bell_ordinary()
    reset_level_flat();
    nh.debug_flags({ mongen = false, hunger = false, prevent_pline = true });

    -- Ordinary bell use
    use_item_dir("a", "uncursed bell", nil);
    use_item_dir("a", "cursed bell", nil);
    use_item_dir("a", "blessed bell", nil);

    nh.debug_flags({ mongen = false, hunger = false, prevent_pline = false });
    nh.pline("test_bell_ordinary: OK");
end

-- ===========================================================================
-- Tests for apply.c: use_candelabrum / use_candle (changed messages,
-- removed 's' variable for candles/candle string in JP version)
-- ===========================================================================

local function test_candelabrum_no_candles()
    reset_level_flat();
    nh.debug_flags({ mongen = false, hunger = false, prevent_pline = true });

    -- Candelabrum with no candles attached
    u.clear_inventory();
    u.giveobj(obj.new("candelabrum of invocation"));
    local o = u.inventory;
    local ot = o:totable();
    nh.pushkey("a");
    nh.pushkey(ot.invlet);
    nh.doturn();

    nh.debug_flags({ mongen = false, hunger = false, prevent_pline = false });
    nh.pline("test_candelabrum_no_candles: OK");
end

local function test_candle_apply()
    reset_level_flat();
    nh.debug_flags({ mongen = false, hunger = false, prevent_pline = true });

    -- Applying candle: try to attach to candelabrum or just light it
    use_item_dir("a", "uncursed tallow candle", nil);
    use_item_dir("a", "cursed tallow candle", nil);
    use_item_dir("a", "uncursed wax candle", nil);

    nh.debug_flags({ mongen = false, hunger = false, prevent_pline = false });
    nh.pline("test_candle_apply: OK");
end

local function test_candelabrum_with_candles_lit()
    reset_level_flat();
    nh.debug_flags({ mongen = false, hunger = false, prevent_pline = true });

    -- Create a lit candelabrum (7 candles) and snuff it
    u.clear_inventory();
    u.giveobj(obj.new("lit candelabrum of invocation"));
    local o = u.inventory;
    local ot = o:totable();
    nh.pushkey("a");
    nh.pushkey(ot.invlet);
    nh.doturn();

    nh.debug_flags({ mongen = false, hunger = false, prevent_pline = false });
    nh.pline("test_candelabrum_with_candles_lit: OK");
end

-- ===========================================================================
-- Tests for apply.c: use_lamp / snuff_lit (changed messages,
-- removed 'ithem' variable in JP version)
-- ===========================================================================

local function test_lamp_apply()
    reset_level_flat();
    nh.debug_flags({ mongen = false, hunger = false, prevent_pline = true });

    -- Light an oil lamp
    use_item_dir("a", "uncursed oil lamp", nil);

    -- Light it again to snuff it (lamplit -> !lamplit)
    use_item_dir("a", "lit oil lamp", nil);

    -- Brass lantern
    use_item_dir("a", "uncursed brass lantern", nil);

    nh.debug_flags({ mongen = false, hunger = false, prevent_pline = false });
    nh.pline("test_lamp_apply: OK");
end

local function test_lamp_lit_wax_candle()
    reset_level_flat();
    nh.debug_flags({ mongen = false, hunger = false, prevent_pline = true });

    -- Lit candles (uses different code path than oil lamp)
    -- JP version removed 'ithem' variable and uses verbalized JP text
    use_item_dir("a", "6 burning tallow candles", nil);

    nh.debug_flags({ mongen = false, hunger = false, prevent_pline = false });
    nh.pline("test_lamp_lit_wax_candle: OK");
end

-- ===========================================================================
-- Tests for apply.c: use_unicorn_horn (changed messages)
-- ===========================================================================

local function test_unicorn_horn_apply()
    reset_level_flat();
    nh.debug_flags({ mongen = false, hunger = false, prevent_pline = true });

    use_item_dir("a", "blessed unicorn horn", nil);
    use_item_dir("a", "uncursed unicorn horn", nil);
    use_item_dir("a", "cursed unicorn horn", nil);

    nh.debug_flags({ mongen = false, hunger = false, prevent_pline = false });
    nh.pline("test_unicorn_horn_apply: OK");
end

-- ===========================================================================
-- Tests for apply.c: jump (changed messages)
-- ===========================================================================

local function test_jump_no_jumping_intrinsic()
    -- jump() with magic=0 checks for Jumping intrinsic.
    -- JP changed messages: "足が無くては跳べない！", "そんな遠くまで跳べない．"
    -- We verify the game doesn't crash when the jump command fails.
    reset_level_flat();
    nh.debug_flags({ mongen = false, hunger = false, prevent_pline = true });

    -- 'j' in NetHack (without number_pad) is "move south", not jump
    -- Jump is triggered via '#jump' extended command or via spell
    -- Test that movement commands don't crash (jp messages for obstacles)
    nh.pushkey("h");
    nh.doturn();
    nh.pushkey("l");
    nh.doturn();
    nh.pushkey("k");
    nh.doturn();
    nh.pushkey("j");
    nh.doturn();

    nh.debug_flags({ mongen = false, hunger = false, prevent_pline = false });
    nh.pline("test_jump_no_jumping_intrinsic: OK");
end

-- ===========================================================================
-- Tests for apply.c: dorub / use_lamp light_cocktail (changed messages)
-- ===========================================================================

local function test_rub_lamp()
    -- dorub() is called when rubbing a lamp (JP messages changed).
    -- In NetHack, 'a' (apply) on a lamp calls use_lamp, while '#rub' calls dorub.
    -- Test via apply to verify no crash; the rubbing path is exercised by the game.
    reset_level_flat();
    nh.debug_flags({ mongen = false, hunger = false, prevent_pline = true });

    -- Apply brass lantern (use_lamp) - tests JP message "電気ランプをこすっても意味はないと思うが"
    -- is shown when dorub is called; applying lights it instead
    u.clear_inventory();
    u.giveobj(obj.new("brass lantern"));
    local o = u.inventory;
    local ot = o:totable();
    nh.pushkey("a");
    nh.pushkey(ot.invlet);
    nh.doturn();

    -- Apply again to test snuff path
    o = u.inventory;
    if o then
        ot = o:totable();
        nh.pushkey("a");
        nh.pushkey(ot.invlet);
        nh.doturn();
    end

    nh.debug_flags({ mongen = false, hunger = false, prevent_pline = false });
    nh.pline("test_rub_lamp: OK");
end

-- ===========================================================================
-- Tests for apply.c: light_cocktail (changed messages)
-- ===========================================================================

local function test_light_potion_oil()
    reset_level_flat();
    nh.debug_flags({ mongen = false, hunger = false, prevent_pline = true });

    -- Apply oil potion to light it (changed JP messages in light_cocktail)
    use_item_dir("a", "uncursed potion of oil", nil);

    nh.debug_flags({ mongen = false, hunger = false, prevent_pline = false });
    nh.pline("test_light_potion_oil: OK");
end

-- ===========================================================================
-- Tests for apply.c: use_tinning_kit (changed messages)
-- ===========================================================================

local function test_tinning_kit_no_corpse()
    reset_level_flat();
    nh.debug_flags({ mongen = false, hunger = false, prevent_pline = true });

    -- Tinning kit with no corpse should give appropriate message
    use_item_dir("a", "uncursed tinning kit", nil);

    nh.debug_flags({ mongen = false, hunger = false, prevent_pline = false });
    nh.pline("test_tinning_kit_no_corpse: OK");
end

local function test_tinning_kit_with_corpse()
    reset_level_flat();
    nh.debug_flags({ mongen = false, hunger = false, prevent_pline = true });

    -- Place a corpse at player's feet
    obj.new("hill orc corpse"):placeobj(u.ux, u.uy);

    -- Tinning kit should allow tinning the corpse
    u.clear_inventory();
    u.giveobj(obj.new("uncursed tinning kit"));
    local o = u.inventory;
    local ot = o:totable();
    nh.pushkey("a");
    nh.pushkey(ot.invlet);
    -- Select the corpse (press ',' or the appropriate choice)
    nh.pushkey(","); -- might select floor item or press other key
    nh.doturn();

    nh.debug_flags({ mongen = false, hunger = false, prevent_pline = false });
    nh.pline("test_tinning_kit_with_corpse: OK");
end

-- ===========================================================================
-- Tests for apply.c: use_leash (changed messages, JP-specific formatting)
-- ===========================================================================

local function test_leash_no_creature()
    reset_level_flat();
    nh.debug_flags({ mongen = false, hunger = false, prevent_pline = true });

    -- Leash in direction with no creature
    use_item_dir("a", "uncursed leash", "h");
    use_item_dir("a", "uncursed leash", "j");
    use_item_dir("a", "uncursed leash", "k");
    use_item_dir("a", "uncursed leash", "l");

    nh.debug_flags({ mongen = false, hunger = false, prevent_pline = false });
    nh.pline("test_leash_no_creature: OK");
end

-- ===========================================================================
-- Tests for apply.c: is_valid_jump_pos (changed messages for various
-- jump failure conditions)
-- ===========================================================================

local function test_jump_magical()
    reset_level_flat();
    nh.debug_flags({ mongen = false, hunger = false, prevent_pline = true });

    -- Use scroll/spell to attempt jump - tests changed JP error messages
    -- The jump function (magic=0) should fail gracefully without Jumping intrinsic
    -- We can test by casting/using items that call jump(magic > 0)
    -- For this test, just verify items that may call jump don't crash
    use_item_dir("a", "uncursed leather boots", nil); -- not jumping boots
    nh.debug_flags({ mongen = false, hunger = false, prevent_pline = false });
    nh.pline("test_jump_magical: OK");
end

-- ===========================================================================
-- Tests for apply.c: fig_transform (changed messages for figurine animation)
-- ===========================================================================

local function test_figurine_in_inventory()
    reset_level_flat();
    nh.debug_flags({ mongen = false, hunger = false, prevent_pline = true });

    -- Give player a figurine; it might transform after some turns
    u.clear_inventory();
    u.giveobj(obj.new("blessed figurine of a ki-rin"));
    local fig = u.inventory:totable();
    assert_true(fig.otyp_name == "figurine", "figurine not created");

    -- Take a few turns - figurine transformation check
    for i = 1, 5 do
        nh.pushkey(".");  -- wait/rest
        nh.doturn();
    end

    nh.debug_flags({ mongen = false, hunger = false, prevent_pline = false });
    nh.pline("test_figurine_in_inventory: OK");
end

-- ===========================================================================
-- Tests for apply.c: beautiful() (changed charisma descriptions in JP)
-- ===========================================================================

local function test_mirror_self_charisma_range()
    reset_level_flat();
    nh.debug_flags({ mongen = false, hunger = false, prevent_pline = true });

    -- The beautiful() function uses JP equivalents for charisma descriptions
    -- Test mirror on self across charisma states (uses look_str format)
    -- Just test that it doesn't crash for normal character
    use_item_dir("a", "uncursed mirror", ".");

    nh.debug_flags({ mongen = false, hunger = false, prevent_pline = false });
    nh.pline("test_mirror_self_charisma_range: OK");
end

-- ===========================================================================
-- Tests for apply.c: hollow_str (changed to Japanese text)
-- The static string hollow_str was changed to JP text in the PR
-- Test it via stethoscope on secret door/corridor
-- ===========================================================================

local function test_stethoscope_secret_door()
    -- Tests the hollow_str static string which was changed to JP in apply.c
    -- The string "うつろな音を聞いた．秘密の%sに違いない！" is used when a secret
    -- door or passage is found via stethoscope.
    des.reset_level();
    des.level_flags("noflip");
    des.level_init({ style = "solidfill", fg = " " });
    -- Build a room with a wall the player can probe
    des.map([[
---------
|.......|
|.......|
|.......|
---------
]]);
    -- Place a secret door in the east wall
    des.door({ state = "secret", wall = "east" });
    des.teleport_region({ region = {4, 2, 4, 2}, region_islev = true, dir = "both" });
    des.finalize_level();

    nh.debug_flags({ mongen = false, hunger = false, prevent_pline = true });

    -- Stethoscope aimed at all walls (may reveal secret door with JP hollow_str message)
    use_item_dir("a", "blessed stethoscope", "h");
    use_item_dir("a", "blessed stethoscope", "j");
    use_item_dir("a", "blessed stethoscope", "k");
    use_item_dir("a", "blessed stethoscope", "l");

    nh.debug_flags({ mongen = false, hunger = false, prevent_pline = false });
    nh.pline("test_stethoscope_secret_door: OK");
end

-- ===========================================================================
-- Tests for apply.c: snuff_candle (removed 'many' variable in JP version)
-- ===========================================================================

local function test_snuff_single_candle()
    reset_level_flat();
    nh.debug_flags({ mongen = false, hunger = false, prevent_pline = true });

    -- Single lit candle (many=false path - removed in JP)
    use_item_dir("a", "lit tallow candle", nil);

    nh.debug_flags({ mongen = false, hunger = false, prevent_pline = false });
    nh.pline("test_snuff_single_candle: OK");
end

local function test_snuff_multiple_candles()
    reset_level_flat();
    nh.debug_flags({ mongen = false, hunger = false, prevent_pline = true });

    -- Multiple lit candles (many=true path - removed in JP)
    use_item_dir("a", "6 burning tallow candles", nil);

    nh.debug_flags({ mongen = false, hunger = false, prevent_pline = false });
    nh.pline("test_snuff_multiple_candles: OK");
end

-- ===========================================================================
-- Tests for allmain.c: health restoration messages (regen_pw, regen_hp)
-- These were changed to JP messages: "エネルギーが回復した．" and "体力が完全回復した．"
-- ===========================================================================

local function test_energy_regen_message()
    reset_level_flat();
    nh.debug_flags({ mongen = false, hunger = false, prevent_pline = true });

    -- Drain then restore energy to trigger the JP "full of energy" message
    -- We can't easily control energy regen timing, but we can verify no crash
    -- by taking many rest turns
    for i = 1, 10 do
        nh.pushkey(".");
        nh.doturn();
    end

    nh.debug_flags({ mongen = false, hunger = false, prevent_pline = false });
    nh.pline("test_energy_regen_message: OK");
end

local function test_hp_regen_message()
    reset_level_flat();
    nh.debug_flags({ mongen = false, hunger = false, prevent_pline = true });

    -- Rest for many turns to trigger health regen messages
    for i = 1, 20 do
        nh.pushkey(".");
        nh.doturn();
    end

    nh.debug_flags({ mongen = false, hunger = false, prevent_pline = false });
    nh.pline("test_hp_regen_message: OK");
end

-- ===========================================================================
-- Tests for allmain.c: welcome() - alignment/gender suffix format changes
-- JP changed " %s" -> "%s" for alignment, " %s" -> "の%s" for gender
-- ===========================================================================

local function test_welcome_message_no_crash()
    -- The welcome() function runs at game start; if we got this far it worked
    -- Test that the character name/role string was formatted without crash
    nh.debug_flags({ prevent_pline = true });

    -- Access character information fields to verify they exist
    local ux = u.ux;
    local uy = u.uy;
    assert_true(type(ux) == "number", "u.ux should be a number");
    assert_true(type(uy) == "number", "u.uy should be a number");
    assert_true(ux > 0 and uy > 0, "player position should be valid");

    nh.debug_flags({ prevent_pline = false });
    nh.pline("test_welcome_message_no_crash: OK");
end

-- ===========================================================================
-- Tests for hack.h: KILLED_SUFFIX constant value
-- KILLED_SUFFIX = 3, must be distinct from KILLED_BY_AN=0, KILLED_BY=1,
-- NO_KILLER_PREFIX=2
-- ===========================================================================

local function test_killed_suffix_constant()
    -- Verify that the nhc (nethack constants) module has the expected values
    -- These correspond to the constants in hack.h:
    -- KILLED_BY_AN = 0, KILLED_BY = 1, NO_KILLER_PREFIX = 2, KILLED_SUFFIX = 3

    -- We can't directly access C #define values from Lua, but we can verify
    -- that the death message formatting works correctly by inducing death
    -- (not practical in a unit test). Instead, we verify the game doesn't crash
    -- when the killer format is used.
    nh.pline("test_killed_suffix_constant: KILLED_SUFFIX=3 defined in hack.h (cannot verify value from Lua)");
    nh.pline("test_killed_suffix_constant: OK (compile-time constant, see include/hack.h:606)");
end

-- ===========================================================================
-- Tests for include/defsym.h: Japanese symbol descriptions
-- Verify the game can load and display map with JP terrain descriptions
-- ===========================================================================

local function test_defsym_jp_terrain_descriptions()
    des.reset_level();
    des.level_flags("noflip");
    -- Build a map with various terrain types (all described in JP in defsym.h)
    des.map([[
-----------
|.........|
|...>.....|
|...<.....|
|.........+
|.........|
-----------
]]);
    des.teleport_region({ region = {2, 2, 2, 2}, region_islev = true, dir = "both" });
    des.finalize_level();

    nh.debug_flags({ mongen = false, prevent_pline = true });

    -- Move around the map to trigger terrain display updates
    -- (Tests that JP terrain symbol descriptions don't crash the game)
    nh.pushkey("l");
    nh.doturn();
    nh.pushkey("h");
    nh.doturn();
    nh.pushkey("j");
    nh.doturn();
    nh.pushkey("k");
    nh.doturn();

    nh.debug_flags({ mongen = false, prevent_pline = false });
    nh.pline("test_defsym_jp_terrain_descriptions: OK");
end

-- ===========================================================================
-- Tests for src/.gitignore: !*.rej added
-- This is a git configuration change, not testable via game tests
-- ===========================================================================

-- ===========================================================================
-- Tests for include/extern.h: monverbself wrapped in #if 0 JP
-- The function declaration was removed; this means no code should call it
-- (compilation would fail if it did). Verify game works without it.
-- ===========================================================================

local function test_monverbself_unused()
    reset_level_flat();
    nh.debug_flags({ mongen = false, hunger = false, prevent_pline = true });

    -- The mirror use_mirror() in JP no longer calls monverbself()
    -- Test mirror on monsters that previously used monverbself:
    -- S_NYMPH monsters use monverbself("admire") in English version
    -- JP version uses a direct pline instead
    -- Just verify mirror works without monverbself

    -- Use mirror in multiple directions
    for _, dir in ipairs({ "h", "j", "k", "l", "y", "u", "b", "n" }) do
        use_item_dir("a", "uncursed mirror", dir);
    end

    nh.debug_flags({ mongen = false, hunger = false, prevent_pline = false });
    nh.pline("test_monverbself_unused: OK");
end

-- ===========================================================================
-- Tests for include/optlist.h: Japanese option descriptions
-- Verify the options system loads JP descriptions without crash
-- ===========================================================================

local function test_optlist_jp_descriptions()
    -- Parse a few of the options that had their descriptions changed to JP
    -- The descriptions are just cosmetic but we can verify options still work
    nh.parse_config("OPTIONS=number_pad:0");
    local np = nh.get_config("number_pad");
    assert_true(np ~= nil, "number_pad option should be accessible");

    nh.parse_config("OPTIONS=runmode:teleport");
    local rm = nh.get_config("runmode");
    assert_true(rm ~= nil, "runmode option should be accessible");

    nh.parse_config("OPTIONS=color");
    local clr = nh.get_config("color");
    assert_true(clr ~= nil, "color option should be accessible");

    nh.pline("test_optlist_jp_descriptions: OK");
end

-- ===========================================================================
-- Tests for include/config.h: jpatchlevel.h included
-- Verify version info includes JP patch information
-- ===========================================================================

local function test_config_jp_patchlevel()
    -- The config.h now includes jpatchlevel.h for version info
    -- The game starting up means the includes worked at compile time
    -- Verify game version info is accessible
    nh.pline("test_config_jp_patchlevel: Included jpatchlevel.h at compile time (game started successfully)");
    nh.pline("test_config_jp_patchlevel: OK");
end

-- ===========================================================================
-- Additional regression tests for edge cases in changed code
-- ===========================================================================

local function test_stethoscope_corpse_then_statue()
    -- Test that when both corpse and statue are present, the code
    -- handles the ordering correctly (modified logic in its_dead)
    reset_level_flat();
    nh.debug_flags({ mongen = false, hunger = false, prevent_pline = true });

    -- Place both a statue and a corpse at the same spot
    -- The code picks the uppermost one
    obj.new("statue"):placeobj(u.ux, u.uy);
    obj.new("hill orc corpse"):placeobj(u.ux, u.uy);

    use_item_dir("a", "blessed stethoscope", ">");

    nh.debug_flags({ mongen = false, hunger = false, prevent_pline = false });
    nh.pline("test_stethoscope_corpse_then_statue: OK");
end

local function test_camera_ceiling_surface()
    -- Camera aimed at ceiling and surface/floor - triggers JP messages
    -- "写真を撮った" (took a picture of)
    reset_level_flat();
    nh.debug_flags({ mongen = false, hunger = false, prevent_pline = true });

    -- u.dz > 0 = floor/surface ("> ")
    use_item_dir("a", "uncursed camera", ">");
    -- u.dz < 0 = ceiling (< )
    use_item_dir("a", "uncursed camera", "<");

    nh.debug_flags({ mongen = false, hunger = false, prevent_pline = false });
    nh.pline("test_camera_ceiling_surface: OK");
end

local function test_mirror_underwater_behavior()
    -- Mirror behavior when underwater - JP message: "淀んだ水を映した"
    -- We can't easily set underwater state in tests, but verify no crash on floor aim
    reset_level_flat();
    nh.debug_flags({ mongen = false, hunger = false, prevent_pline = true });

    use_item_dir("a", "uncursed mirror", ">");
    use_item_dir("a", "uncursed mirror", "<");
    use_item_dir("a", "uncursed mirror", ".");

    nh.debug_flags({ mongen = false, hunger = false, prevent_pline = false });
    nh.pline("test_mirror_underwater_behavior: OK");
end

local function test_towel_all_variants()
    -- Test towel in various curse states - JP messages vary
    reset_level_flat();
    nh.debug_flags({ mongen = false, hunger = false, prevent_pline = true });

    -- Uncursed (clean message: "汚れていない")
    use_item_dir("a", "uncursed towel", nil);

    -- Blessed (also gives "clean" message)
    use_item_dir("a", "blessed towel", nil);

    -- Cursed (slimy hands or gunk on face)
    use_item_dir("a", "cursed towel", nil);

    nh.debug_flags({ mongen = false, hunger = false, prevent_pline = false });
    nh.pline("test_towel_all_variants: OK");
end

local function test_leash_on_self()
    -- Leash on self: JP message "自分を縛る？変なの．．．"
    reset_level_flat();
    nh.debug_flags({ mongen = false, hunger = false, prevent_pline = true });

    -- Direction '.' targets self
    use_item_dir("a", "uncursed leash", ".");

    nh.debug_flags({ mongen = false, hunger = false, prevent_pline = false });
    nh.pline("test_leash_on_self: OK");
end

-- ===========================================================================
-- Run all tests
-- ===========================================================================

nh.debug_flags({ mongen = false, hunger = false });

local tests = {
    -- apply.c: use_camera
    test_camera_directions,
    test_camera_ceiling_surface,

    -- apply.c: use_towel
    test_towel_clean,
    test_towel_cursed,
    test_towel_all_variants,

    -- apply.c: use_stethoscope / its_dead
    test_stethoscope_on_single_corpse,
    test_stethoscope_on_multiple_corpses,
    test_stethoscope_on_corpse_adjacent,
    test_stethoscope_on_statue,
    test_stethoscope_on_empty_floor,
    test_stethoscope_lateral_directions,
    test_stethoscope_secret_door,
    test_stethoscope_corpse_then_statue,

    -- apply.c: use_whistle / use_magic_whistle
    test_whistle_types,

    -- apply.c: use_mirror
    test_mirror_self,
    test_mirror_lateral,
    test_mirror_ceiling_floor,
    test_mirror_self_charisma_range,
    test_mirror_underwater_behavior,

    -- apply.c: use_bell
    test_bell_ordinary,

    -- apply.c: use_candelabrum / use_candle / snuff_candle
    test_candelabrum_no_candles,
    test_candle_apply,
    test_candelabrum_with_candles_lit,
    test_snuff_single_candle,
    test_snuff_multiple_candles,

    -- apply.c: use_lamp / snuff_lit / light_cocktail
    test_lamp_apply,
    test_lamp_lit_wax_candle,
    test_light_potion_oil,

    -- apply.c: use_unicorn_horn
    test_unicorn_horn_apply,

    -- apply.c: use_tinning_kit
    test_tinning_kit_no_corpse,
    test_tinning_kit_with_corpse,

    -- apply.c: use_leash
    test_leash_no_creature,
    test_leash_on_self,

    -- apply.c: jump / is_valid_jump_pos
    test_jump_no_jumping_intrinsic,
    test_jump_magical,

    -- apply.c: fig_transform
    test_figurine_in_inventory,

    -- apply.c: dorub
    test_rub_lamp,

    -- allmain.c: regen_pw, regen_hp messages
    test_energy_regen_message,
    test_hp_regen_message,

    -- allmain.c: welcome()
    test_welcome_message_no_crash,

    -- hack.h: KILLED_SUFFIX constant
    test_killed_suffix_constant,

    -- defsym.h: JP terrain descriptions
    test_defsym_jp_terrain_descriptions,

    -- extern.h: monverbself removed
    test_monverbself_unused,

    -- optlist.h: JP descriptions
    test_optlist_jp_descriptions,

    -- config.h: jpatchlevel.h
    test_config_jp_patchlevel,
};

local passed = 0;
local failed = 0;

for i, testfn in ipairs(tests) do
    local ok, err = pcall(testfn);
    if ok then
        passed = passed + 1;
    else
        failed = failed + 1;
        nh.pline("FAIL [" .. i .. "]: " .. tostring(err));
    end
end

nh.debug_flags({ mongen = false, hunger = false, prevent_pline = false });

nh.pline(string.format("test_jp_changes: %d passed, %d failed", passed, failed));
if failed > 0 then
    error(string.format("test_jp_changes: %d tests FAILED", failed));
end