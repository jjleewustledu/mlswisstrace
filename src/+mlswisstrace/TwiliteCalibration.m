classdef TwiliteCalibration < handle & mlpet.AbstractCalibration
	%% TWILITECALIBRATION  
    %  get.invEfficiency() traps known defects using sessionData identifiers.

	%  $Revision$
 	%  was created 19-Jul-2017 23:38:06 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlswisstrace/src/+mlswisstrace.
 	%% It was developed on Matlab 9.2.0.538062 (R2017a) for MACI64.  Copyright 2017 John Joowon Lee.
 	    
    properties (Dependent)
        Bq_over_cps
        calibrationAvailable
        invEfficiency
        twiliteData
    end
    
    methods (Static)
        function dispCalibration(varargin)
            %  Args:
            %      filename (required file)
            %      halflife (required text|scalar):  '15O', '18F', '11C', or seconds
            %      baseline_t0 (datetime):  1st datetime for baseline, DEFAULT is start of file
            %      baseline_tf (datetime):  last datetime for baseline
            %      reference_t0 (datetime):  1st datetime for reference, DEFAULT is 5 sec after baseline_tf
            %      reference_tf (datetime):  last datetime for reference, DEFAULT is end of file

            ip = inputParser;
            addRequired(ip, 'filename', @isfile);
            addRequired(ip, 'halflife', @(x) istext(x) || isscalar(x))
            addParameter(ip, 'baseline_t0', NaT, @isdatetime);
            addParameter(ip, 'baseline_tf', NaT, @isdatetime);
            addParameter(ip, 'reference_t0', NaT, @isdatetime);
            addParameter(ip, 'reference_tf', NaT, @isdatetime);
            parse(ip, varargin{:});
            ipr = ip.Results;
            if istext(ipr.halflife)
                ipr.halflife = mlpet.Radionuclides.halflifeOf(ipr.halflife);
            end

            % visualize
            cal = mlswisstrace.CrvData(ipr.filename);
            plotAll(cal);

            % determine baseline activity
            if isnat(ipr.baseline_t0)
                ipr.baseline_t0 = cal.time(1);
            end
            ipr.baseline_t0 = ensureTimeZone(ipr.baseline_t0);
            [~,baseline_idx0] = max(cal.time > ipr.baseline_t0);
            if isnat(ipr.baseline_tf)
                return
            end
            ipr.baseline_tf = ensureTimeZone(ipr.baseline_tf);
            [~,baseline_idxf] = max(cal.time > ipr.baseline_tf);
            baseline = cal.coincidence(baseline_idx0:baseline_idxf);

            % determine reference activity, decay-corrected
            if isnat(ipr.reference_t0)
                ipr.reference_t0 = ipr.baseline_tf + seconds(5);
            end
            ipr.reference_t0 = ensureTimeZone(ipr.reference_t0);
            [~,reference_idx0] = max(cal.time > ipr.reference_t0);
            if isnat(ipr.reference_tf)
                ipr.reference_tf = cal.time(end);
            end
            ipr.reference_tf = ensureTimeZone(ipr.reference_tf);
            [~,reference_idxf] = max(cal.time >= ipr.reference_tf);
            reference = cal.coincidence(reference_idx0:reference_idxf);
            N = length(reference);
            reference = reference .* (2.^((0:N-1)/ipr.halflife))';

            % disp
            fprintf(strcat(clientname(false, 2), ":\n"));
            fprintf('mean(baseline(%s -> %s)):  %g\n', ipr.baseline_t0, ipr.baseline_tf, mean(baseline));
            fprintf('std( baseline(%s -> %s)):  %g\n', ipr.baseline_t0, ipr.baseline_tf, std( baseline));
            fprintf('mean(reference(%s -> %s)):  %g\n', ipr.reference_t0, ipr.reference_tf, mean(reference));
            fprintf('std( reference(%s -> %s)):  %g\n', ipr.reference_t0, ipr.reference_tf, std( reference));
        end
        function this = createFromSession(sesd, varargin)
            %% CREATEBYSESSION
            %  @param required sessionData is an mlpipeline.{ISessionData,ImagingData}.
            %  @param offset is numeric & searches for alternative SessionData.
            
            import mlswisstrace.TwiliteCalibration
            
            this = TwiliteCalibration(sesd, varargin{:});                
            
            offset = 0;
            while ~this.calibrationAvailable
                if isa(sesd, 'mlpipeline.ImagingMediator')
                    error('mlswisstrace:ValueError', stackstr())
                end
                offset = offset + 1;
                sesd1 = sesd.findProximal(offset);
                this = TwiliteCalibration(sesd1, varargin{:});
            end
        end
        function ie = invEfficiencyf(obj)
            %% INVEFFICIENCYF attempts to use calibration data from the nearest possible datetime.
            %  @param obj is an mlpipeline.{ISessionData,ImagingData}
            
            this = mlswisstrace.TwiliteCalibration.createFromSession(obj);
            ie = this.invEfficiency;
        end
    end
    
	methods % GET        
        function g = get.Bq_over_cps(this)
            g = asrow(this.Bq_over_cps_);
        end
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
    end

    methods
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
        function [cr,td] = countRateForCal(this)
            %% finds the temporally most proximate Twilite cal data and estimates count rate in counts/s.
            
            td = copy(this.twiliteData_);
            [~,thresholdedIndex] = max(td.countRate() > td.baselineSup);
            dtM1 = this.radMeasurements_.mMR.scanStartTime_Hh_mm_ss(1);
            dtM2 = td.datetimeMeasured + seconds(thresholdedIndex - 1);
            td.findBaseline(dtM2);
            td.findBolus(dtM1);
            td.timeForDecayCorrection = td.time0;
            td.decayCorrect;
            cr = td.countRate('index0', td.index0, 'indexF', td.indexF);
            cr = asrow(cr);
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
        Bq_over_cps_
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
                rowSelect = strcmp(rm.wellCounter.TRACER, this.CAL_TRACER) & ...
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
                activityDensityCapr = this.shiftWorldLines(activityDensityCapr, shift, this.calibration_halflife);
                
                % get activity density from Twilite data sources && form efficiency^{-1}

                % branching ratios cancel for this.invEfficiency_
                
                this.twiliteData_ = mlswisstrace.TwiliteData.createFromSession(sesd, 'radMeasurements', rm);
                this.invEfficiency_ = mean(activityDensityCapr)/mean(this.activityDensityForCal());
                vvol = this.twiliteData_.visibleVolume;
                this.Bq_over_cps_ = mean(activityDensityCapr)*vvol/mean(this.countRateForCal());
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

