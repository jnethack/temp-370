-- NetHack tower tower1.lua	$NHDT-Date: 1717178759 2024/05/31 18:05:59 $  $NHDT-Branch: NetHack-3.7 $:$NHDT-Revision: 1.3 $
--	Copyright (c) 1989 by Jean-Christophe Collet
-- NetHack may be freely redistributed.  See license for details.
--
--
-- Upper stage of Vlad's tower
des.level_init({ style = "solidfill", fg = " " });

des.level_flags("mazelevel", "noteleport", "hardfloor", "solidify")
des.map({ halign = "half-left", valign = "center", map = [[
  --- --- ---  
  |.| |.| |.|  
---S---S---S---
|.......+.+...|
---+-----.-----
  |...\.|.+.|  
---+-----.-----
|.......+.+...|
---S---S---S---
  |.| |.| |.|  
  --- --- ---  
]] });

local niches = { {03,01}, {03,09}, {07,01}, {07,09}, {11,01}, {11,09} };
shuffle(niches);

des.ladder("down", 11,05)
-- The lord and his court
des.monster("吸血鬼ヴラド", 06, 05)
des.monster("V",niches[1])
des.monster("V",niches[2])
des.monster("V",niches[3])
-- The brides; they weren't named in Bram Stoker's original _Dracula_
-- and when appearing in umpteen subsequent books and movies there is
-- no consensus for their names.  According to the Wikipedia entry for
-- "Brides of Dracula", the "Czechoslovakian TV film Hrabe Drakula (1971)"
-- gave them titles rather than (or perhaps in addition to) specific names
-- and we use those titles here.  Marking them as 'waiting' forces them to
-- start in vampire form instead of vampshifted into bat/fog/wolf form.
des.monster({ id="Vampire Lady", niches[4], name="Madame", waiting=1 })
des.monster({ id="Vampire Lady", niches[5], name="Marquise", waiting=1 })
des.monster({ id="Vampire Lady", niches[6], name="Countess", waiting=1 })
-- The doors
des.door("closed",08,03)
des.door("closed",10,03)
des.door("closed",03,04)
des.door("locked",10,05)
des.door("locked",08,07)
des.door("locked",10,07)
des.door("closed",03,06)
-- treasures
des.object("宝箱", 07,05)

des.object("宝箱",niches[6])
des.object("宝箱",niches[1])
des.object("宝箱",niches[2])
des.object("宝箱",niches[3])
des.object({ id = "宝箱", coord=niches[4],
             contents = function()
                des.object({ id = "蜜蝋のろうそく", quantity=math.random(4,8) })
             end
});
des.object({ id = "宝箱", coord=niches[5],
             contents = function()
                des.object({ id = "獣脂のろうそく", quantity=math.random(4,8) })
             end
});
-- We have to protect the tower against outside attacks
des.non_diggable(selection.area(00,00,14,10))
