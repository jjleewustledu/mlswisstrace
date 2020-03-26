classdef TwiliteCalibration0 < mlswisstrace.AbstractTwilite
	%% TWILITECALIBRATION  

	%  $Revision$
 	%  was created 19-Jul-2017 23:38:06 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlswisstrace/src/+mlswisstrace.
 	%% It was developed on Matlab 9.2.0.538062 (R2017a) for MACI64.  Copyright 2017 John Joowon Lee.
 	    
    methods (Static)
        function this = createFromDate(varargin)
            %% @param required dt is datetime.
            
            ip = inputParser;
            addRequired(ip, 'dt', @isdatetime);
            addParameter(ip, 'isotope', 'FDG', @ischar);
            parse(ip, varargin{:})
            ipr = ip.Results;

            crvpth = fullfile(getenv('HOME'), 'Documents', 'private', 'Twilite', 'CRV', '');
            crvfp = sprintf('fdg_dt%d%02d%02d', ipr.dt.Year, ipr.dt.Month, ipr.dt.Day);
            crvfqfn = fullfile(crvpth, [crvfp '.crv']);
            if ~isfile(crvfqfn) 
                crvfp = sprintf('o15_fdg_dt%d%02d%02d', ipr.dt.Year, ipr.dt.Month, ipr.dt.Day);
                crvfqfn = fullfile(crvpth, [crvfp '.crv']);
                assert(isfile(crvfqfn))
            end
            crm = mlpet.CCIRRadMeasurements.createFromDate(ipr.dt);
            this = mlswisstrace.TwiliteCalibration0( ...
                'fqfilename', crvfqfn, ...
                'manualData', crm, ...
                'isotope', ipr.isotope, ...
                'doseAdminDatetime', crm.datetimeTracerAdmin('tracer', 'cal'));
        end
    end
    
	methods 
        function m    = mean_nobaseline(this)
            m = mean(this.timingData_.activity);
        end
        function m    = median_nobaseline(this)
            m = median(this.timingData_.activity);
        end
        function s    = std_nobaseline(this)
            s = std(this.timingData_.activity);
        end
        function this = updateTimingData(this, aDatetime)
            %% UPDATETIMINGDATA progressively shrinks this.timingData_ by imposing time limits based on
            %  @param aDatetime.
            
            this.timingData_ = this.timingData_.findCalibrationFrom(aDatetime);
        end
        
 		function this = TwiliteCalibration0(varargin)
 			%% TWILITECALIBRATION
            %  @param dt.
            %  @param invEfficiency.
            %  @param expectedBaseline.
            %  @param measuredBaseline.
       
 			this = this@mlswisstrace.AbstractTwilite(varargin{:});
            this.isDecayCorrected = true;
 		end
    end 
    
    %% PROTECTED
    
    properties (Access = protected)
        baselineRange_ % time index
        samplingRange_ % time index
    end
    
    %% HIDDEN @deprecated
    
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
