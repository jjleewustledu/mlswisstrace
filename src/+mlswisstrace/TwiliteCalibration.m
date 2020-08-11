classdef TwiliteCalibration < handle & mlpet.AbstractCalibration
	%% TWILITECALIBRATION  
    %  get.invEfficiency() traps known defects using sessionData identifiers.

	%  $Revision$
 	%  was created 19-Jul-2017 23:38:06 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlswisstrace/src/+mlswisstrace.
 	%% It was developed on Matlab 9.2.0.538062 (R2017a) for MACI64.  Copyright 2017 John Joowon Lee.
 	    
    properties (Dependent)
        calibrationAvailable
        invEfficiency
        twiliteData
    end
    
    methods (Static)
        function buildCalibration()
        end   
        function this = createFromSession(sesd, varargin)
            %% CREATEBYSESSION
            %  @param required sessionData is an mlpipeline.ISessionData.
            %  @param offset is numeric & searches for alternative SessionData.
            
            import mlswisstrace.TwiliteCalibration
            
            this = TwiliteCalibration(sesd, varargin{:});                
            
            offset = 0;
            while ~this.calibrationAvailable              
                offset = offset + 1;
                sesd1 = sesd.findProximal(offset);
                this = TwiliteCalibration(sesd1, varargin{:});
            end
        end
        function ie = invEfficiencyf(obj)
            %% INVEFFICIENCYF attempts to use calibration data from the nearest possible datetime.
            %  @param obj is an mlpipeline.ISessionData
            
            assert(isa(obj, 'mlpipeline.ISessionData'))
            this = mlswisstrace.TwiliteCalibration.createFromSession(obj);
            ie = this.invEfficiency;
        end
    end
    
	methods 
        
        %% GET
        
        function g = get.calibrationAvailable(this)
            g = ~isempty(this.twiliteData_) && ~isnan(this.invEfficiency);
        end
        function g = get.invEfficiency(this)
            if strcmp(this.sessionData.scanFolder, 'FDG_DT20180601125239.000000-Converted-AC')
                g = 1.643;
                return
            end
            g = asrow(this.invEfficiency_);
        end
        function g = get.twiliteData(this)
            g = this.twiliteData_;
        end
        
        %%        
        
        function [ad,td] = activityDensityForCal(this)
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
            [ad,td] = this.activityDensityForCal();
            plot(ad);
            xlabel('indices')
            ylabel('activity density / (Bq/mL)')
            title('mlswisstrace.TwiliteCalibration.plot():this.activityDensityForCal()')
            text(10, (max(ad) - min(ad))/2, ['sampling start: ' datestr(td.datetime0)])
        end
        
    end
    
    %% PROTECTED
    
    properties (Access = protected)
        invEfficiency_
        twiliteData_
    end
    
    methods (Access = protected)  
 		function this = TwiliteCalibration(sesd, varargin)
 			this = this@mlpet.AbstractCalibration(varargin{:});
            
            try
                % update for new sesd
                if isempty(this.radMeasurements_) || ...
                        ~strcmp(this.radMeasurements_.sessionData.scanPath, sesd.scanPath)
                    this.radMeasurements_ = mlpet.CCIRRadMeasurements.createFromSession(sesd);
                end

                % get activity density from Caprac
                
                rm = this.radMeasurements_;            
                rowSelect = strcmp(rm.wellCounter.TRACER, '[18F]DG') & ...
                    isnice(rm.wellCounter.MassSample_G) & ...
                    isnice(rm.wellCounter.Ge_68_Kdpm);
                mass = rm.wellCounter.MassSample_G(rowSelect);
                ge68 = rm.wellCounter.Ge_68_Kdpm(rowSelect); 
                shift = seconds( ...
                    rm.mMR.scanStartTime_Hh_mm_ss(1) - ...
                    seconds(rm.clocks.TimeOffsetWrtNTS____s('mMR console')) - ...
                    rm.wellCounter.TIMECOUNTED_Hh_mm_ss(rowSelect)); % backwards in time, clock-adjusted            
                capCal = mlcapintec.CapracCalibration.createFromSession(sesd, 'radMeasurements', rm, 'exactMatch', true);
                activityDensityCapr = capCal.activityDensity('mass', mass, 'ge68', ge68, 'solvent', 'water');
                activityDensityCapr = this.shiftWorldLines(activityDensityCapr, shift, this.radionuclide_.halflife);
                
                % get activity density from Twilite data sources && form efficiency^{-1}
                
                this.twiliteData_ = mlswisstrace.TwiliteData.createFromSession(sesd, 'radMeasurements', rm);
                this.invEfficiency_ = mean(activityDensityCapr)/mean(this.activityDensityForCal());
            catch ME
                
                % calibration data was inadequate, but proximal session may be useable
                handwarning(ME)
                this.twiliteData_ = [];
                this.invEfficiency_ = NaN;
            end
        end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

