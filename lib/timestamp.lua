---------------------------------------------------------------------
--     This Lua5 module is Copyright (c) 2020, Peter J Billam      --
--                         pjb.com.au                              --
--  This module is free software; you can redistribute it and/or   --
--         modify it under the same terms as Lua5 itself.          --
---------------------------------------------------------------------
-- Example usage:
-- local MM = require 'mymodule'
-- MM.foo()

local M = {} -- public interface
M.Version = '1.0'
M.VersionDate = '3feb2020'

------------------------------ private ------------------------------
function warn(...)
    local a = {}
    for k,v in pairs{...} do table.insert(a, tostring(v)) end
    io.stderr:write(table.concat(a),'\n') ; io.stderr:flush()
end
function die(...) warn(...);  os.exit(1) end
function qw(s)  -- t = qw[[ foo  bar  baz ]]
    local t = {} ; for x in s:gmatch("%S+") do t[#t+1] = x end ; return t
end

------------------------------ public ------------------------------

function M.timestamp ()
   -- returns current date and time in "199403011 113520" format
   return(os.date("%Y%m%d %H%M%S"))
end
function M.datestamp ()
   -- returns current date in "19940311" format
   return(os.date("%Y%m%d"))
end

print(M.timestamp())
print(M.datestamp())

--[[
function M.neatdate ()
   -- converts "940311" or "19940311" to "11mar1994", or "9403" to "mar1994"
   local ($date, $yy, $mm, $dd, $mon);
   $date = shift(@_);
   $date =~ s/^9/199/;
   ($yy, $mm, $dd) = $date =~ /(\d\d\d\d)(\d\d)((\d\d)?)/;
   $mon = ("jan","feb","mar","apr","may","jun",
           "jul","aug","sep","oct","nov","dec")[$mm - 1];
   $dd =~ s/^0/ /;
   if ($dd) then return ("$dd$mon$yy")
   elseif ($mm) then return ("$mon$yy")
   else return ($date) end
end
--]]

return M

--[=[

=pod

=head1 NAME

mymodule.lua - does whatever

=head1 SYNOPSIS

 local M = require 'mymodule'
 a = { 6,8,7,9,8 }
 b = { 4,7,5,4,5,6,4 }
 local probability_of_hypothesis_being_wrong = M.ttest(a,b,'b>a')

=head1 DESCRIPTION

This module does whatever

=head1 FUNCTIONS

=over 3

=item I<ttest(a,b, hypothesis)>

The arguments I<a> and I<b> are arrays of numbers

The I<hypothesis> can be one of 'a>b', 'a<b', 'b>a', 'b<a',
'a~=b' or 'a<b'.

I<ttest> returns the probability of your hypothesis being wrong.

=back

=head1 DOWNLOAD

This module is available at
http://pjb.com.au/comp/lua/mymodule.html

=head1 AUTHOR

Peter J Billam, http://pjb.com.au/comp/contact.html

=head1 SEE ALSO

 http://pjb.com.au/


=cut

]=]

