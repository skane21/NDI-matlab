function exp = ndi_marderlab_makedev(exp, devname)
% NDI_MARDERLAB_MAKEDEV - initialize devices used by MARDERLAB
%
% EXP = NDI_MARDERLAB_MAKEDEV(EXP, DEVNAME)
%
% Creates devices that look for files in the MARDERLAB standard recording
% scheme, where data from different epochs are organized into
% subdirectories (using NDI_FILENAVIGATOR_EPOCHDIR). DEVNAME should be the 
% name a device in the table below. These devices are added to the NDI_SESSION
% object EXP. If DEVNAME is a cell list of strings, then multiple items are added.
%
% If the function is called with no input arguments, then it returns a list
% of all valid device names.
% 
% Each epoch is defined by the presence specific files that are needed by each
% device as described below.
%
% Devices created    | Description
% ----------------------------------------------------------------
% marder_ced         |  ndi_daqsystem_multichannel_mfdaq that looks for
%                    |    files '[something].smr' and
%                    |    '[something].epochprobemap.txt'
%
% See also: NDI_FILENAVIGATOR_EPOCHDIR

if nargin == 0,
	exp = {'marder_ced'};
	return;
end;

if iscell(devname),
	for i=1:length(devname),
		exp = ndi_marderlab_makedev(exp, devname{i});
	end
	return;
end

fileparameters = {};
objectclass = 'ndi_daqsystem_mfdaq';
readerobjectclass = 'ndi_daqreader_mfdaq';
epochprobemapclass = 'ndi_epochprobemap_daqsystem';

switch devname,
	case 'marder_ced',
		fileparameters{end+1} = '#\.smr\>';
		fileparameters{end+1} = '#\.epochprobemap.txt\>'; 
		readerobjectclass = [readerobjectclass '_cedspike2'];
		epochprobemapfileparameters = {'(.*)epochprobemap.txt'};
	otherwise,
		error(['Unknown device requested ' devname '.']);

end

ft = ndi_filenavigator(exp, fileparameters, epochprobemapclass, epochprobemapfileparameters);

eval(['dr = ' readerobjectclass '();']);

eval(['mydev = ' objectclass '(devname, ft, dr );']);

exp = exp.daqsystem_add(mydev);
