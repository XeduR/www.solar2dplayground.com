-- Simple function that finds specific (escape) characters from a file
-- and outputs a single line string that can be used in a JSON file.
-- (Note: This file and its folder are excluded in build.settings.)

-- How to use:
-- 1) Change the path/filename below.
-- 2) Open main.lua with Solar2D and check console output.

local path = system.pathForFile( "input.lua" )
local file, errorString
if path then
    file, errorString = io.open( path, "r" )
end
 
if not file then
    print( "File error: " .. (errorString and errorString or "path or filename is incorrect.") )
else
    local contents = file:read( "*a" )
    local contents = contents:gsub( "\t", "\\t" )
    local contents = contents:gsub( "\n", "\\n" )
    local contents = contents:gsub( "\v", "\\v" )
    local contents = contents:gsub( "\r", "\\r" )
    local contents = contents:gsub( "    ", "\\t" )
    -- local contents = contents:gsub( "\'", "\\'" )
    local contents = contents:gsub( "\"", "\\\"" )
    contents = "\"" .. contents .. "\""
    
    print( "\v" .. contents )
    io.close( file )
end
 
file = nil