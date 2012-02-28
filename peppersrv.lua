--[[
	peppersrv - A repository statistics server for pepper
	Copyright (C) 2012 Jonas Gehring

	Released under the GNU General Public License, version 3.
	Please see the COPYING file in the source distribution for license
	terms and conditions, or see http://www.gnu.org/licenses/.
--]]


require "json"
require "pepper.plotutils"
require "xavante"

-- Needed for debugging
require "xavante.filehandler"
require "xavante.redirecthandler"


-- Meta-data
function describe()
	local r = {}
	r.title = "peppersrv"
	r.description = "Repository statistics server"
	r.options = {
		{"-cARG, --config=ARG", "Load configuration from file ARG"},
		{"-rLIST, --reports=LIST", "Serve reports from comma-separated LIST"},
		{"-tARG, --type=ARG", "Set image type"},
		{"--show-index", "Show simple index page for debugging"},
		{"-hARG, --host=ARG", "Bind to host AGG (default 0.0.0.0)"},
		{"-pARG, --port=ARG", "Bind to port ARG (default 8080)"},
	}
	return r
end


-- Cache: report => {head, output}
local cache = {}

-- Configuration loaded from file
local config = {}

-- Image extension to mime type
local mime_types = {
	svg = "image/svg+xml",
	png = "image/png",
	jpg = "image/jpg",
	jpeg = "image/jpg",
	gif = "image/gif"
}

-- Wrapper for getopt()
function getopt(self, opt, default)
	for i,v in ipairs(pepper.utils.split(opt, ",")) do
		if config[v] then
			return config[v]
		end
	end
	if default then
		return self:getopt(opt, default)
	else
		return self:getopt(opt)
	end
end

-- Create HTTP errors of type 500 (server failure)
function error_500(req, res, err)
	res.statusline = "HTTP/1.1 500 Internal Server Error"
	res.headers ["Content-Type"] = "text/html"
	res.content = string.format([[
	<!DOCTYPE HTML PUBLIC "-//IETF//DTD HTML 2.0//EN">
	<HTML><HEAD>
	<TITLE>500 Internal Server Error</TITLE>
	</HEAD><BODY>
	<H1>Internal Server Error</H1>
	<P>The server encountered an error while trying to server %s:</P>
	<VERBATIM>%s</VERBATIM>
	</BODY></HTML>]], req.built_url, err);
	return res
end

-- Serves a report image
function serve(req, res, self, report)
	if req.cmd_mth ~= "GET" and req.cmd_mth ~= "HEAD" then
		return xavante.httpd.err_405(req, res)
	end

	-- Setup report options
	local options = {}
	local imgtype = string.lower(getopt(self, "t,type", "svg"))
	options["type"] = imgtype
	if config.reports and config.reports[report] then
		for k,v in pairs(config.reports[report]) do
			options[k] = tostring(v)
		end
	end

	local repo = self:repository()
	local head = repo:head()
	local date
	local status, out

	-- Run report if not cached yet
	if cache[report] == nil or cache[report][1] ~= head then
		status, out = pcall(pepper.run, report, options)
		if not status then
			return error_500(req, res, out)
		end
		date = repo:revision(head):date()
		cache[report] = {head, date, out}
	else
		date = cache[report][2]
		out = cache[report][3]
	end

	res.headers["Content-Type"] = mime_types[imgtype]
	res.headers["Last-Modified"] = os.date("!%a, %d %b %Y %H:%M:%S GMT", date)

	-- Answer to modification time quries
	-- TODO: Answer _before_ running the report
	local lms = req.headers["if-modified-since"] or 0
	local lm = res.headers["Last-Modified"] or 1
	if lms == lm then
		res.headers["Content-Length"] = 0
		res.statusline = "HTTP/1.1 304 Not Modified"
		res.content = ""
		res.chunked = false
		res:send_headers()
		return res
	end

	-- Serve file (or headers only)
	-- TODO: gzip compression for SVG files
	res.headers["Content-Length"] = #out
	if req.cmd_mth == "GET" then
		res.chunked = false
		res:send_data(out)
	else
		res.content = ""
		res:send_headers()
	end
	return res
end

-- Constructs a new serve() callback with bound arguments
function make_serve(args)
	return function(req, res)
		return serve(req, res, args.self, args.report)
	end
end

-- Listing function
function list(req, res, self, reports)
	local c = json.encode(reports)
	res.headers["Content-Type"] = "application/json"
	res.headers["Content-Length"] = #c
	res:send_data(c)
	return res
end

-- Constructs a listing callback with bound arguments
function make_list(args)
	return function(req, res)
		return list(req, res, args.self, args.reports)
	end
end

-- Report entry point
function main(self)
	-- Read configuration file
	local config_file = self:getopt("c,config")
	if config_file then
		config = require(config_file:gsub(".lua$", ""))
	end

	-- Check image type
	local imgtype = string.lower(getopt(self, "t,type", "svg"))
	if mime_types[imgtype] == nil then
		error("Unsupported image type: " .. imgtype)
	end

	-- Load report definitions
	local reports = {}
	if config and config.reports then
		reports = config.reports
	else
		local list = getopt(self, "r,reports", table.concat(pepper.list_reports(), ","))
		for i,v in ipairs(pepper.utils.split(list, ",")) do
			reports[v] = {}
		end
	end

	-- Setup URL patterns for reports
	local rules = {}
	local names = {}
	for k,v in pairs(reports) do
		local name = pepper.utils.basename(k):gsub(".lua$", "")
		local path = name
		if v and v.path then path = v.path end
		table.insert(rules, {match = "^/r/" .. name .. "$", with = make_serve, params = {self = self, report = path}})
		table.insert(names, path)
	end
	table.sort(names)

	-- Setup helper patters
	table.insert(rules, {
		match = "^/list$", with = make_list, params = {self = self, reports = names}
	})

	-- Show index page for debugging
	if getopt(self, "show-index") then
		table.insert(rules, {
			match = "/index.html", with = xavante.filehandler, params = {baseDir = "/home/jonas/webdevel/peppersrv"}
		})
		table.insert(rules, {
			match = ".", with = xavante.redirecthandler, params = {"index.html"}
		})
	end

	-- Start HTTP server
	xavante.HTTP{
		server = {host = getopt(self, "host", "0.0.0.0"),
		port = tonumber(getopt(self, "p,port", "8080"))},
		defaultHost = {
			rules = rules
		},
	}
	xavante.start()
end
