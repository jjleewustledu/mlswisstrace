classdef Twilite < mlswisstrace.AbstractTwilite
	%% TWILITE  

	%  $Revision$
 	%  was created 23-Jan-2017 19:39:08
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/MATLAB-Drive/mlswisstrace/src/+mlswisstrace.
 	%% It was developed on Matlab 9.1.0.441655 (R2016b) for MACI64.  Copyright 2017 John Joowon Lee.
    
    methods 
        
        %%       
        
 		function this = Twilite(varargin)
 			%% TWILITE
            
 			this = this@mlswisstrace.AbstractTwilite(varargin{:});
            
            %this = this.updateTimingData;
            %this.counts = this.tableTwilite2counts;
            %assert(length(this.counts) == length(this.taus), 'mlswisstrace:arraySizeMismatch', 'Twilite.ctor');            
            %this.invEfficiency_ = ip.Results.invEfficiency;          
            %this.specificActivity = this.invEfficiency*(this.counts - this.countsBaseline)./this.taus./this.visibleVolume;
        end        
    end
    
    %% PROTECTED
    
    properties (Access = protected)
        twiliteCalibration_
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

