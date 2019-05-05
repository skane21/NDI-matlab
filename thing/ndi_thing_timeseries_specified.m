classef ndi_thing_timeseries_specified < ndi_thing_timeseries
% NDI_THING - define or examine a thing in the experiment
%
	properties (SetAccess=protected, GetAccess=public)

	end % properties

	methods
		function ndi_thing_timeseries_obj = ndi_thing_timeseries(thing_name, ndi_probe_obj)
			if ~isa(ndi_probe_obj, 'ndi_probe'),
				error(['NDI_PROBE_OBJ must be of type NDI_PROBE']);
			end;
			ndi_thing_obj.name = ndi_probe_obj.thing_name;
			ndi_thing_obj.probe = ndi_probe_obj;
		end; % ndi_thing_timeseries()

	% NDI_THING_TIMESERIES methods

		function [data, t, timeref] = readtimeseries(ndi_thing_timeseries_obj, timeref_or_epoch, t0, t1)
			%  READTIMESERIES - read the NDI_THING_TIMESERIES data from a probe based on specified time relative to an NDI_TIMEFERENCE or epoch
			%
			%  [DATA, T, TIMEREF] = READTIMESERIES(NDI_THING_TIMESERIES_OBJ, TIMEREF_OR_EPOCH, T0, T1)
			%
			%  Reads timeseries data from an NDI_THING_TIMESERIES object. The DATA and time information T that are
			%  returned depend on the the specific subclass of NDI_THING_TIMESERIES that is called (see READTIMESERIESEPOCH).
			%
			%  In the base class, this function merely calls the thing's probe's READTIMESERIES function. 
			%  TIMEREF_OR_EPOCH is either an NDI_TIMEREFERENCE object indicating the time reference for
			%  T0, T1, or it can be a single number, which will indicate the data are to be read from that
			%  epoch.
			%
			%  DATA is the data for the probe.  T is a time structure, in units of TIMEREF if it is an
			%  NDI_TIMEREFERENCE object or in units of the epoch if an epoch is passed.  The TIMEREF is returned.
			%
				
				if isa(timeref_or_epoch,'ndi_timereference'),
					timeref = timeref_or_epoch;
				else,
					timeref = ndi_timereference(ndi_thing_timeseries_obj, ndi_clocktype('dev_local_time'), timeref_or_epoch, 0);
				end;

				[epoch_t0_out, epoch_timeref, msg] = ndi_probe_timeseries_obj.experiment.syncgraph.time_convert(timeref, t0, ndi_probe_timeseries_obj, ndi_clocktype('dev_local_time'));
				[epoch_t1_out, epoch_timeref, msg] = ndi_probe_timeseries_obj.experiment.syncgraph.time_convert(timeref, t1, ndi_probe_timeseries_obj, ndi_clocktype('dev_local_time'));

				epoch = epoch_timeref.epoch;

				if nargin <2,  % some readtimeseriesepoch() methods may be able to save time if the time information is not requested
					[data] = ndi_probe_timeseries_obj.readtimeseriesepoch(epoch, epoch_t0_out, epoch_t1_out);
				else,
					[data,t] = ndi_probe_timeseries_obj.readtimeseriesepoch(epoch, epoch_t0_out, epoch_t1_out);
					% now need to convert t back to timeref units
					if isnumeric(t),
						t = ndi_probe_timeseries_obj.experiment.syncgraph.time_convert(epoch_timeref, t, timeref.referent, timeref.clocktype);
					elseif isstruct(t),
						fn = fieldnames(t);
						for i=1:numel(fn),
							t = setfield(t, fn{i}, ndi_probe_timeseries_obj.experiment.syncgraph.time_convert(epoch_timeref, ...
								getfield(t,fn{i}), timeref.referent, timeref.clocktype));
						end
					end;
				end;

				[data,t,timeref] = ndi_thing_timeseries_obj.probe.readtimeseries(timeref_or_epoch, t0, t1);
		end %readtimeseries()

	end; % methods

end % classdef

