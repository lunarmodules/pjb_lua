local C = require 'minicurses'
C.initscr()
C.mvaddstr(0, 0, 'initscr worked :-) ; mvaddstr(0,0,str)')

C.move(1,1); C.noecho() ; C.addstr('move(1,1); noecho(); addstr(str)')

C.move(2,2); C.addstr('move(2,2); addstr(str), getch() : ')
C.refresh()
local c = C.getch()

C.move(3,3)
C.addstr('move(3,3); addstr(str); echo(); getch(); noecho() : ')
C.echo()
C.refresh()
local d = C.getch()
C.noecho()

-- C.move(4,3)
-- C.addstr('move(4,3); addstr(str); echo(); getstr(); noecho() : ')
-- C.echo()
-- C.refresh()
-- local s = C.getstr()
-- C.noecho()

-- C.endwin() ; os.exit()

C.attrset(C.BOLD)
C.mvaddstr(5,6,'attrset(BOLD); mvaddstr(4,4,str); attrset(NORMAL) ')
C.attrset(C.NORMAL)

C.attrset(C.REVERSE)
C.mvaddstr(6,7,'attrset(REVERSE); mvaddstr(5,5,str); attrset(NORMAL) ')
C.attrset(C.NORMAL)

-- C.attrset(C.STANDOUT)
-- C.mvaddstr(6,6,'attrset(STANDOUT); mvaddstr(6,6,str); attrset(NORMAL) ')
-- C.attrset(C.NORMAL)

-- C.attrset(C.DIM);
-- C.mvaddstr(7,7,'attrset(DIM); mvaddstr(7,7,str); attrset(NORMAL) ');
-- C.attrset(C.NORMAL);

C.mvaddstr(21,0,'The amusements of modern urban populations tend more and')
C.mvaddstr(22,0,'more to be passive and collective, and to consist of')
C.mvaddstr(23,0,'inactive observation of the skilled activities of others.')
C.mvaddstr(24,0,'-- Bertrand Russell, "Useless" Knowledge, round 1930')
C.mvaddstr(7,3, 'See the text below? Press a key to test clrtobot() ... ')
e = C.getch()
C.move(8,0)
C.clrtobot()

C.mvaddstr(8,6,
  'See the text on this line ? Press a key to test clrtoeol() ... ')
C.move(8,33)
e = C.getch()
C.clrtoeol()

C.echo()
C.mvaddstr(9,5,'echo(); getnstr() -- enter a string: ')
C.refresh()
s = C.getnstr(100)
C.noecho()
C.mvaddstr(10,4,'you typed : '..s)
C.refresh()

C.echo()
C.mvaddstr(11,3,'echo(); mvgetnstr() -- enter a string: ')
C.refresh()
s = C.mvgetnstr(11,42,100)
C.noecho()
C.mvaddstr(12,2,'you typed : '..s)
C.refresh()

C.mvaddstr(13,1, 'Press any key to quit ')
local e = C.getch()

C.endwin()
-- print(C.NORMAL, C.DIM, C.BOLD, C.REVERSE)
