classdef Twilite < mlswisstrace.AbstractTwilite
	%% TWILITE  

	%  $Revision$
 	%  was created 23-Jan-2017 19:39:08
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/MATLAB-Drive/mlswisstrace/src/+mlswisstrace.
 	%% It was developed on Matlab 9.1.0.441655 (R2016b) for MACI64.  Copyright 2017 John Joowon Lee.
    
    methods 
 		function this = Twilite(varargin)
 			%% TWILITE
            
 			this = this@mlswisstrace.AbstractTwilite(varargin{:});            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'isotope', '15O', @ischar);
            parse(ip, varargin{:});                      
            this.isotope_ = ip.Results.isotope;            
        end        
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

