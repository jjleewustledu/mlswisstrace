classdef TwiliteCalibration < handle & mlpet.AbstractCalibration
	%% TWILITECALIBRATION  

	%  $Revision$
 	%  was created 19-Jul-2017 23:38:06 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlswisstrace/src/+mlswisstrace.
 	%% It was developed on Matlab 9.2.0.538062 (R2017a) for MACI64.  Copyright 2017 John Joowon Lee.
 	    
    properties (Dependent)
        calibrationAvailable
        invEfficiency
    end
    
    methods (Static)
        function buildCalibration()
        end   
        function this = createFromSession(sesd, varargin)
            %% CREATEBYSESSION
            %  @param required sessionData is an mlpipeline.ISessionData.
            %  @param offset is numeric & searches for alternative SessionData.
            
            import mlswisstrace.TwiliteCalibration
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addRequired(ip, 'sesd', @(x) isa(x, 'mlpipeline.ISessionData'))
            addOptional(ip, 'offset', 1, @isnumeric)
            parse(ip, sesd, varargin{:})
            ipr = ip.Results;
            
            try
                this = TwiliteCalibration(sesd, varargin{:});
                
                % get twilite calibration from most time-proximal calibration measurements
                if ~this.calibrationAvailable
                    error('mlswisstrace:ValueError', 'TwiliteCalibration.calibrationAvailable -> false')
                end
            catch ME
                handwarning(ME)
                sesd = TwiliteCalibration.findProximalSession(sesd, ipr.offset);
                this = TwiliteCalibration.createFromSession(sesd, 'offset', ipr.offset+1);
            end
        end
        function ie = invEfficiencyf(obj)
            %% INVEFFICIENCYF attempts to use calibration data from the nearest possible datetime.
            %  @param obj is an mlpipeline.ISessionData
            
            assert(isa(obj, 'mlpipeline.ISessionData'))
            this = mlswisstrace.TwiliteCalibration.createFromSession(obj);
            ie = this.invEfficiency;            
            ie = asrow(ie);
        end
    end
    
	methods 
        
        %% GET
        
        function g = get.calibrationAvailable(this)
            g = ~isempty(this.twiliteData_);
        end
        function g = get.invEfficiency(this)
            g = this.invEfficiency_;                
        end
        
        %%        
        
        function ad = activityDensityForCal(this)
            %% finds the temporally most proximate Twilite cal data and estimates activity density in Bq/mL.
            
            td = copy(this.twiliteData_);
            [~,thresholdedIndex] = max(td.countRate() > td.baselineSup);
            dtM1 = this.radMeasurements_.mMR.scanStartTime_Hh_mm_ss(1);
            dtM2 = td.datetimeMeasured + seconds(thresholdedIndex - 1);
            td.findBaseline(dtM2);
            td.findBolus(dtM1);
            td.timeForDecayCorrection = td.time0;
            td.decayCorrect;
            ad = td.activityDensity('index0', td.index0, 'indexF', td.indexF);
            ad = asrow(ad);
        end
        function [h1,h2] = plot(this)
            assert(isa(this.twiliteData_, 'mlswisstrace.TwiliteData'), ...
                'mlswisstrace:RuntimeError', 'TwiliteCalibration.plot() found faulty this.twiliteData_')
            td = copy(this.twiliteData_);
            td.resetTimeLimits;
            h1 = td.plot();
            h2 = figure;
            ad = this.activityDensityForCal();
            plot(ad);
            xlabel('indices')
            ylabel('activity density / (Bq/mL)')
            title('mlswisstrace.TwiliteCalibration.plot():this.activityDensityForCal()')
            text(1, ad(1), datestr(this.twiliteData_.datetimeMeasured))
        end
        
    end
    
    %% PROTECTED
    
    properties (Access = protected)
        invEfficiency_
        twiliteData_
    end
    
    methods (Access = protected)  
 		function this = TwiliteCalibration(sesd, varargin)
 			this = this@mlpet.AbstractCalibration( ...
                'radMeas', mlpet.CCIRRadMeasurements.createFromSession(sesd), varargin{:});
            
            % get activity density from Caprac
            rm = this.radMeasurements_;
            rowSelect = strcmp(rm.wellCounter.TRACER, '[18F]DG') & ...
                isnice(rm.wellCounter.MassSample_G) & ...
                isnice(rm.wellCounter.Ge_68_Kdpm);
            mass = rm.wellCounter.MassSample_G(rowSelect);
            ge68 = rm.wellCounter.Ge_68_Kdpm(rowSelect); 
            
            try
                shift = seconds( ...
                    rm.mMR.scanStartTime_Hh_mm_ss(1) - ...
                    seconds(rm.clocks.TimeOffsetWrtNTS____s('mMR console')) - ...
                    rm.wellCounter.TIMECOUNTED_Hh_mm_ss(rowSelect)); % backwards in time, clock-adjusted            
                capCal = mlcapintec.CapracCalibration.createFromSession(sesd);
                activityDensityCapr = capCal.activityDensity('mass', mass, 'ge68', ge68, 'solvent', 'water');
                activityDensityCapr = this.shiftWorldLines(activityDensityCapr, shift, this.radionuclide_.halflife);
                this.twiliteData_ = mlswisstrace.TwiliteData.createFromSession(sesd);
                this.invEfficiency_ = mean(activityDensityCapr)/mean(this.activityDensityForCal());
            catch ME
                handwarning(ME)
                this.twiliteData_ = [];
                this.invEfficiency_ = NaN;
            end
        end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

