---------------------------------------------------------------------
--     This Lua5 module is Copyright (c) 2022, Peter J Billam      --
--                         pjb.com.au                              --
--  This module is free software; you can redistribute it and/or   --
--         modify it under the same terms as Lua5 itself.          --
---------------------------------------------------------------------
-- Example usage:
-- local MM = require 'mymodule'
-- MM.foo()

local M = {} -- public interface
M.Version = '1.0'
M.VersionDate = '24jan2022'

------------------------------ private ------------------------------
local function warn(...)
    local a = {}
    for k,v in pairs{...} do table.insert(a, tostring(v)) end
    io.stderr:write(table.concat(a),'\n') ; io.stderr:flush()
end
local function die(...) warn(...);  os.exit(1) end
local function qw(s)  -- t = qw[[ foo  bar  baz ]]
	local t = {} ; for x in s:gmatch("%S+") do t[#t+1] = x end ; return t
end
local function printf (...) print(string.format(...)) end
local function round(x)
	if not x then return nil end
	return math.floor(x+0.5)
end

require 'DataDumper'
local function Dump(...)
	local d = string.gsub(DataDumper(...), '^return ', '')
	return d
end

function closest_point (points, point, isolated_points, distance_func)
	local closest_isolated
	local minimum_distance = math.huge
	for k,v in pairs(isolated_points) do
		local dist = distance_func(points[point], points[k])
		if dist < minimum_distance then -- a new shortest !
			minimum_distance = dist
			closest_isolated = k
		end
	end
	return closest_isolated, minimum_distance
end

local function points_datablock ( points )
	local arr = {'$P << EOP\n',}
	local format = string.format
	local  push  = table.insert
	for i, point in ipairs(points) do
		push(arr, string.format('%g %g %d\n',point[1], point[2], i))
	end
	push(arr, 'EOP\n')
	return table.concat(arr)
end

local function links_datablock (points, links )
	-- lines are  "x1 y1 \nx2 y2"    where a link is {{x1,y1}, {x2,y2}}
	local arr = {'$L << EOL\n',}
	local format = string.format
	local  push  = table.insert
	for i, link in ipairs(links) do
		push(arr, string.format('%g %g\n%g %g\n\n',
		  points[link[1]][1], points[link[1]][2],
		  points[link[2]][1], points[link[2]][2])
		)
	end
	push(arr, 'EOL\n')
	return table.concat(arr)
end

local function numbers_datablock ( points, offset )
	local arr = {'$N << EON\n',}
	local format = string.format
	local  push  = table.insert
	for i, point in ipairs(points) do
		push(arr, string.format('%g %g %d\n',point[1], point[2]-offset, i))
	end
	push(arr, 'EON\n')
	return table.concat(arr)
end

local function ranges (points)
	local xmin = math.huge ; local xmax = 0 - math.huge
	local ymin = math.huge ; local ymax = 0 - math.huge
	for i, point in ipairs(points) do
		local x = point[1] ; local y = point[2]
		if x < xmin then xmin = x end
		if x > xmax then xmax = x end
		if y < ymin then ymin = y end
		if y > ymax then ymax = y end
	end
	local xmargin = (xmax-xmin) * 0.06
	local ymargin = (ymax-ymin) * 0.06
	return xmin-xmargin, xmax+xmargin, ymin-ymargin, ymax+ymargin
end

local function average (dists)
	local av = 0
	for i, dist in ipairs(dists) do av = av + dist end
	return av / #dists
end

------------------------------ public ------------------------------

function M.prim (points, distance_func)
	-- I think this is Prim's Algorithm ...
	local isolated = {}
	for i = 2,#points do isolated[i] = true end
	local connected = {1}
	local links     = {}  -- a link is {i,j}
	local distances = {}
	for i = 2, #points do
		local minimum_distance = math.huge
		local closest_connected, closest_isolated
		-- seek the isolated point closest to any connected point:
		for ic, nc in pairs(connected) do
			if nc then
				local closest, dist =
				  closest_point(points, nc, isolated, distance_func)
				if dist < minimum_distance then -- a new shortest !
					minimum_distance  = dist
					closest_connected = nc
					closest_isolated  = closest
				end
			end
		end
		table.insert(connected, closest_isolated)
		isolated[closest_isolated] = nil
		table.insert(links, {closest_connected, closest_isolated})
		table.insert(distances, minimum_distance)
	end
	return links, distances
end


function M.gnuplot_run(src)
	local P = assert(io.popen('gnuplot', 'w'))
	P:write(src)
	P:close()
end
function M.gnuplot_src(points,links,distances, xpixels,ypixels, output_file)
	if not   ypixels   then   ypixels   =  770 end
	if not   xpixels   then   xpixels   = 1300 end
	if not output_file then output_file = '/tmp/spanning_tree' end
	-- If output_file is *.ps should change to 'set terminal postscript'
	--   and if *.eps 'set terminal postscript eps'
	--   see: 'gnuplot> help set terminal postscript'
	-- If points are 3D, should use `set view`
	--   http://hirophysics.com/gnuplot/gnuplot10.html
	--   http://lowrank.net/gnuplot/plotpm3d-e.html
	--   https://sites.science.oregonstate.edu/~landaur/nacphy/DATAVIS/gnuplot.html
	--   https://psy.swansea.ac.uk/staff/Carter/gnuplot/gnuplot_3d.htm
	-- gnuplot> help lines   ;   help circles   ;    help datablocks  etc...
	local xmin, xmax, ymin, ymax = ranges(points)
	local r1 = 0.03 * math.sqrt((xmax-xmin)*(ymax-ymin))
	local radius
	if #links == 0 then
		radius = 0.4*r1
	else
		local r2 = 0.1 * average(distances)
		radius = 0.3*r1 + 0.7*r2
	end
	local fontsz = round((radius/r1) * 0.025 * math.sqrt(xpixels*ypixels))
-- warn(string.format('radius=%g r1=%g xpixels=%d ypixels=%d\n',radius,r1,xpixels,ypixels))
-- printf('#links = %d   radius/r1 = %g', #links, radius/r1)
	local offset =  tostring((radius/r1) * 0.006 * (ymax-ymin))
	-- printf('radius=%g  fontsz=%d  offset=%g\n', radius,fontsz,offset)
	-- use datablocks: $P for points, $L for lines, $N for point=numbers
	local terminal = 'set terminal png enhanced '
	if string.match(output_file, '%.jpg$') then
		terminal = 'set terminal jpeg enhanced'
	elseif string.match(output_file, '%.eps$') then
		terminal = 'set terminal postscript eps '
	end
-- warn(string.format('fontsz=%g type(fontsz)=%s\n',fontsz,type(fontsz)))
	local arr = {terminal,
	  string.format(' size %d,%d',xpixels,ypixels),
	  string.format(' font "sans, %d"\n set colorsequence classic\n',fontsz),
	  points_datablock(points),
	  links_datablock(points, links),
	  numbers_datablock(points, offset),
	  string.format('set output "%s"\n', output_file),
	  string.format('set xrange [%g:%g]\n',xmin,xmax),
	  string.format('set yrange [%g:%g]\n',ymin,ymax),
[[plot \
  $L using 1:2 with lines lc rgb "black" lw 2 notitle,\
  $P using 1:2:(]], tostring(radius),
   [[) with circles linecolor rgb "white" \
   lw 2 fill solid border lc lt 0 notitle, \
  $N using 1:2:3 with labels offset (0,0) font 'Arial Bold' notitle
]]
}
	return table.concat(arr)
end

return M

--[=[

=pod

=head1 NAME

spanning_tree.lua - some simple minimal-spanning-tree funtions

=head1 SYNOPSIS

 local ST = require 'spanning_tree'
 points = {   -- point is 2D {x,y}
   {1,1}, {2,6}, {3,3}, {3,5}, {3,7},{4,8},{6,8},{7,6},{7,2},{8,8}
 }
 function distance_func (point1, point2)
	local dx = point2[1] - point1[1]
	local dy = point2[2] - point1[2]
	return math.sqrt(dx*dx + dy*dy)
 end
 links, distances = ST.prim(points, distance_func)

 gnuplot_code = gnuplot(points, links)

=head1 DESCRIPTION

This module implements some simple minimum-spanning-tree funtions.

https://en.wikipedia.org/wiki/Prim%27s_algorithm

  point    == vertex
  link     == edge
  distance == weight

The algorithm may informally be described as performing the following steps:

  Initialize a tree with a single vertex, chosen arbitrarily from the graph.
  Grow the tree by one edge:
    of the edges that connect the tree to vertices not yet in the tree,
    find the minimum-weight edge, and transfer it to the tree.
  Repeat step 2 (until all vertices are in the tree).

In more detail, it may be implemented following the pseudocode below. 

  Associate with each vertex v of the graph a number C[v] (the cheapest cost
    of a connection to v) and an edge E[v] (the edge providing that cheapest
    connection). To initialize these values, set all values of C[v] to +inf
    (or to any number larger than the maximum edge weight)
    and set each E[v] to a special flag value indicating that
    there is no edge connecting v to earlier vertices.
  Initialize an empty forest F and a set Q of vertices that have
    not yet been included in F (initially, all vertices).
  Repeat the following steps until Q is empty:
      Find and remove a vertex v from Q having the minimum possible value of C[v]
      Add v to F and, if E[v] is not the special flag value, also add E[v] to F
      Loop over the edges vw connecting v to other vertices w.
	    For each such edge, if w still belongs to Q and vw has
	    smaller weight than C[w], perform the following steps:
          Set C[w] to the cost of edge vw
          Set E[w] to point to edge vw.
  Return F

=head1 FUNCTIONS

=over 3

=item B<ST.prim(points, distance_function)>

I<prim> returns (links, distances)

=item B<ST.clusters(links, distances)>

I<clusters> returns ( ?? )

=item B<ST.gnuplot(points, links, xpixels, ypixels, output_file)

https://stackoverflow.com/questions/20406346/how-to-plot-tree-graph-web-data-on-gnuplot

The data is organized like this:
PJB: I would want  x1 y1  x2 y2 [colour]   all on one line

   point1a_x point1a_y color
   point1b_x point1b_y color

   point2a_x point2a_y color
   point2b_x point2b_y color
   (...)

   point2n_x point2n_y color
   point2n_x point2n_y color

The gnuplot is:

   plot 'edges.dat' u 1:2 with lines lc rgb "black" lw 2 notitle,\
  'edges.dat' u 1:2:(0.6) with circles fill solid lc rgb "black" notitle,\
  'edges.dat' using 1:2:($0) with labels tc rgb "white" offset (0,0) font 'Arial Bold' notitle

or

   plot 'edges.dat' u 1:2 with lines lc rgb "black" lw 2 notitle,\
   'edges.dat' u 1:2:(0.8) with circles linecolor rgb "white" lw 2 fill solid border lc lt 0 notitle, \
   'edges.dat' using 1:2:($0) with labels offset (0,0) font 'Arial Bold' notitle

Cluster-coloured graph:

   unset colorbox
   set palette model RGB defined ( 0 0 0 0 , 1 1 0 0 , 2 1 0.9 0, 3 0 1 0, 4 0 1 1 , 5 0 0 1 , 6 1 0 1 )
   plot 'edges.dat' u 1:2:3 with lines lc palette notitle,\
   'edges.dat' u 1:2:(0.15):3 with circles fill solid palette notitle

There is only one problem though... If the point have multiple lines,
it gets plotted twice and with different labels... Any workarounds? – 
rgcalsaverini  Dec 5 '13 at 17:44

The accepted answer didn't quite work out for me.
Here is how I had to change it: The format of the input file

  # A vertex has 3 fields: x coordinate, y coordnate and the label
  # An edge consists of two points in consecutive lines
  # There must be one or more blank lines between each edge.

  21.53 9.55 A
  24.26 7.92 B

  5.63 3.23 C
  2.65 1.77 D

  5.63 3.23 C
  4.27 7.04 E

#...

The big difference compared to the other answer is that
the labels belong to vertices, not edges.

Also note that I changed the labels to letters instead of numbers.
Labels can be any string and this makes it clearer that they are not
sequential indexes in the example.
The plotting command

  plot \
    'edges.dat' using 1:2       with lines lc rgb "black" lw 2 notitle,\
    'edges.dat' using 1:2:(0.6) with circles fill solid lc rgb "black" notitle,\
    'edges.dat' using 1:2:3     with labels tc rgb "white" offset (0,0) font 'Arial Bold' notitle

Big change here is that now when plotting the labels we plot
the 3rd field instead of the $0 field, which is a sequential number.

 gnuplot
 gnuplot> help plot datafile special

 The special filename '-' specifies that the data are inline; i.e., they
 follow the command.  Only the data follow the command; `plot` options
 like filters, titles, and line styles remain on the `plot` command line.
 This is similar to << in unix shell script.  The data are entered
 as though they are being read from a file, one data point per record.
 The letter "e" at the start of the first column terminates data entry.

 ( or could try '/dev/stdin' ... )



 https://staff.itee.uq.edu.au/ksb/howto/gnuplot-pdf-howto.html
 Gnuplot output to PDF (via eps).

  First, make a gnuplot "plot" file which uses "postscript" terminal output
  Although the new gnuplot supports pdf terminal output,
  it doesnt seem as full featured as the eps/pdf output.
  The important terminal lines are as follows:
   set terminal postscript portrait enhanced color dashed lw 1 "DejaVuSans" 12
   set output "temp.ps"
  Next run gnuplot on your plot file:
    gnuplot temp.plot
  Then convert the eps to pdf:
    epstopdf temp.ps
  Then use pdfcrop to make sure the bounding box is aligned with the output:
    pdfcrop temp.pdf; mv temp-crop.pdf temp.pdf

  This can all be done via a script (eg: save it as gnuplotcrop):
    #!/usr/bin
    bn=`basename $1 .plot`
    gnuplot $bn.plot
    epstopdf $bn.ps
    pdfcrop $bn.pdf
    mv $bn-crop.pdf $bn.pdf

  Then, just run gnuplotcrop file.plot
  - make sure the output is defined as file.ps inside this file.



=back

=head1 DOWNLOAD

This module is available at
https://pjb.com.au/comp/lua/spanning_tree.html

=head1 AUTHOR

Peter J Billam, https://pjb.com.au/comp/contact.html

=head1 SEE ALSO

 https://pjb.com.au/
 https://en.wikipedia.org/wiki/Prim%27s_algorithm
 https://stackoverflow.com/questions/20406346/how-to-plot-tree-graph-web-data-on-gnuplot
 https://staff.itee.uq.edu.au/ksb/howto/gnuplot-pdf-howto.html
 3D :
 http://hirophysics.com/gnuplot/gnuplot10.html
 http://lowrank.net/gnuplot/plotpm3d-e.html
 https://sites.science.oregonstate.edu/~landaur/nacphy/DATAVIS/gnuplot.html
 3D with mouse :
 https://stackoverflow.com/questions/17507727/rotating-3d-plots-with-the-mouse-in-multiplot-mode
   set terminal x11
   splot sin(x)
 http://gnuplot.sourceforge.net/docs_4.2/node201.html
 http://gnuplot.sourceforge.net/demo_canvas_5.2/

=cut


]=]
