#! /usr/bin/env lua
ST = require 'spanning_tree'
require 'DataDumper'

function Dump(...)
	local d = string.gsub(DataDumper(...), '^return ', '')
	return d
end

local function printf (...) print(string.format(...)) end

----------------------------------------------------------

points = {   -- point 2D {x,y}
 {1,1}, {2,6}, {3,3}, {3,5}, {3,7},{4,8},{6,8},{7,6},{7,2},{8,8}
}
function distance_func (point1, point2)
	local dx = point2[1] - point1[1]
	local dy = point2[2] - point1[2]
	return math.sqrt(dx*dx + dy*dy)
end

links, distances = ST.prim(points, distance_func)
-- printf(' points   are: %s', Dump(points))
-- printf('  links   are: %s', Dump(links))
-- printf('distances are: %s', Dump(distances))

-- print(ST.points_datablock(points))
-- print(ST.links_datablock(links))
-- os.exit()

-- printf(ST.gnuplot(points,links,700,600,'/tmp/sp.png'))

--local src = ST.gnuplot_src(points,links,1000,900,'/tmp/sp.png')
--ST.gnuplot_run(src)
--os.execute('feh /tmp/sp.png')

math.randomseed(os.time())
for n,npoints in ipairs({50,100,200}) do
	points = {}
	min = 1 ; max = 10 ; range = max - min
	for i = 1,npoints do
		points[i] = {min + range*math.random(), min + range*math.random() }
	end
	start_time = os.clock()
	links, distances = ST.prim(points, distance_func)
	local src = ST.gnuplot_src(points,links,distances, 1000,900,'/tmp/sp.png')
	end_time = os.clock()
	printf('#points = %d   elapsed time = %g', #points, end_time-start_time)
	ST.gnuplot_run(src)
	os.execute('feh /tmp/sp.png')
end

for n,npoints in ipairs({100}) do
	points = {}
	min = 1 ; max = 10 ; range = max - min
	for i = 1,npoints do
		points[i] = {min + range*math.random(), min + range*math.random() }
	end
	start_time = os.clock()
	links, distances = ST.prim(points, distance_func)
	local src = ST.gnuplot_src(points,links,distances, 1000,900,'/tmp/sp.jpg')
	end_time = os.clock()
	printf('#points = %d   elapsed time = %g', #points, end_time-start_time)
	ST.gnuplot_run(src)
	run_time = os.clock()
	printf('           gnuplot run time = %g', run_time-end_time)
	-- os.execute('gv /tmp/sp.eps')
end
