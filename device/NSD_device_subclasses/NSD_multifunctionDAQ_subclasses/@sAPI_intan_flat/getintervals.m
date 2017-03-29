function [intervals] = getintervals(sAPI_dev)
%   FUNCTION GETINTERVALS - list the relative time order for all the
%   intervals
%
%   INTERVALS = GETINTERVALS(SAPI_DEV)
%
%   Returns the orders for all the intervals related to the experiment
%
%   INTERVALS = {f1,order1
%                f2,order2
%                f3,order3....}

intervals = struct('file',[],'local_epoch_order',[]);
intervals = ([]);

filelist = findfiletype(getpath(getexperiment(sAPI_dev)),'rhd');
    for i=1:length(filelist),
        temp = read_Intan_RHD2000_header(filelist{i});
        intervals(end+1).file = temp.fileinfo.filename;
        intervals(end).local_epoch_order = i;            % desired implementation: need to use multiple filenames to make comparsion and get the order list
    end
return;


% intervals = [];
% for (i <= size(device.stim_times,1) )
% intervals(:,1) = device.stim_times(,2);
% intervals(:,2) = device.stim_times(,3) - device.stim_times(,2);
% intervals(:,3) = device.voltageForTime;
