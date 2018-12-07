classdef TwiliteData < handle & AbstractTracerData
	%% TWILITEDATA  

	%  $Revision$
 	%  was created 17-Oct-2018 15:56:25 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlswisstrace/src/+mlswisstrace.
 	%% It was developed on Matlab 9.4.0.813654 (R2018a) for MACI64.  Copyright 2018 John Joowon Lee.
 	
	properties
 		
 	end

	methods 
		  
 		function this = TwiliteData(varargin)
 			%% TWILITEDATA
 			%  @param .

 			this = this@AbstractTracerData(varargin{:});
 		end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

