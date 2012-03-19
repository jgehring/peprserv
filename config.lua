--[[
	Example configuration for peprsrv
--]]


local options = {

-- General options
port = 8080,         -- Default port is 8080
host = "0.0.0.0",    -- Accept connections from everywhere
type = "svg",        -- Generate SVG images by default
["check-head"] = 60,     -- Check for new repository head after 60 seconds

-- Report definitions with report-specific options
reports = {
	authors = {                 -- This report will be available at /r/authors
		_path = "authors",      -- Report path, defaults to entry name
		n = 4,                  -- Show contributions of 4 busiest authors
		tags = "^v",            -- Show tags starting with 'v'
	},

	loc = {                     -- No extra options for /r/loc
	},

	filetypes_pie = {           -- /r/filetypes
		_path = "filetypes",    -- Run the "filetypes" report
		type = "png",           -- Generate a PNG image for this report
		size = "620x500",       -- Image size
		pie = true,             -- Generate a pie chart
	},

	-- These are the other graphical reports, without any extra options
	activity = { },
	authors_pie = { },
	commit_counts = { },
	directories = { },
	filetypes = { },
	-- participation = { }, -- disabled, as author argument is mandatory
	punchcard = { },
	times = { },
	volume = { },
},

} -- End of options

return options
