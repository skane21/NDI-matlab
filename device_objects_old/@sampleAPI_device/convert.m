function [i0,t0] = convert(NSD,NSD_clock, t)
% CONVERT - Computes the interval and sample time relative
% to another clock
%
%   [I0, T0] = INTERVAL_RELATIVE_TIME(SAPI,SAPI_CLOCK, T)
%
%   Given a clock and a time point, compute the interval and time point
%   where the same time occurs on our device's clock

i = 1;

if strcmp (getclocktype(NSD_clock), 'global'),
    error(['do not know what to do.']);
    
elseif strcmp (getclocktype(NSD_clock), 'local'),
% 	t_ = d.clock(t);  % local to local    
    error(['do not know what to do.']);

elseif strcmp (getclocktype(NSD_clock), 'epoch'),
    i0 = getinterval(NSD_clock);
    t0 = t;
end


