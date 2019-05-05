classdef (Abstract) ndi_iodevice_image < ndi_iodevice
    %This is an abstract superclass of all imaging device drivers
    %This class defines the fundumental functions that the drivers should implement (frame, and numframe)

    properties
    end

    methods
        function obj = ndi_iodevice_image(name,filetree)
            obj = obj@ndi_iodevice(name,filetree);
        end
    end

    methods (Abstract)
        %This function returns a specific fram 'i' from epoch 'n'
        im = frame(obj,n,i)
        %This function returns the number of frames in epoch 'n'
        num = numFrame(obj,n)
    end


end