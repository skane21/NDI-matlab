% NDI_DAQREADER_MFDAQ_INTAN - Device driver for Intan Technologies RHD file format
%
% This class reads data from Intan Technologies .RHD file format.
%
% Intan Technologies: http://intantech.com/
%
%

classdef ndi_daqreader_mfdaq_intan < ndi_daqreader_mfdaq
	properties
		

	end % properties

	methods
		function obj = ndi_daqreader_mfdaq_intan(varargin)
		% NDI_DAQREADER_MFDAQ_INTAN - Create a new NDI_DEVICE_MFDAQ_INTAN object
		%
		%  D = NDI_DAQREADER_MFDAQ_INTAN(NAME,THEFILENAVIGATOR)
		%
		%  Creates a new NDI_DAQREADER_MFDAQ_INTAN object with name NAME and associated
		%  filenavigator THEFILENAVIGATOR.
		%
			obj = obj@ndi_daqreader_mfdaq(varargin{:})
		end

		function channels = getchannelsepoch(ndi_daqreader_mfdaq_intan_obj, epochfiles)
		% GETCHANNELSEPOCH - List the channels that are available on this Intan device for a given set of files
		%
		%  CHANNELS = GETCHANNELSEPOCH(NDI_DAQREADER_MFDAQ_INTAN_OBJ, EPOCHFILES)
		%
		%  Returns the channel list of acquired channels in this session
		%
		% CHANNELS is a structure list of all channels with fields:
		% -------------------------------------------------------
		% 'name'             | The name of the channel (e.g., 'ai1')
		% 'type'             | The type of data stored in the channel
		%                    |    (e.g., 'analogin', 'digitalin', 'image', 'timestamp')
		%

			channels = emptystruct('name','type');

			intan_channel_types = {
				'amplifier_channels'
				'aux_input_channels'
				'board_dig_in_channels'
				'board_dig_out_channels'};

			multifunctiondaq_channel_types = ndi_daqsystem_mfdaq.mfdaq_channeltypes;

			% open RHD files, and examine the headers for all channels present
			%   for any new channel that hasn't been identified before,
			%   add it to the list

			filename = ndi_daqreader_mfdaq_intan_obj.filenamefromepochfiles(epochfiles); 
			header = read_Intan_RHD2000_header(filename);

			for k=1:length(intan_channel_types),
				if isfield(header,intan_channel_types{k}),
					channel_type_entry = ndi_daqreader_mfdaq_intan_obj.intanheadertype2mfdaqchanneltype(...
							intan_channel_types{k});
					channel = getfield(header, intan_channel_types{k});
					num = numel(channel);             %% number of channels with specific type
					for p = 1:numel(channel),
						newchannel.type = channel_type_entry;
						newchannel.name = ndi_daqreader_mfdaq_intan_obj.intanname2mfdaqname(...
							ndi_daqreader_mfdaq_intan_obj,...
							channel_type_entry,...
							channel(p).native_channel_name); 
						channels(end+1) = newchannel;
					end
				end
			end
		end % getchannels()

		function [b,msg] = verifyepochprobemap(ndi_daqreader_mfdaq_intan_obj, epochprobemap, epochfiles)
		% VERIFYEPOCHPROBEMAP - Verifies that an EPOCHPROBEMAP is compatible with a given device and the data on disk
		%
		%   B = VERIFYEPOCHPROBEMAP(NDI_DAQREADER_MFDAQ_INTAN_OBJ, EPOCHPROBEMAP, EPOCHFILES)
		%
		% Examines the NDI_EPOCHPROBEMAP_DAQREADER EPOCHPROBEMAP and determines if it is valid for the given device
		% with epoch files EPOCHFILES.
		%
		% See also: NDI_DAQREADER, NDI_EPOCHPROBEMAP_DAQREADER
			b = 1;
			msg = '';
			% UPDATE NEEDED
		end

		function filename = filenamefromepochfiles(ndi_daqreader_mfdaq_intan_obj, filename)
			s1 = ['.*\.rhd\>']; % equivalent of *.ext on the command line
			[tf, matchstring, substring] = strcmp_substitution(s1,filename,'UseSubstituteString',0);
			index = find(tf);
			if numel(index)> 1,
				error(['Need only 1 .rhd file per epoch.']);
			elseif numel(index)==0,
				error(['Need 1 .rhd file per epoch.']);
			else,
				filename = filename{index}; 
			end
		end % filenamefromepoch

		function data = readchannels_epochsamples(ndi_daqreader_mfdaq_intan_obj, channeltype, channel, epochfiles, s0, s1)
		%  FUNCTION READ_CHANNELS - read the data based on specified channels
		%
		%  DATA = READ_CHANNELS(MYDEV, CHANNELTYPE, CHANNEL, EPOCHFILES ,S0, S1)
		%
		%  CHANNELTYPE is the type of channel to read (cell array of strings, one per channel)
		%
		%  CHANNEL is a vector of the channel numbers to read, beginning from 1
		%
		%  EPOCH is set of epoch files
		%
		%  DATA is the channel data (each column contains data from an indvidual channel) 
		%
			filename = ndi_daqreader_mfdaq_intan_obj.filenamefromepochfiles(epochfiles); 

			uniquechannel = unique(channeltype);
			if numel(uniquechannel)~=1,
				error(['Only one type of channel may be read per function call at present.']);
			end
			intanchanneltype = ndi_daqreader_mfdaq_intan_obj.mfdaqchanneltype2intanchanneltype(uniquechannel{1});

			sr = ndi_daqreader_mfdaq_intan_obj.samplerate(epochfiles, channeltype, channel);
			sr_unique = unique(sr); % get all sample rates
			if numel(sr_unique)~=1,
				error(['Do not know how to handle different sampling rates across channels.']);
			end;

			sr = sr_unique;

			t0 = (s0-1)/sr;
			t1 = (s1-1)/sr;
			[data] = read_Intan_RHD2000_datafile(filename,'',intanchanneltype,channel,t0,t1);

		end % readchannels_epochsamples

		function sr = samplerate(ndi_daqreader_mfdaq_intan_obj, epochfiles, channeltype, channel)
			% SAMPLERATE - GET THE SAMPLE RATE FOR SPECIFIC EPOCH AND CHANNEL
			%
			% SR = SAMPLERATE(DEV, EPOCHFILES, CHANNELTYPE, CHANNEL)
			% CHANNELTYPE can be either a string or a cell array of
			% strings the same length as the vector CHANNEL.
			% If CHANNELTYPE is a single string, then it is assumed that
			% that CHANNELTYPE applies to every entry of CHANNEL.
			%
			% SR is the list of sample rate from specified channels
			%
				sr = [];
				filename = ndi_daqreader_mfdaq_intan_obj.filenamefromepochfiles(epochfiles); 

				head = read_Intan_RHD2000_header(filename);
				for i=1:numel(channel),
					channeltype_here = celloritem(channeltype,i);
					freq_fieldname = ndi_daqreader_mfdaq_intan_obj.mfdaqchanneltype2intanfreqheader(channeltype_here);
					sr(i) = getfield(head.frequency_parameters,freq_fieldname);
				end
		end % samplerate()

		function t0t1 = t0_t1(ndi_daqreader_mfdaq_intan_obj, epochfiles)
			% EPOCHCLOCK - return the t0_t1 (beginning and end) epoch times for an epoch
			%
			% T0T1 = T0_T1(NDI_EPOCHSET_OBJ, EPOCHFILES)
			%
			% Return the beginning (t0) and end (t1) times of the epoch EPOCH_NUMBER
			% in the same units as the NDI_CLOCKTYPE objects returned by EPOCHCLOCK.
			%
			% The abstract class always returns {[NaN NaN]}.
			%
			% See also: NDI_CLOCKTYPE, EPOCHCLOCK
			%
				filename = ndi_daqreader_mfdaq_intan_obj.filenamefromepochfiles(epochfiles); 

				header = read_Intan_RHD2000_header(filename);

				[blockinfo, bytes_per_block, bytes_present, num_data_blocks] = Intan_RHD2000_blockinfo(filename, header);

				total_samples = 60 * num_data_blocks;
				total_time = total_samples / header.frequency_parameters.amplifier_sample_rate; % in seconds

				t0 = 0;
				t1 = total_time-1/header.frequency_parameters.amplifier_sample_rate;

				t0t1 = {[t0 t1]};
					% developer note: in the Intan acquisition software, one can define a time offset; right now we aren't considering that
		end % t0t1

	end % methods

	methods (Static)  % helper functions

		function intanchanheadertype = mfdaqchanneltype2intanheadertype(channeltype)
		% MFDAQCHANNELTYPE2INTANHEADERTYPE - Convert between the NDI_DAQREADER_MFDAQ channel types and Intan headers
		%
		% INTANCHANHEADERTYPE = MFDAQCHANNELTYPE2INTANHEADERTYPE(CHANNELTYPE)
		% 
		% Given a standard NDI_DAQREADER_MFDAQ channel type, returns the name of the type as
		% indicated in Intan header files.

			switch (channeltype),
				case {'analog_in','ai'},
					intanchanheadertype = 'amplifier_channels';
				case {'digital_in','di'}
					intanchanheadertype = 'board_dig_in_channels';
				case {'digital_out','do'},
					intanchanheadertype = 'board_dig_out_channels';
				case {'auxiliary','aux','ax','auxiliary_in','auxiliary_input'},
					intanchanheadertype = 'aux_input_channels';
				otherwise,
					error(['Could not convert channeltype ' channeltype '.']);
			end;

		end % mfdaqchanneltype2intanheadertype()

		function channeltype = intanheadertype2mfdaqchanneltype(intanchanneltype)
		% INTANHEADERTYPE2MFDAQCHANNELTYPE- Convert between Intan headers and the NDI_DAQREADER_MFDAQ channel types 
		%
		% CHANNELTYPE = INTANHEADERTYPE2MFDAQCHANNELTYPE(INTANCHANNELTYPE)
		% 
		% Given an Intan header file type, returns the standard NDI_DAQREADER_MFDAQ channel type

			switch (intanchanneltype),
				case {'amplifier_channels'},
					channeltype = 'analog_in';
				case {'board_dig_in_channels'},
					channeltype = 'digital_in';
				case {'board_dig_out_channels'},
					channeltype = 'digital_out';
				case {'aux_input_channels'},
					channeltype = 'auxiliary_in';
				otherwise,
					error(['Could not convert channeltype ' intanchanneltype '.']);
			end;

		end % mfdaqchanneltype2intanheadertype()

		function intanchanneltype = mfdaqchanneltype2intanchanneltype(channeltype)
		% MFDAQCHANNELTYPE2INTANCHANNELTYPE- convert the channel type from generic format of multifuncdaqchannel 
		%					 to the specific intan channel type
		%
		%    INTANCHANNELTYPE = MFDAQCHANNELTYPE2INTANCHANNELTYPE(CHANNELTYPE)
		%
		%	 the intanchanneltype is a string of the specific channel type for intan
		%
			switch channeltype, 
				case {'analog_in','ai'},
					intanchanneltype = 'amp';
				case {'digital_in','di'},
					intanchanneltype = 'din';
				case {'digital_out','do'},
					intanchanneltype = 'dout';
				case {'time','timestamp'},
					intanchanneltype = 'time';
				case {'auxiliary','aux','auxiliary_input','auxiliary_in'},
					intanchanneltype = 'aux';
				otherwise,
					error(['Do not know how to convert channel type ' channeltype '.']);
			end
		end % mfdaqchanneltype2intanchanneltype()

		function [ channame ] = intanname2mfdaqname(ndi_daqreader_mfdaq_intan_obj, type, name )
		% INTANNAME2MFDAQNAME - Converts a channel name from Intan native format to NDI_DAQREADER_MFDAQ format.
		%
		% MFDAQNAME = INTANNAME2MFDAQNAME(NDI_DAQREADER_MFDAQ_INTAN, MFDAQTYPE, NAME)
		%   
		% Given an Intan native channel name (e.g., 'A-000') in NAME and a
		% NDI_DAQREADER_MFDAQ channel type string (see NDI_DEVICE_MFDAQ), this function
		% produces an NDI_DAQREADER_MFDAQ channel name (e.g., 'ai1').
		%  
			sep = find(name=='-');
			chan_intan = str2num(name(sep+1:end));
			chan = chan_intan + 1; % intan numbers from 0
			channame = [ndi_daqsystem_mfdaq.mfdaq_prefix(type) int2str(chan)];

		end % intanname2mfdaqname()

		function headername = mfdaqchanneltype2intanfreqheader(channeltype)
		% MFDAQCHANNELTYPE2INTANFREQHEADER - Return header name with frequency information for channel type
		%
		%  HEADERNAME = MFDAQCHANNELTYPE2INTANFREQHEADER(CHANNELTYPE)
		%
		%  Given an NDI_DEV_MFDAQ channel type string, this function returns the associated fieldname
		%  
			switch channeltype,
				case {'analog_in','ai'},
					headername = 'amplifier_sample_rate';
				case {'digital_in','di'},
					headername = 'board_dig_in_sample_rate';
				case {'digital_out','do'},
					headername = 'board_dig_out_sample_rate';
				case {'time','timestamp'},
					headername = 'amplifier_sample_rate';
				case {'auxiliary','aux'},
					headername = 'aux_input_sample_rate';
				otherwise,
					error(['Do not know frequency header name for channel type ' channeltype '.']);
			end;
		end % mfdaqchanneltype2intanfreqheader()

	end % methods (Static)
end

