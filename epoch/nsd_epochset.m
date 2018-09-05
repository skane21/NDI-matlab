classdef nsd_epochset
% NSD_EPOCHSET - routines for managing a set of epochs and their dependencies
%
%

	properties (SetAccess=protected,GetAccess=public)
		
	end % properties
	properties (SetAccess=protected,GetAccess=protected)
	end % properties

	methods

		function obj = nsd_epochset()
			% NSD_EPOCHSET - constructor for NSD_EPOCHSET objects
			%
			% NSD_EPOCHSET_OBJ = NSD_EPOCHSET()
			%
			% This class has no parameters so the constructor is called with no input arguments.
			%

		end % nsd_epochset

		% okay, suppose we had

		%deleteepoch

		function n = numepochs(nsd_epochset_obj)
			% NUMEPOCHS - Number of epochs of NSD_EPOCHSET
			% 
			% N = NUMEPOCHS(NSD_EPOCHSET_OBJ)
			%
			% Returns the number of epochs in the NSD_EPOCHSET object NSD_EPOCHSET_OBJ.
			%
			% See also: EPOCHTABLE

				n = numel(epochtable(nsd_epochset_obj));

		end % numepochs

		function [et,hashvalue] = epochtable(nsd_epochset_obj)
			% EPOCHTABLE - Return an epoch table that relates the current object's epochs to underlying epochs
			%
			% [ET,HASHVALUE] = EPOCHTABLE(NSD_EPOCHSET_OBJ)
			%
			% ET is a structure array with the following fields:
			% Fieldname:                | Description
			% ------------------------------------------------------------------------
			% 'epoch_number'            | The number of the epoch. The number may change as epochs are added and subtracted.
			% 'epoch_id'                | The epoch ID code (will never change once established, though it may be deleted.)
			%                           |   This epoch ID uniquely specifies the epoch.
			% 'epochcontents'           | Any contents information for each epoch, usually of type NSD_EPOCHCONTENTS or empty.
			% 'epoch_clock'             | A cell array of NSD_CLOCKTYPE objects that describe the type of clocks available
			% 'underlying_epochs'       | A structure array of the nsd_epochset objects that comprise these epochs.
			%                           |   It contains fields 'underlying', 'epoch_number', 'epoch_id', and 'epochcontents'
			%
			% HASHVALUE is the hashed value of the epochtable. One can check to see if the epochtable
			% has changed with NSD_EPOCHSET/MATCHEDEPOCHTABLE.
			%
			% After it is read from disk once, the ET is stored in memory and is not re-read from disk
			% unless the user calls NSD_EPOCHSET/RESETEPOCHTABLE.
			%
				[cached_et, cached_hash] = cached_epochtable(nsd_epochset_obj);
				if isempty(cached_et),
					et = nsd_epochset_obj.buildepochtable();
					hashvalue = hashmatlabvariable(et);
					[cache,key] = getcache(nsd_epochset_obj);
					if ~isempty(cache),
						priority = 1; % use higher than normal priority
						cache.add(key,'epochtable-hash',struct('epochtable',et,'hashvalue',hashvalue),priority);
					end
				else,
					et = cached_et;
					hashvalue = cached_hash;
				end;

		end % epochtable

		function [et] = buildepochtable(nsd_epochset_obj)
			% BUILDEPOCHTABLE - Build and store an epoch table that relates the current object's epochs to underlying epochs
			%
			% [ET] = BUILDEPOCHTABLE(NSD_EPOCHSET_OBJ)
			%
			% ET is a structure array with the following fields:
			% Fieldname:                | Description
			% ------------------------------------------------------------------------
			% 'epoch_number'            | The number of the epoch. The number may change as epochs are added and subtracted.
			% 'epoch_id'                | The epoch ID code (will never change once established, though it may be deleted.)
			%                           |   This epoch ID uniquely specifies the epoch.
			% 'epochcontents'           | Any contents information for each epoch, usually of type NSD_EPOCHCONTENTS or empty.
			% 'epoch_clock'             | A cell array of NSD_CLOCKTYPE objects that describe the type of clocks available
			% 'underlying_epochs'       | A structure array of the nsd_epochset objects that comprise these epochs.
			%                           |   It contains fields 'underlying', 'epoch_number', 'epoch_id', and 'epochcontents'
			%
			% After it is read from disk once, the ET is stored in memory and is not re-read from disk
			% unless the user calls NSD_EPOCHSET/RESETEPOCHTABLE.
			%
				ue = emptystruct('underlying','epoch_number','epoch_id','epochcontents');
				et = emptystruct('epoch_number','epoch_id','epochcontents','epoch_clock','underlying_epochs');
		end % buildepochtable

		function [et,hashvalue]=cached_epochtable(nsd_epochset_obj)
			% CACHED_EPOCHTABLE - return the cached epochtable of an NSD_EPOCHSET object
			%
			% [ET, HASHVALUE] = CACHED_EPOCHTABLE(NSD_EPOCHSET_OBJ)
			%
			% Return the cached version of the epochtable, if it exists, along with its HASHVALUE
			% (a hash number generated from the table). If there is no cached version,
			% ET and HASHVALUE will be empty.
			%
				et = [];
				hashvalue = [];
				[cache,key] = getcache(nsd_epochset_obj);
				if (~isempty(cache) & ~isempty(key)),
					table_entry = cache.lookup(key,'epochtable-hash');
					if ~isempty(table_entry),
						et = table_entry(1).data.epochtable;
						hashvalue = table_entry(1).data.hashvalue;
					end;
				end
		end % cached_epochtable

		function [cache, key] = getcache(nsd_epochset_obj)
			% GETCACHE - return the NSD_CACHE and key for an NSD_EPOCHSET object
			%
			% [CACHE, KEY] = GETCACHE(NSD_EPOCHSET_OBJ)
			%
			% Returns the NSD_CACHE object CACHE and the KEY used by the NSD_EPOCHSET object NSD_EPOCHSET_OBJ.
			%
			% In this abstract class, no cache is available, so CACHE and KEY are empty. But subclasses can engage the
			% cache services of the class by returning an NSD_CACHE object and a unique key.
			%
				cache = [];
				key = [];
		end % getcache

		function nsd_epochset_obj = resetepochtable(nsd_epochset_obj)
			% RESETEPOCHTABLE - clear an NSD_EPOCHSET epochtable in memory and force it to be re-read from disk
			%
			% NSD_EPOCHSET_OBJ = RESETEPOCHTABLE(NSD_EPOCHSET_OBJ)
			%
			% This function clears the internal cached memory of the epochtable, forcing it to be re-read from
			% disk at the next request.
			%
			% See also: NSD_EPOCHSET/EPOCHTABLE

				[cache,key]=getcache(nsd_epochset_obj);
				if (~isempty(cache) & ~isempty(key)),
					cache.remove(key,'epochtable-hash');
				end
		end % resetepochtable

		function b = matchedepochtable(nsd_epochset_obj, hashvalue)
			% MATCHEDEPOCHTABLE - compare a hash number from an epochtable to the current version
			%
			% B = MATCHEDEPOCHTABLE(NSD_EPOCHSET_OBJ, HASHVALUE)
			%
			% Returns 1 if the current hashed value of the cached epochtable is identical to HASHVALUE.
			% Otherwise, it returns 0.

				b = 0;
				[cached_et, cached_hashvalue] = cached_epochtable(nsd_epochset_obj);
				if ~isempty(cached_et),
					b = (hashvalue == cached_hashvalue);
				end
		end % matchedepochtable

		function eid = epochid(nsd_epochset_obj, epoch_number)
			% EPOCHID - Get the epoch identifier for a particular epoch
			%
			% ID = EPOCHID (NSD_EPOCHSET_OBJ, EPOCH_NUMBER)
			%
			% Returns the epoch identifier string for the epoch EPOCH_NUMBER.
			% If it doesn't exist, it is created.
			%
			%
				eid = ''; % abstract class;
		end % epochid

		function ec = epochclock(nsd_epochset_obj, epoch_number)
			% EPOCHCLOCK - return the NSD_CLOCKTYPE objects for an epoch
			%
			% EC = EPOCHCLOCK(NSD_EPOCHSET_OBJ, EPOCH_NUMBER)
			%
			% Return the clock types available for this epoch as a cell array
			% of NSD_CLOCKTYPE objects (or sub-class members).
			%
			% The abstract class always returns NSD_CLOCKTYPE('no_time')
			%
			% See also: NSD_CLOCKTYPE
			%
				ec = {nsd_clocktype('no_time')};
		end % epochclock

		function s = epoch2str(nsd_epochset_obj, number)
			% EPOCH2STR - convert an epoch number or id to a string
			%
			% S = EPOCH2STR(NSD_EPOCHSET_OBJ, NUMBER)
			%
			% Returns the epoch NUMBER in the form of a string. If it is a simple
			% integer, then INT2STR is used to produce a string. If it is an epoch
			% identifier string, then it is returned.
				if isnumeric(number)
					s = int2str(number);
				elseif iscell(number), % a cell array of strings
					s = [];
					for i=1:numel(number),
						if (i>2)
							s=cat(2,s,[', ']);
						end;
						s=cat(2,s,number{i});
					end
				elseif ischar(number),
					s = number;
				else,
					error(['Unknown epoch number or identifier.']);
				end;
                end % epoch2str()

		% overlap table functions

		function ot = overlaptable(nsd_epochset_obj_a, nsd_epochset_obj_b)
			% OVERLAPTABLE - compute overlaps among two NSD_EPOCHSET objects
			%
			% OT = OVERLAPTABLE(NSD_EPOCHSET_OBJ_A, NSD_EPOCHSET_OBJ_B)
			%
			% OT is a matrix that has size NUMEPOCHS(NSD_EPOCHSET_OBJ_A) x NUMEPOCHS(NSD_EPOCHSET_OBJ_B)
			% and each entry OT(i,j) is 
			%    1 : If epoch i of NSD_EPOCHSET_OBJ_A overlaps NSD_EPOCHSET_OBJ_B
			%    0 : If epoch i of NSD_EPOCHSET_OBJ_A does NOT overlap NSD_EPOCHSET_OBJ_B
			%  NaN : If it is unknown if epoch i of NSD_EPOCHSET_OBJ_A overlaps NSD_EPOCHSET_OBJ_B.
			%
			% Two epochs are said to overlap if the time interval of epoch 1 (in absolute time) overlaps 
			% that of epoch 2.
			%
				cached_ot = cached_overlaptable(nsd_epochset_obj_a, nsd_epochset_obj_b);
				if isempty(cached_ot),
					ot = nsd_epochset_obj_a.buildoverlaptable(nsd_epochset_obj_b);
					[et_a,hash_a] = cached_epochtable(nsd_epochset_obj_a);
					[et_b,hash_b] = cached_epochtable(nsd_epochset_obj_b);
					[cache_a,key_a] = getcache(nsd_epochset_obj_a);
					[cache_b,key_b] = getcache(nsd_epochset_obj_a);
					if ~isempty(cache_a) & ~isempty(cache_b),
						overlaptable_type = ['overlaptable-' key_b];
						priority = 1; % use higher than normal priority
						cache_a.add(key,overlaptable_type,...
							struct('overlaptable',ot,'hashvalue_a',hash_a,'hashvalue_b',hash_b),...
							priority);
					end
				else,
					ot = cached_ot;
				end;
		end % overlaptable

		function ot = buildoverlaptable(nsd_epochset_obj_a, nsd_epochset_obj_b)
			% BUILDOVERLAPTABLE - compute overlap table among two NSD_EPOCHSET objects
			%
			% OT = BUILTOVERLAPTABLE(NSD_EPOCHSET_OBJ_A, NSD_EPOCHSET_OBJ_B)
			%
			% OT is a matrix that has size NUMEPOCHS(NSD_EPOCHSET_OBJ_A) x NUMEPOCHS(NSD_EPOCHSET_OBJ_B)
			% and each entry OT(i,j) is 
			%    1 : If epoch i of NSD_EPOCHSET_OBJ_A overlaps NSD_EPOCHSET_OBJ_B
			%    0 : If epoch i of NSD_EPOCHSET_OBJ_A does NOT overlap NSD_EPOCHSET_OBJ_B
			%  NaN : If it is unknown if epoch i of NSD_EPOCHSET_OBJ_A overlaps NSD_EPOCHSET_OBJ_B.
			%
			% Two epochs are said to overlap if the time interval of epoch 1 (in absolute time) overlaps 
			% that of epoch 2.
			%
			% In the abstract class, the table is all NaN.
			%
				ot = NaN(numepochs(nsd_epochset_obj_a),numepochs(nsd_epochset_obj_b));
		end % buildoverlaptable

		function [ot]=cached_overlaptable(nsd_epochset_obj_a, nsd_epochset_obj_b)
			% CACHED_OVERLAPTABLE - return the cached overlap table of an NSD_EPOCHSET object
			%
			% [OT] = CACHED_OVERLAPTABLE(NSD_EPOCHSET_OBJ_A, NSD_EPOCHSET_OBJ_B)
			%
			% Return the cached version of the overlaptable, if it exists and is up-to-date
			% (that is, the hash numbers from the EPOCHTABLEs of NSD_EPOCHSET_OBJ_A and NSD_EPOCHSET_OBJ_B
			% have not changed). If there is no cached version, or if it is not up-to-date, OT will be empty.
			% If the cached OT is present and not up-to-date, it is deleted.
			%
			%
				ot = [];
				[cache_a,key_a] = getcache(nsd_epochset_obj_a);
				[cache_b,key_b] = getcache(nsd_epochset_obj_b);
				if ( ~isempty(cache_a) & ~isempty(key_a) & ~isempty(cache_b) & ~isempty(key_b) ),
					overlaptable_type = ['overlaptable-' key_b];
					ot_data = cache.lookup(key,overlaptable_type);
					if ~isempty(ot_data),
						if matchedepochtable(nsd_epochset_obj_a, ot_data(1).hashvalue_a) & ...
							matchedepochtable(nsd_epochset_obj_b, ot_data(1).hashvalue_b),
							ot = ot_data(1).data.overlaptable;
						else,
							cache_a.remove(key,overlaptable_type); % it's out of date, clean it up
						end
					end
				end
		end % cached_overlaptable

		% epochgraph

		function [cost, mapping] = epochgraph(nsd_epochset_obj)
			% EPOCHGRAPH - graph of the mapping and cost of converting time among epochs
			%
			% [COST, MAPPING] = EPOCHGRAPH(NSD_EPOCHSET_OBJ)
			%
			% Compute the cost and the mapping among epochs in the EPOCHTABLE for an NSD_EPOCHSET object
			%
			% COST is an MxM matrix where M is the number of ordered pairs of (epochs, clocktypes).
			% For example, if there is one epoch with clock types 'dev_local_time' and 'utc', then M is 2.
			% Each entry COST(i,j) indicates whether there is a mapping between (epoch, clocktype) i to j.
			% The cost of each transformation is normally 1 operation. 
			% MAPPING is the NSD_TIMEMAPPING object that describes the mapping.
			%
				[cost, mapping] = cached_epochgraph(nsd_epochset_obj);
				if isempty(cost),
					[cost,mapping] = nsd_epochset_obj.buildepochgraph;
					[et,hash] = cached_epochtable(nsd_epochset_obj);
					[cache,key] = getcache(nsd_epochset_obj);
					if ~isempty(cache),
						epochgraph_type = ['epochgraph-hashvalue'];
						priority = 1; % use higher than normal priority
						data.cost = cost;
						data.mapping = mapping;
						data.hashvalue = hash;
						cache.add(key,epochgraph_type,data,priority);
					end
				end;
		end % overlaptable

		function [cost, mapping] = buildepochgraph(nsd_epochset_obj)
			% BUILDEPOCHGRAPH - compute the epochgraph among epochs for an NSD_EPOCHSET object
			%
			% [COST,MAPPING] = BUILDEPOCHGRAPH(NSD_EPOCHSET_OBJ)
			%
			% Compute the cost and the mapping among epochs in the EPOCHTABLE for an NSD_EPOCHSET object
			%
			% COST is an MxM matrix where M is the number of ordered pairs of (epochs, clocktypes).
			% For example, if there is one epoch with clock types 'dev_local_time' and 'utc', then M is 2.
			% Each entry COST(i,j) indicates whether there is a mapping between (epoch, clocktype) i to j.
			% The cost of each transformation is normally 1 operation. 
			% MAPPING is the NSD_TIMEMAPPING object that describes the mapping.
			%
			%
			% In the abstract class, the following NSD_CLOCKTYPEs, if they exist, are linked across epochs with 
			% a cost of 1 and a linear mapping rule with shift 1 and offset 0:
			%   'utc' -> 'utc'
			%   'utc' -> 'approx_utc'
			%   'exp_global_time' -> 'exp_global_time'
			%   'exp_global_time' -> 'approx_exp_global_time'
			%   'dev_global_time' -> 'dev_global_time'
			%   'dev_global_time' -> 'approx_dev_global_time'
			%
			%
			% See also: NSD_CLOCKTYPE, NSD_CLOCKTYPE/NSD_CLOCKTYPE, NSD_TIMEMAPPING, NSD_TIMEMAPPING/NSD_TIMEMAPPING

					% Developer note: some subclasses will have the ability to go across different clock types,
					% such as going from 'dev_local_time' to 'utc'. Those subclasses will likely want to
					% override this method by first calling the base class and then adding their own entries.

				trivial_mapping = nsd_timemapping([ 1 0 ]);

				et = epochtable(nsd_epochset_obj);
				epochclocklist = {};
				for i=1:numel(et),
					epochclocklist = cat(1,epochclocklist,et(i).epoch_clock);
				end

				cost = zeros(numel(epochclocklist));
				mapping = cell(numel(epochclocklist));

				for i=1:numel(epochclocklist),
					for j=1:numel(epochclocklist),
						if j==i,
							cost(i,j) = 1;
							mapping{i,j} = trivial_mapping;
						else,
							[cost(i,j),mapping{i,j}] = epochclocklist{i}.epochgraph_edge(epochclocklist{j});
						end
					end
				end

		end % buildepochgraph

		function [cost,mapping]=cached_epochgraph(nsd_epochset_obj)
			% CACHED_EPOCHGRAPH - return the cached epoch graph of an NSD_EPOCHSET object
			%
			% [COST,MAPPING] = CACHED_EPOCHGRAPH(NSD_EPOCHSET_OBJ)
			%
			% Return the cached version of the epoch graph, if it exists and is up-to-date
			% (that is, the hash number from the EPOCHTABLE of NSD_EPOCHSET_OBJ 
			% has not changed). If there is no cached version, or if it is not up-to-date,
			% COST and MAPPING will be empty. If the cached epochgraph is present and not up-to-date,
			% it is deleted.
			%
			% See also: NSD_EPOCHSET_OBJ/EPOCHGRAPH, NSD_EPOCHSET_OBJ/BUILDEPOCHGRAPH
			%
				cost = [];
				mapping = [];
				[cache,key] = getcache(nsd_epochset_obj);
				if ( ~isempty(cache)  & ~isempty(key) ),
					epochgraph_type = ['epochgraph-hashvalue'];
					eg_data = cache.lookup(key,epochgraph_type);
					if ~isempty(eg_data),
						if matchedepochtable(nsd_epochset_obj, eg_data(1).hashvalue), 
							cost = eg_data(1).data.cost;
							mapping = eg_data(1).data.mapping;
						else,
							cache.remove(key,epochgraph_type); % it's out of date, clean it up
						end
					end
				end
		end % cached_epochgraph

	end % methods

end % classdef

 
%discussion: If we do this
%
%how will we pick and store epoch labels for non-devices? 
%	use some absurd concatenation
%	where to store it? or construct it from the myriad of underlying records?
%

