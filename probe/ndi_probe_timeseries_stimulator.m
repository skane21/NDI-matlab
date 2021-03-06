classdef ndi_probe_timeseries_stimulator < ndi_probe_timeseries
% NDI_PROBE_TIMESERIES_STIMULATOR - Create a new NDI_PROBE_TIMESERIES_STIMULATOR class object that handles probes that are associated with NDI_DAQSYSTEM_STIMULUS objects
%
	properties (GetAccess=public, SetAccess=protected)
	end

	methods
		function obj = ndi_probe_timeseries_stimulator(varargin)
			% NDI_PROBE_TIMESERIES_STIMULATOR - create a new NDI_PROBE_TIMESERIES_STIMULATOR object
			%
			% OBJ = NDI_PROBE(SESSION, NAME, REFERENCE, TYPE)
			%
			% Creates an NDI_PROBE_TIMESERIES_STIMULATOR associated with an NDI_SESSION object SESSION and
			% with name NAME (a string that must start with a letter and contain no white space),
			% reference number equal to REFERENCE (a non-negative integer), the TYPE of the
			% probe (a string that must start with a letter and contain no white space).
			%
				obj = obj@ndi_probe_timeseries(varargin{:});
		end % ndi_probe_timeseries_stimulator()

		function [data, t, timeref] = readtimeseriesepoch(ndi_probe_timeseries_stimulator_obj, epoch, t0, t1)
			% READ_STIMULUSEPOCH - Read stimulus data from an NDI_PROBE_TIMESERIES_STIMULATOR object
			%
			% [DATA, T, TIMEREF] = READTIMESERIESEPOCH(NDI_PROBE_TIMESERIES_STIMULATOR_OBJ, EPOCH, T0, T1)
			%  STIMON, STIMOFF, STIMID, PARAMETERS, STIMOPENCLOSE] = ...
			%    READSTIMULUSEPOCH(NDI_PROBE_STIMULTOR_OBJ, EPOCH, T0, T1)
			%
			% Reads stimulus delivery information from an NDI_PROBE_TIMESERIES_STIMULATOR object for a given EPOCH.
			% T0 and T1 are in epoch time.
			%
			% T.STIMON is an Nx1 vector with the ON times of each stimulus delivery in the time units of
			%    the epoch or the clock.
			% T.STIMOFF is an Nx1 vector with the OFF times of each stimulus delivery in the time units of
			%    the epoch or the clock. If STIMOFF data is not provided, these values will be NaN.
			% DATA.STIMID is an Nx1 vector with the STIMID values. If STIMID values are not provided, these values
			%    will be NaN.
			% DATA.PARAMETERS is an Nx1 cell array of stimulus parameters. If the device provides no parameters,
			%    then this will be an empty cell array of size Nx1.
			% T.STIMOPENCLOSE is an Nx2 vector of stimulus 'setup' and 'shutdown' times, if applicable. For example,
			%    a visual stimulus might begin or end with the presentation of a 'background' image. These times will
			%    be encoded here. If there is no information about stimulus setup or shutdown, then 
			%    T.STIMOPENCLOSE == [T.STIMON T.STIMOFF].
			% 
			% TIMEREF is an NDI_TIMEREFERENCE object that refers to this EPOCH.
			%
			% See also: NDI_PROBE_TIMESERIES/READTIMESERIES
			%
				[dev,devname,devepoch,channeltype,channel]=ndi_probe_timeseries_stimulator_obj.getchanneldevinfo(epoch);
				eid = ndi_probe_timeseries_stimulator_obj.epochid(epoch);

				if numel(unique(devname))>1, error(['Right now, all channels must be on the same device.']); end;
					% developer note: it would be pretty easy to extend this, just loop over the devices
				[edata] = readevents(dev{1},channeltype,channel,devepoch{1},t0,t1);
				if ~iscell(edata),
					edata = {edata};
				end;
				channel_labels = getchannels(dev{1});
				for i=1:numel(channeltype),
					switch channel_labels(i).name,
						case 'mk1', % stimonoff
							%edata{i},
							t.stimon = edata{i}(find(edata{i}(:,2)==1),1);
							t.stimoff = edata{i}(find(edata{i}(:,2)==-1),1);
						case 'mk2',
							data.stimid = edata{i}(:,2);
						case 'mk3',
							% ASSUMPTION: the number of off events will be the same size as the on events; 
							%   might not be true if a recording is cut-off mid presentation
							t.stimopenclose(:,1) = edata{i}( find(edata{i}(:,2)==1) , 1); 
							t.stimopenclose(:,2) = edata{i}( find(edata{i}(:,2)==-1) , 1); 
						case {'e1','e2','e3'}, % not saved
						otherwise,
							error(['Unknown channel.']);
					end
				end
				data.parameters = get_stimulus_parameters(dev{1},devepoch{1});

				timeref = ndi_timereference(ndi_probe_timeseries_stimulator_obj, ndi_clocktype('dev_local_time'), eid, 0);

		end %readtimeseriesepoch()
	end; % methods
end


