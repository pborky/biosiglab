% TCP client for neuroserver
%
% edfdata       - method obtaining headers and data from neuroserver
% edfheader     - method obtaining headers from neuroserver
% edfstatus     - method initializing some data structs
% edfwatch      - method retrieving data for given time
% neuroclient   - low level communication function
% neuroclientwrapper - wrapper with error handlers
% socketclose   - method cleaning up TCP socket
% 
% About: Bio Signal Lab
% (C) 2011, Written by Peter Boraros
% <a href="http://www.pborky.sk">Peter Boraros</a>
% <a href="https://github.com/pborky/biosiglab">Git Repo</a>