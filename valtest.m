function a = valtest(width,varargin)
   p = inputParser;
   validScalarPosNum = @(x) isnumeric(x) && isscalar(x) && (x > 0);
   validshapestr = @(x) any(validatestring(x,{'square','rectangle','parallelogram'}));
   addRequired(p,'width',validScalarPosNum);
   addOptional(p,'height',1,validScalarPosNum);
   addParameter(p,'units','inches',@isstring);
   addParameter(p,'shape','rectangle',validshapestr);
   parse(p,width,varargin{:});
   
   a = [ num2str(p.Results.width*p.Results.height) '_' p.Results.units '_' p.Results.shape]; 
end