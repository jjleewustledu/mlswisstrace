classdef TwiliteCalibration0 < mlswisstrace.Twilite
	%% TWILITECALIBRATION  

	%  $Revision$
 	%  was created 19-Jul-2017 23:38:06 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlswisstrace/src/+mlswisstrace.
 	%% It was developed on Matlab 9.2.0.538062 (R2017a) for MACI64.  Copyright 2017 John Joowon Lee.
 	
    
	methods 
 		function this = TwiliteCalibration0(varargin)
 			%% TWILITECALIBRATION
       
 			this = this@mlswisstrace.Twilite(varargin{:}, 'doMeasureBaseline', false);            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'isotope', '18F', @ischar);
            parse(ip, varargin{:});                      
            this.isotope_ = ip.Results.isotope;
 		end
    end 
    
    %% PROTECTED
    
    properties (Access = protected)
        baselineRange_ % time index
        samplingRange_ % time index
    end
    
    %% HIDDEN    
    %  @deprecated
    
    methods (Hidden)
        function [m,s] = calibrationBaseline(this)
            %% CALIBRATIONBASELINE returns specific activity
            %  @returns m, mean
            %  @returns s, std
            
            cnts = this.counts.*this.taus;
            cnts = cnts(this.baselineRange_);
            sa   = cnts/this.arterialCatheterVisibleVolume;
            m    = mean(sa);
            s    = std(sa);
        end
        function [m,s] = calibrationMeasurement(this)
            %% CALIBRATIONMEASUREMENT returns specific activity without baseline
            %  @returns m, mean
            %  @returns s, std
            
            [m,s] = this.calibrationSample;
             m    = m - this.calibrationBackground;
        end
        function [m,s] = calibrationSample(this)
            %% CALIBRATIONSAMPLE returns specific activity
            %  @returns m, mean
            %  @returns s, std
            
            tzero  = this.times(this.samplingRange_(1));
            dccnts = this.decayCorrection_.correctedCounts(this.counts, tzero).*this.taus;
            dccnts = dccnts(this.samplingRange_);
            sa     = dccnts/this.arterialCatheterVisibleVolume;
            m      = mean(sa);
            s      = std(sa);
        end
        function this  = findCalibrationIndices(this)
            minCnts = min(this.counts);
            cappedCnts = [minCnts*ones(1,5) this.counts minCnts*ones(1,5)];
            [~,tup]   = max(diff(smooth(cappedCnts))); % smoothing range = 5
            tup = tup - 5;
            [~,tdown] = min(diff(smooth(cappedCnts)));
            tdown = tdown - 5;
            smplRng   = tup:tdown;
            N = length(this.counts);
            Npre = smplRng(1);
            Npost = N - smplRng(end);
            if (Npre > Npost)
                baseRng = 1:smplRng(1)-1;
            else
                baseRng = smplRng(end)+1:N;
            end
            this.samplingRange_ = smplRng;
            this.baselineRange_ = baseRng;
        end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

