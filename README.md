peprserv - A repository statistics server for pepper
====================================================

peprserv is a small web server that provides statistics and graphs
for source code repositories. It is implemented as a report script for 
[pepper](http://scm-pepper.sourceforge.net) and serves the output of
other reports via HTTP.

Current features include individual report configuration, caching of
report output and answering to HTTP HEAD requests. A live demo using
[the official Git repository](https://github.com/gitster/git)
is available at [http://jgehring.net:9000](http://jgehring.net:9000).


Dependencies
------------
-   [pepper](http://scm-pepper.sourceforge.net), version 0.3.1 or higher
-   [Xavante](http://keplerproject.github.com/xavante/)
-   optional: [lua-zlib](https://github.com/brimworks/lua-zlib) for output
    compression 


Quick-start
-----------
Install the dependencies, cd to the top-level peprserv directory and run

	$ pepper peprserv --config=config.lua --show-index $REPOSITORY

where $REPOSITORY is the path a source code repository. Afterwards,
point your browser to `http://localhost:8080`and check your console for
possible progress output.


Configuration
-------------
The script handles a number of command-line arguments to customize its
behaviour, but for full control you might want to use a configuration
file. The example configuration included in the package (`config.lua`)
should provide a good starting point.

While you're setting up the server, you can use the `--show-index` flag
to make the server provide a small HTML page that can be used to test
the current configuration.


Usage
-----
The program is a web server using HTTP, so you need a browser or something
similar to get data from it. Example given, if a report named `loc` is
offered, it is available at `/r/loc`. However, the intended use case
is acting as a backend for web sites, providing on-demand repository
statistics.  Thus, the program offers a small API containing the following
"functions" (i.e. URLs):

-   `/list` returns a JSON-formatted list with all offered report
     scripts. JSONP via `?callback=` is supported, too.
-   `/r/$REPORT` runs the respective report and returns its output

Individual report arguments can be append to an URL, like in
`/r/loc?branch=next`.  Arguments inside the URL take precedence over
those specified in the configuration file.


License
-------
peprserv - A repository statistics server for pepper
Copyright (C) 2012 Jonas Gehring

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the 
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.                                                                       
