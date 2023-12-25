-- NetHack Healer Hea-goal.lua	$NHDT-Date: 1652196003 2022/05/10 15:20:03 $  $NHDT-Branch: NetHack-3.7 $:$NHDT-Revision: 1.2 $
--	Copyright (c) 1989 by Jean-Christophe Collet
--	Copyright (c) 1991, 1993 by M. Stephenson, P. Winner
-- NetHack may be freely redistributed.  See license for details.
--
des.level_init({ style = "solidfill", fg = "P" });

des.level_flags("mazelevel");

--
des.level_init({ style="mines", fg=".", bg="P", smoothed=false, joined=true, lit=1, walled=false })

des.map([[
.P....................................PP.
PP.......PPPPPPP....PPPPPPP....PPPP...PP.
...PPPPPPP....PPPPPPP.....PPPPPP..PPP...P
...PP..............................PPP...
..PP..............................PP.....
..PP..............................PPP....
..PPP..............................PP....
.PPP..............................PPPP...
...PP............................PPP...PP
..PPPP...PPPPP..PPPP...PPPPP.....PP...PP.
P....PPPPP...PPPP..PPPPP...PPPPPPP...PP..
PPP..................................PPP.
]]);
-- Dungeon Description
des.region(selection.area(00,00,40,11), "lit")
-- Stairs
des.stair("up", 39,10)
-- Non diggable walls
des.non_diggable(selection.area(00,00,40,11))
-- Objects
des.object({ id = "六尺棒", x=20, y=06, buc="blessed", spe=0, name="アスクレピオスの杖" })
des.object("雷の杖", 20, 06)
des.object()
des.object()
des.object()
des.object()
des.object()
des.object()
des.object()
des.object()
des.object()
des.object()
des.object()
des.object()
des.object()
des.object()
-- Random traps
des.trap()
des.trap()
des.trap()
des.trap()
des.trap()
des.trap()
-- Random monsters.
des.monster({ id = "サイクロプス", x=20, y=06, peaceful=0 })
des.monster("兇暴ネズミ")
des.monster("兇暴ネズミ")
des.monster("兇暴ネズミ")
des.monster({ class = "r", peaceful=0 })
des.monster({ class = "r", peaceful=0 })
des.monster("巨大ウナギ")
des.monster("巨大ウナギ")
des.monster("巨大ウナギ")
des.monster("巨大ウナギ")
des.monster("巨大ウナギ")
des.monster("巨大ウナギ")
des.monster("電気ウナギ")
des.monster("電気ウナギ")
des.monster("サメ")
des.monster("サメ")
des.monster({ class = ";", peaceful=0 })
des.monster({ class = "D", peaceful=0 })
des.monster({ class = "D", peaceful=0 })
des.monster({ class = "D", peaceful=0 })
des.monster({ class = "D", peaceful=0 })
des.monster({ class = "D", peaceful=0 })
des.monster({ class = "S", peaceful=0 })
des.monster({ class = "S", peaceful=0 })
des.monster({ class = "S", peaceful=0 })
des.monster({ class = "S", peaceful=0 })
des.monster({ class = "S", peaceful=0 })
des.monster({ class = "S", peaceful=0 })
des.monster({ class = "S", peaceful=0 })
des.monster({ class = "S", peaceful=0 })
des.monster({ class = "S", peaceful=0 })
des.monster({ class = "S", peaceful=0 })

