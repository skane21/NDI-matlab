% NDI_IODEVICE_MFDAQ - Multifunction DAQ object class
%
% The NDI_IODEVICE_MFDAQ object class.
%
% This object allows one to address multifunction data acquisition systems that
% sample a variety of data types potentially simultaneously. 
%
% The channel types that are supported are the following:
% Channel type (string):      | Description
% -------------------------------------------------------------
% 'analog_in'   or 'ai'       | Analog input
% 'analog_out'  or 'ao'       | Analog output
% 'digital_in'  or 'di'       | Digital input
% 'digital_out' or 'do'       | Digital output
% 'time'        or 't'        | Time
% 'auxiliary_in','aux' or 'ax'| Auxiliary channels
% 'event', or 'e'             | Event trigger (returns times of event trigger activation)
% 'mark', or 'mk'             | Mark channel (contains value at specified times)
% 
%
% See also: NDI_IODEVICE_MFDAQ/NDI_IODEVICE_MFDAQ
%

classdef ndi_iodevice_mfdaq < ndi_iodevice
	properties (GetAcces=public,SetAccess=protected)

	end
	properties (Access=private) % potential private variables
	end

	methods
		function obj = ndi_iodevice_mfdaq(varargin)
			% NDI_IODEVICE_MFDAQ - Create a new multifunction DAQ object
			%
			%  D = NDI_IODEVICE_MFDAQ(NAME, THEFILETREE)
			%
			%  Creates a new NDI_IODEVICE_MFDAQ object with NAME, and FILETREE.
			%  This is an abstract class that is overridden by specific devices.
			obj = obj@ndi_iodevice(varargin{:});
		end; % ndi_iodevice_mfdaq

		% functions that override ndi_epochset

                function ec = epochclock(ndi_iodevice_mfdaq_obj, epoch_number)
                        % EPOCHCLOCK - return the NDI_CLOCKTYPE objects for an epoch
                        %
                        % EC = EPOCHCLOCK(NDI_IODEVICE_MFDAQ_OBJ, EPOCH_NUMBER)
                        %
                        % Return the clock types available for this epoch as a cell array
                        % of NDI_CLOCKTYPE objects (or sub-class members).
			% 
			% For the generic NDI_IODEVICE_MFDAQ, this returns a single clock
			% type 'dev_local'time';
			%
			% See also: NDI_CLOCKTYPE
                        %
                                ec = {ndi_clocktype('dev_local_time')};
                end % epochclock

		function channels = getchannels(thedev)
			% FUNCTION GETCHANNELS - List the channels that are available on this device
			%
			%  CHANNELS = GETCHANNELS(THEDEV)
			%
			%  Returns the channel list of acquired channels in this experiment
			%
			%  The channels are of different types. In the below, 
			%  'n' is replaced with the channel number.
			%  Type       | Description
			%  ------------------------------------------------------
			%  ain        | Analog input (e.g., ai1 is the first input channel)
			%  din        | Digital input (e.g., di1 is the first input channel)
			%  t          | Time - a time channel
			%  axn        | Auxillary inputs
			%
			% CHANNELS is a structure list of all channels with fields:
			% -------------------------------------------------------
			% 'name'             | The name of the channel (e.g., 'ai1')
			% 'type'             | The type of data stored in the channel
			%                    |    (e.g., 'analog_input', 'digital_input', 'image', 'timestamp')
			%
			   % because this is an abstract class, only empty records are returned
				channels = struct('name',[],'type',[]);  
				channels = channels([]);
		end; % getchannels

		function data = readchannels_epochsamples(self, channeltype, channel, epoch, s0, s1)
			%  FUNCTION READ_CHANNELS - read the data based on specified channels
			%
			%  DATA = READ_CHANNELS(MYDEV, CHANNELTYPE, CHANNEL, EPOCH ,S0, S1)
			%
			%  CHANNELTYPE is the type of channel to read
			%
			%  CHANNEL is a vector of the channel numbers to read, beginning from 1
			%
			%  EPOCH is the epoch number to read from.
			%
			%  DATA will have one column per channel.
			%
			data = [];
		end % readchannels_epochsamples()

		function data = readchannels(self, channeltype, channel, timeref_or_epoch, t0, t1)
			%  FUNCTION READCHANNELS - read the data based on specified channels
			%
			%  DATA = READCHANNELS(MYDEV, CHANNELTYPE, CHANNEL, TIMEREF_OR_EPOCH, T0, T1)
			%
			%  CHANNELTYPE is the type of channel to read
			%  ('analog','digitalin','digitalout', etc)
			%  
			%  CHANNEL is a vector with the identity of the channels to be read.
			%  
			%  TIMEREF_OR_EPOCH is either an NDI_CLOCK object indicating the clock for T0, T1, or
			%  it can be a single number, which will indicate the data are to be read from that epoch.
			%
			%  DATA is the data collection for specific channels

			error('this function presently does not work, needs to know how to get to experiment');

			if isa(timeref_or_epoch,'ndi_timereference'),
				exp = self.experiment;
				[t0,epoch0_timeref] = exp.syncgraph.timeconvert(timeref_or_epoch,t0,...
					self,ndi_clocktype('devlocal'));
				[t1,epoch1_timeref] = exp.syncgraph.timeconvert(timeref_or_epoch,t1,...
					self,ndi_clocktype('dev_local_time'));
				if epoch0_timeref.epoch~=epoch1_timeref.epoch,
					error(['Do not know how to read across epochs yet; request spanned ' ...
						 self.filetree.epoch2str(epoch0_timeref.epoch) ...
						' and ' self.filetree.epoch2str(epoch1_timeref.epoch) '.']);
				end
				epoch = epoch0;
			else,
				epoch = timeref_or_epoch;
			end
			sr = samplerate(self, epoch, channeltype, channel);
			if numel(unique(sr))~=1,
				error(['Do not know how to handle multiple sampling rates across channels.']);
			end;
			sr = unique(sr);
			s0 = 1+round(sr*t0);
			s1 = 1+round(sr*t1);
			[data] = readchannels_epochsamples(self, epoch, channeltype, channel, s0, s1);
		end %readchannels()

		function data = readevents(self, channeltype, channel, timeref_or_epoch, t0, t1)
			%  FUNCTION READEVENTS - read events or markers of specified channels
			%
			%  DATA = READEVENTS(MYDEV, CHANNELTYPE, CHANNEL, TIMEREF_OR_EPOCH, T0, T1)
			%
			%  CHANNELTYPE is the type of channel to read
			%  ('event','marker', etc)
			%  
			%  CHANNEL is a vector with the identity of the channel(s) to be read.
			%  
			%  TIMEREF_OR_EPOCH is either an NDI_TIMEREFERENCE object indicating the clock for T0, T1, or
			%  it can be a single number, which will indicate the data are to be read from that epoch.
			%
			%  DATA is a two-column-per-channel vector; the first column has the time of the event. The second
			%  column indicates the marker code. In the case of 'events', this is just 1. If more than one channel
			%  is requested, DATA is returned as a cell array, one entry per channel.
			%

			if isa(timeref_or_epoch,'ndi_timereference'),
				tref = timeref_or_epoch;
				error(['this function does not handle working with clocks yet.']);
			else,
				epoch = timeref_or_epoch;
				%disp('here, about to call readchannels_epochsamples')
				[data] = readevents_epochsamples(self,channeltype,channel,epoch,t0,t1);
			end
		end % readevents

		function [data, timeref] = readevents_epochsamples(self, channeltype, channel, n, t0, t1)
			%  READEVENTS_EPOCHSAMPLES - read events or markers of specified channels for a specified epoch
			%
			%  [DATA, TIMEREF] = READEVENTS_EPOCHSAMPLES(MYDEV, CHANNELTYPE, CHANNEL, EPOCH, T0, T1)
			%
			%  CHANNELTYPE is the type of channel to read
			%  ('event','marker', etc)
			%  
			%  CHANNEL is a vector with the identity of the channel(s) to be read.
			%  
			%  EPOCH is the epoch number 
			%
			%  DATA is a two-column vector; the first column has the time of the event. The second
			%  column indicates the marker code. In the case of 'events', this is just 1. If more than one channel
			%  is requested, DATA is returned as a cell array, one entry per channel.
			%
			%  TIMEREF is an NDI_TIMEREFERENCE with the NDI_CLOCK of the device, referring to epoch N at time 0 as the reference.
			%  
			data = [];
			timeref = [];
		end % readevents_epochsamples

                function sr = samplerate(self, epoch, channeltype, channel)
			% SAMPLERATE - GET THE SAMPLE RATE FOR SPECIFIC CHANNEL
			%
			% SR = SAMPLERATE(DEV, EPOCH, CHANNELTYPE, CHANNEL)
			%
			% SR is an array of sample rates from the specified channels
			%
			% CHANNELTYPE can be either a string or a cell array of
			% strings the same length as the vector CHANNEL.
			% If CHANNELTYPE is a single string, then it is assumed that
			% that CHANNELTYPE applies to every entry of CHANNEL.
			% 
			% Note: in the abstract class NDI_IODEVICE_MFDAQ, this returns empty.
			sr = [];  % this is an abstract class
		end

		function [t_prime, epochnumber_prime] = timeconvert_old(self, clock, t, epochnumber)
			% TIMECONVERT - convert time to NDI_IODEVICE_MFDAQ 'dev_local_time'
			%
			%[T_PRIME, EPOCHNUMBER_PRIME] = TIMECONVERT(NDI_IODEVICE_MFDAQ_OBJ, CLOCK, T, [EPOCHNUMBER])
			%
			%Given an NDI_CLOCK CLOCK, a time T, and, if CLOCK is a 'dev_local_time' type of clock,
			%an EPOCHNUMBER, convert time to device's local 'dev_local_time' clock. EPOCHNUMBER_PRIME is the
			%epoch number in which time T occurs, and time T_PRIME is the time within the EPOCHNUMBER_PRIME when 
			%time T occurs.
			%
				ismyclock = 0;
				% is this clock already linked to my device??
				if isa(clock,'ndi_clock_iodevice'),
					if clock.device==self,
						ismyclock = 1;
					end
				end

				if ~ismyclock, % need to send out to sync table for conversion
					exp = self.experiment;
					myclock = ndi_clock_iodevice('dev_local_time',self); % MORE HERE
					if nargin<4,
						% [t1,epochnumber] = exp.synctable.timeconvert(clock, myclock, t); % more here!
					else,
						% [t1,epochnumber] = exp.synctable.timeconvert(clock, myclock, t, epochnumber); % more here!
					end
					return;
				end

				if isa(clock,'ndi_clock_iodevice_epoch'), % don't need epochnumber, we know it already
					t_prime = t;
					epochnumber_prime = clock.epoch;
					return
				end

				switch clock.type,
					case 'dev_local_time',
						t_prime = t;
						if nargin<4,
							error(['EPOCHNUMBER must be given if clock is type ''dev_local_time''.']);
						end
						epochnumber_prime = epochnumber; % must be given
					case 'no_time',
						t_prime = [];
						epochnumber_prime = [];
					case {'utc','exp_global_time','dev_global_time'},
						% need to get start and end time of each epoch, figure out which one has t
						error(['Do not know how to do this yet. More development needed.']);
				end
		end % timeconvert()
	end; % methods

	methods (Static), % functions that don't need the object
		function ct = mfdaq_channeltypes
			% MFDAQ_CHANNELTYPES - channel types for NDI_IODEVICE_MFDAQ objects
			%
			%  CT = MFDAQ_CHANNELTYPES - channel types for NDI_IODEVICE_MFDAQ objects
			%
			%  Returns a cell array of strings of supported channels of the
			%  NDI_IODEVICE_MFDAQ class. These are the following:
			%
			%  Channel type:       | Description: 
			%  -------------------------------------------------------------
			%  analog_in           | Analog input channel
			%  aux_in              | Auxiliary input
			%  analog_out          | Analog output channel
			%  digital_in          | Digital input channel
			%  digital_out         | Digital output channel
			%  marker              | 
			%
			% See also: NDI_IODEVICE_MFDAQ/MFDAQ_TYPE
			ct = { 'analog_in', 'aux_in', 'analog_out', 'digital_in', 'digital_out', 'marker', 'event', 'time' };
		end;

		function prefix = mfdaq_prefix(channeltype)
			% MFDAQ_PREFIX - Give the channel prefix for a channel type
			%
			%  PREFIX = MFDAQ_PREFIX(CHANNELTYPE)
			%
			%  Produces the channel name prefix for a given CHANNELTYPE.
			% 
			% Channel type:               | MFDAQ_PREFIX:
			% ---------------------------------------------------------
			% 'analog_in',       'ai'     | 'ai' 
			% 'analog_out',      'ao'     | 'ao'
			% 'digital_in',      'di'     | 'di'
			% 'digital_out',     'do'     | 'do'
			% 'time','timestamp','t'      | 't'
			% 'auxiliary','aux','ax',     | 'ax'
			%    'auxiliary_in'           | 
			% 'mark', 'marker', or 'mk'   | 'mk'
			% 'event' or 'e'              | 'e'
			%
			% See also: NDI_IODEVICE_MFDAQ/MFDAQ_TYPE
			%
				switch channeltype,
					case {'analog_in','ai'},
						prefix = 'ai';
					case {'analog_out','ao'},
						prefix = 'ao';
					case {'digital_in','di'},
						prefix = 'di';
					case {'digital_out','do'},
						prefix = 'do';
					case {'time','timestamp','t'},
						prefix = 't';
					case {'auxiliary','aux','ax','auxiliary_in'},
						prefix = 'ax';
					case {'marker','mark','mk'},
						prefix = 'mk';
					case {'event','e'},
						prefix = 'e';
				end;
		end % mfdaq_prefix()

		function type = mfdaq_type(channeltype)
			% MFDAQ_TYPE - Give the preferred long channel type for a channel type
			%
			%  TYPE = MFDAQ_TYPE(CHANNELTYPE)
			%
			%  Produces the preferred long channel type name for a given CHANNELTYPE.
			% 
			% Channel type:               | MFDAQ_TYPE:
			% ---------------------------------------------------------
			% 'analog_in',       'ai'     | 'analog_in' 
			% 'analog_out',      'ao'     | 'analog_out'
			% 'digital_in',      'di'     | 'digital_in'
			% 'digital_out',     'do'     | 'digital_out'
			% 'time','timestamp','t'      | 'time'
			% 'auxiliary','aux','ax',     | 'auxiliary'
			%    'auxiliary_in'           | 
			% 'mark', 'marker', or 'mk'   | 'mark'
			% 'event' or 'e'              | 'event'
			%
			% See also: NDI_IODEVICE_MFDAQ/MFDAQ_PREFIX
			%
				switch channeltype,
					case {'analog_in','ai'},
						type = 'analog_in';
					case {'analog_out','ao'},
						type = 'analog_out';
					case {'digital_in','di'},
						type = 'digital_in';
					case {'digital_out','do'},
						type = 'digital_out';
					case {'time','timestamp','t'},
						type = 'time';
					case {'auxiliary','aux','ax','auxiliary_in'},
						type = 'ax';
					case {'marker','mark','mk'},
						type = 'mark';
					case {'event','e'},
						type = 'event';
				end;
		end 
	
	end % methods (Static)
end
