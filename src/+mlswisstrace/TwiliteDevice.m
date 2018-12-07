classdef TwiliteDevice < handle & mlpet.Instrument
	%% TWILITEDEVICE  

	%  $Revision$
 	%  was created 18-Oct-2018 14:00:25 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlswisstrace/src/+mlswisstrace.
 	%% It was developed on Matlab 9.4.0.813654 (R2018a) for MACI64.  Copyright 2018 John Joowon Lee.
 	
	properties
 		
 	end
    
    methods (Static)        
        function checkRangeInvEfficiency(ie)
            %  @param required ie is numeric.
            %  @throws mlswisstrace:ValueError.
            
            assert(all(150 < ie) && all(ie < 500), ...
                'mlswisstrace:ValueError', ...
                'TwiliteDevice.checkRangeInvEfficiency.ie->%s', mat2str(ie));
        end
    end

	methods 
		  
 		function this = TwiliteDevice(varargin)
 			%% TWILITEDEVICE
 			%  @param .

 			this = this@mlpet.Instrument(varargin{:});
 		end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

