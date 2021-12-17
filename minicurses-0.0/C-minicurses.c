/*
    C-minicurses.c - A minimal module giving access to ncurses

   This Lua5 module is Copyright (c) 2021, Peter J Billam
                     www.pjb.com.au

 This module is free software; you can redistribute it and/or
       modify it under the same terms as Lua5 itself.
*/

/* #include <strings.h> */
#include <lua.h>
#include <lauxlib.h>
#include <ncurses.h>
/* less /usr/include/ncurses.h */

static int c_addstr(lua_State *L) {
	/* Lua stack: str */
	size_t len;
    const char *str  = lua_tolstring(L, 1, &len);
	addstr(str);
}
static int c_attrset(lua_State *L) {
	int attr = lua_tointeger(L, 1);
	attrset( (NCURSES_ATTR_T) attr );
}


static int c_cbreak(lua_State *L) {
	cbreak();
}

static int c_clear(lua_State *L) {
	clear();
}

static int c_clrtobot(lua_State *L) {
	clrtobot();
}

static int c_clrtoeol(lua_State *L) {
	clrtoeol();
}

static int c_echo(lua_State *L) {
	lua_pushinteger(L, echo());
	return 1;
}

static int c_endwin(lua_State *L) {
	endwin();
}

static int c_getch(lua_State *L) {
	lua_pushinteger(L, getch());
	return 1;
}

static int c_getnstr(lua_State *L) {
	int len = lua_tointeger(L, 1);
	char str[len+1];
	int rc = getnstr(str, len);
	/* fprintf(stderr, "len=%d  rc=%d\n", len, rc); */
	lua_pushstring(L, str);
	return 1;
	/* from C-readline.c: see PiL4 p.280 */
}

static int c_hline(lua_State *L) {
	lua_Integer n  = lua_tointeger(L, 1);
	hline(ACS_HLINE, n);
}

static int c_initscr(lua_State *L) {
	initscr();
}

static int c_intrflush(lua_State *L) {
	int on  = lua_toboolean(L, 1);
	intrflush(stdscr, on);
}

static int c_keypad(lua_State *L) {
	int on  = lua_toboolean(L, 1);
	keypad(stdscr, on);
}

static int c_move(lua_State *L) {
	lua_Integer row  = lua_tointeger(L, 1);
	lua_Integer col  = lua_tointeger(L, 2);
	move(row, col);
}

static int c_mvaddstr(lua_State *L) {
	/* Lua stack: x, y, str */
	lua_Integer row  = lua_tointeger(L, 1);
	lua_Integer col  = lua_tointeger(L, 2);
	size_t len;
    const char *str  = lua_tolstring(L, 3, &len);
	mvaddstr(row, col, str);
}

static int c_mvbox(lua_State *L) {
	int top_row = lua_tointeger(L, 1);
	int lft_col = lua_tointeger(L, 2);
	int bot_row = lua_tointeger(L, 3);
	int rgt_col = lua_tointeger(L, 4);
	move(top_row, lft_col);
	addch(ACS_ULCORNER); hline(ACS_HLINE, rgt_col-lft_col-1);
	move(top_row, rgt_col); addch(ACS_URCORNER); refresh();
	move(bot_row, lft_col);
	addch(ACS_LLCORNER); hline(ACS_HLINE, rgt_col-lft_col-1);
	refresh();
	move(bot_row, rgt_col); addch(ACS_LRCORNER); refresh();
	move(top_row+1, lft_col); vline(ACS_VLINE, bot_row-top_row-1); refresh();
	move(top_row+1, rgt_col); vline(ACS_VLINE, bot_row-top_row-1); refresh();
}

static int c_noecho(lua_State *L) {
	noecho();
}

static int c_nonl(lua_State *L) {
	nonl();
}

static int c_refresh(lua_State *L) {
	refresh();
}

static int c_vline(lua_State *L) {
	lua_Integer n  = lua_tointeger(L, 1);
	hline(ACS_VLINE, n);
}

/*------------------------------------------------*/

struct constant {  /* Gems p. 334 */
    const char * name;
    int value;
};
static const struct constant constants[] = {
    /* {"COLS",     COLS}, {"LINES",    LINES}, */
	{"BOLD",     A_BOLD},
	{"NORMAL",   A_NORMAL},
	{"REVERSE",  A_REVERSE},
/* BUT these are not constant :-)  what are they ? unsigned char ?
	{"VLINE",    (const unsigned char) ACS_VLINE},
	{"HLINE",    (const unsigned char) ACS_HLINE},
	{"ULCORNER", (const unsigned char) ACS_ULCORNER},
	{"URCORNER", (const unsigned char) ACS_URCORNER},
	{"LLCORNER", (const unsigned char) ACS_LLCORNER},
	{"LRCORNER", (const unsigned char) ACS_LRCORNER},
*/

/*	{"A_NORMAL", A_NORMAL},
	{"A_ATTRIBUTES", A_ATTRIBUTES},
	{"A_CHARTEXT", A_CHARTEXT},
	{"A_COLOR", A_COLOR},
	{"A_STANDOUT", A_STANDOUT},
	{"A_UNDERLINE", A_UNDERLINE},
	{"A_REVERSE", A_REVERSE},
	{"A_BLINK", A_BLINK},
	{"A_DIM", A_DIM},
	{"A_BOLD", A_BOLD},
	{"A_ALTCHARSET", A_ALTCHARSET},
	{"A_INVIS", A_INVIS},
	{"A_PROTECT", A_PROTECT},
	{"A_HORIZONTAL", A_HORIZONTAL},
	{"A_LEFT", A_LEFT},
	{"A_LOW", A_LOW},
	{"A_RIGHT", A_RIGHT},
	{"A_TOP", A_TOP},
	{"A_VERTICAL", A_VERTICAL},
*/
	{NULL, 0}
};

static const luaL_Reg prv[] = {  /* private functions */
    {"addstr",   c_addstr},
    {"attrset",  c_attrset},
    {"cbreak",   c_cbreak},
    {"clear",    c_clear},
    {"clrtobot", c_clrtobot},
    {"clrtoeol", c_clrtoeol},
    {"echo",     c_echo},
    {"getch",    c_getch},
    {"getnstr",  c_getnstr},
    {"hline",    c_hline},
    {"initscr",  c_initscr},
    {"keypad",   c_keypad},
    {"noecho",   c_noecho},
    {"endwin",   c_endwin},
    {"move",     c_move},
    {"mvaddstr", c_mvaddstr},
    {"mvbox",    c_mvbox},
    {"refresh",  c_refresh},
    {"vline",    c_vline},
    {NULL, NULL}
};

static int initialise(lua_State *L) {  /* Lua Programming Gems p. 335 */
    /* Lua stack: aux table, prv table, dat table */
    int index;  /* define constants in module namespace */
    for (index = 0; constants[index].name != NULL; ++index) {
        lua_pushinteger(L, constants[index].value);
        lua_setfield(L, 3, constants[index].name);
    }
    /* lua_pushvalue(L, 1);   * set the aux table as environment */
    /* lua_replace(L, LUA_ENVIRONINDEX);
       unnecessary here, fortunately, because it fails in 5.2 */
    lua_pushvalue(L, 2); /* register the private functions */
    /* https://github.com/TheLinx/lao/issues/2 */
#if LUA_VERSION_NUM >= 502
    luaL_setfuncs(L, prv, 0);    /* 5.2 */
    return 0;
#else
    /* https://search.brave.com/search?q=luaL_register&source=web */
    luaL_register(L, NULL, prv); /* 5.1 */
    return 0;
#endif
}

int luaopen_minicurses(lua_State *L) {
    lua_pushcfunction(L, initialise);
    return 1;
}

