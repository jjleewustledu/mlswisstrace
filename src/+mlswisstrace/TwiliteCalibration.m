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
        function this = createFromSession(varargin)
            %% CREATEBYSESSION
            %  @param required sessionData is an mlpipeline.ISessionData.
            
            this = mlswisstrace.TwiliteCalibration(varargin{:});
        end
        function inveff = invEfficiencyf(obj)
            %% INVEFFICIENCYF attempts to use calibration data from the nearest possible datetime.
            %  @param obj is an mlpipeline.ISessionData
            
            assert(is(obj, 'mlpipeline.ISessionData'))
            this = mlswisstrace.TwiliteCalibration.createFromSession(obj);
            inveff = this.invEfficiency;
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
            dtM1 = this.radMeasurements_.mMR.scanStartTime_Hh_mm_ss('NiftyPET');
            dtM2 = td.datetimeMeasured + seconds(thresholdedIndex - 1);
            td.findBaseline(dtM2);
            td.findBolus(dtM1);
            td.timeForDecayCorrection = td.time0;
            td.decayCorrect;
            ad = td.activityDensity('indices', td.index0:td.indexF);
        end
        function [h1,h2] = plot(this)
            assert(isa(this.twiliteData_, 'mlswisstrace.TwiliteData'), ...
                'mlswisstrace:RuntimeError', 'TwiliteCalibration.plot() found faulty this.twiliteData_')
            td = copy(this.twiliteData_);
            td.resetTimeLimits;
            h1 = td.plot();
            h2 = figure;
            plot(this.activityDensityForCal());
            xlabel('indices')
            ylabel('activity density / (Bq/mL)')
            title('mlswisstrace.TwiliteCalibration.plot():this.activityDensityForCal()')
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
            rowSelect = strcmp(rm.wellCounter.TRACER, '[18F]DG');
            mass = rm.wellCounter.MassSample_G(rowSelect);
            ge68 = rm.wellCounter.Ge_68_Kdpm(rowSelect);            
            
            try
                shift = seconds( ...
                    rm.mMR.scanStartTime_Hh_mm_ss('NiftyPET') - ...
                    seconds(rm.clocks.TimeOffsetWrtNTS____s('mMR console')) - ...
                    rm.wellCounter.TIMECOUNTED_Hh_mm_ss(rowSelect)); % backwards in time, clock-adjusted            
                capCal = mlcapintec.CapracCalibration.createFromSession(sesd);
                activityDensityCapr = capCal.activityDensity('mass', mass, 'ge68', ge68, 'solvent', 'water');
                activityDensityCapr = this.shiftWorldLines(activityDensityCapr, shift, this.radionuclide_.halflife); 

                % get twilite calibration from most time-proximal calibration measurements
                this.twiliteData_ = mlswisstrace.TwiliteData.createFromSession(sesd);
                offset = 0;
                while ~this.calibrationAvailable                    
                    sesd = this.searchForCalibrationSession(sesd, offset);
                    this.twiliteData_ = mlswisstrace.TwiliteData.createFromSession(sesd);
                    offset = offset + 1;
                end
                this.invEfficiency_ = mean(activityDensityCapr)/mean(this.activityDensityForCal());
            catch ME
                handwarning(ME)
                this.twiliteData_ = [];
                this.invEfficiency_ = NaN;
            end
        end
    end
    
    %% PRIVATE
    
    methods (Access = private)
        function sesd = searchForCalibrationSession(this, sesd, offset)
            datetimeBest = datetime(sesd);
            fdgCrvs = globT(fullfile(mlnipet.Resources.instance().CCIR_RAD_MEASUREMENTS_DIR, 'Twilite', 'CRV', '*fdg*.crv'));
            dates = this.crv2date(fdgCrvs);
            [~,idx] = min(abs(dates - datetimeBest));
            sesd = this.date2sessionData(dates(idx + offset), sesd);
        end
        function sesd = date2sessionData(this, date, sesd)
            home = getenv('SINGULARITY_HOME');
            assert(~isempty(home))
            for project = globFoldersT(fullfile(home, 'CCIR_*'))
                for session = globFoldersT(fullfile(project{1}, 'ses-E*'))
                    for fdg = globFoldersT(fullfile(session{1}, 'FDG_DT*-Converted-AC'))
                        if this.containsDate(fdg{1}, date)
                            sesd = sesd.create(fullfile(mybasename(project{1}), mybasename(session{1}), mybasename(fdg{end})));
                            return
                        end
                    end
                end
            end            
            error('mlswisstrace:RuntimeError', ...
                'TwiliteCalibration.date2sessionData could not find sessionData for date %s', datestr(date))
        end
        function tf = containsDate(~, str, date)
            tf = lstrfind(str, datestr(date, 'yyyymmdd'));
        end
        function d = crv2date(this, crv)
            if iscell(crv)
                dates = cellfun(@(x) this.crv2date(x), crv, 'UniformOutput', false);
                dates = dates';
                T = cell2table(dates);
                d = T.dates;
                return
            end
            
            % base case
            assert(ischar(crv))            
            ss = strsplit(mybasename(crv), 'dt');
            d = datetime(ss{2}, 'InputFormat', 'yyyyMMdd');            
        end
    end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

