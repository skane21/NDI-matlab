function d = sampleAPI_device(name,thedatatree,reference)
% SAMPLEAPI_DEVICE - Create a new SAMPLEAPI_DEVICE object
%
%  D = SAMPLEAPI_DEVICE(NAME, THEDATATREE,REFERENCE)
%
%  Creates a new SAMPLEAPI_DEVICE object with name and specific data tree object.
%  This is an abstract class that is overridden by specific devices.
%  
%

if nargin==1,
	error(['Not enough input arguments.']);
elseif nargin==2,
	sampleAPI_device_struct = struct('name',name,'datatree',thedatatree,reference','time'); 
	d = class(sampleAPI_device_struct, 'sampleAPI_device');
elseif nargin==3,
	sampleAPI_device_struct = struct('name',name,'datatree',thedatatree,'reference',reference); 
	d = class(sampleAPI_device_struct, 'sampleAPI_device');
else,
	error(['Too many input arguments.']);
end;

end
