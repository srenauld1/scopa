         % - Should we force TIFFStack to use tiffread, rather than libTiff?
         if (~exist('bForceTiffread', 'var') || isempty(bForceTiffread))
            bForceTiffread = false;
         end
         
         % - Can we use the accelerated TIFF library?
         if (exist('tifflib') ~= 3) %#ok<EXIST>
             % - Try to copy the library
             strTiffLibLoc = which('/private/tifflib');
             if isempty(strTiffLibLoc)
                 bForceTiffread = true;
             else
                 strTIFFStackLoc = fileparts(which('TIFFStack'));
                 copyfile(strTiffLibLoc, fullfile(strTIFFStackLoc, 'private'), 'f');
             end
         end
         oStack.bForceTiffread = bForceTiffread;

         oStack.bUseTiffLib = (exist('tifflib') == 3) & ~bForceTiffread; %#ok<EXIST>