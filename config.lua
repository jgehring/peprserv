--[[
	Example configuration for peprsrv
--]]


local options = {

-- General options
port = 8080,         -- Default port is 8080
host = "0.0.0.0",    -- Accept connections from everywhere
type = "svg",        -- Generate SVG images by default
check-head = 60,     -- Check for new repository head after 60 seconds

-- Report definitions with report-specific options
reports = {
	authors = {                 -- This report will be available at /r/authors
		path = "authors",       -- Report path, defaults to entry name
		n = 4,                  -- Show contributions of 4 busiest authors
		tags = "^v",            -- Show tags starting with 'v'
	},

	loc = {                     -- No extra options for /r/loc
	},

	filetypes = {               -- /r/filetypes
		type = "png",           -- Generate a PNG image for this report
		size = "500x500",       -- Image size
		pie = true,             -- Generate a pie chart
	}
},

} -- End of options

return options
