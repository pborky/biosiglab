function bsl_path(toolboxroot)
% BSL_PATH sets path to Biosignal Toolbox. 
%
% Synopsis:
%  bsl_path
%  bsl_path(toolboxroot)
%
% Description:
%  bsl_path(toolboxroot) sets path to the Biosignal 
%   Toolbox stored in given root directory toolboxroot.
%
%  bsl_path uses toolboxroot = pwd .
%


if nargin < 1
   toolboxroot=pwd;              % get current directory
end

disp('Adding path for the Statistical Pattern Recognition Toolbox...');

% path for UNIX
p = ['$:',...
     '$neurodata:',...
     '$neuroserver:',...
     '$external/somtoolbox:'
    ];

p=translate(p,toolboxroot);

% adds path at the start
addpath(p);
% add path for STPR Toolbox
stprpath(translate('$external/stprtool',toolboxroot));



%--translate ---------------------------------------------------------
function p = translate(p,toolboxroot);
%TRANSLATE Translate unix path to platform specific path
%   TRANSLATE fixes up the path so that it's valid on non-UNIX platforms
%
% This function was derived from MathWork M-file "pathdef.m"

cname = computer;
% Look for VMS, this covers VAX_VMSxx as well as AXP_VMSxx.
%if (length (cname) >= 7) & strcmp(cname(4:7),'_VMS')
%  p = strrep(p,'/','.');
%  p = strrep(p,':','],');
%  p = strrep(p,'$toolbox.','toolbox:[');
%  p = strrep(p,'$','matlab:[');
%  p = [p ']']; % Append a final ']'

% Look for PC
if strncmp(cname,'PC',2)
  p = strrep(p,'/','\');
  p = strrep(p,':',';');
  p = strrep(p,'$',[toolboxroot '\']);

% Look for MAC
%elseif strncmp(cname,'MAC',3)
%  p = strrep(p,':',':;');
%  p = strrep(p,'/',':');
%  m = toolboxroot;
%  if m(end) ~= ':'
%    p = strrep(p,'$',[toolboxroot ':']);
%  else
%    p = strrep(p,'$',toolboxroot);
%  end
else
  p = strrep(p,'$',[toolboxroot '/']);
end
