classdef TwiliteDevice < handle & mlpet.AbstractDevice
	%% TWILITEDEVICE  

	%  $Revision$
 	%  was created 18-Oct-2018 14:00:25 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlswisstrace/src/+mlswisstrace.
 	%% It was developed on Matlab 9.4.0.813654 (R2018a) for MACI64.  Copyright 2018 John Joowon Lee.
 	    
	properties (Dependent)
        baselineActivity
        baselineActivityDensity
        baselineCountRate
 		calibrationAvailable
        catheterKit
        deconvCatheter
        Dt
        hct
        invEfficiency
        radialArteryKit
        timeCliff
        t0_forced
 	end
    
    methods (Static)
        function this = createFromSession(sesd, varargin)
            data = mlswisstrace.TwiliteData.createFromSession(sesd, varargin{:});
            Dt = 2*ceil(mlswisstrace.Catheter_DT20190930.t0); % provide room for delay corrections
            data.time0 = max(data.time0 - Dt, 0);
            rm = mlpet.CCIRRadMeasurements.createFromSession(sesd, varargin{:});
            hct = rm.laboratory{'Hct',1};
            if iscell(hct)
                hct = hct{1};
            end
            if istext(hct)
                hct = str2double(hct);
            end
            if isa(sesd, 'mlnipet.SessionData')
                t0_forced = sesd.t0_forced;
            else
                t0_forced = [];
            end
            cal = mlswisstrace.TwiliteCalibration.createFromSession( ...
                mlswisstrace.TwiliteDevice.findCalibrationSession(sesd, varargin{:}));
            this = mlswisstrace.TwiliteDevice( ...
                'calibration', cal, ...
                'data', data, ...
                'hct', hct, ...
                't0_forced', t0_forced);
            
            if max(this.countRate) < 10*std(this.baselineCountRate) + mean(this.baselineCountRate)
                error('mlswisstrace:ValueError', ...
                    'TwiliteDevice.createFromSession:  mean(countRate) ~ %g but mean(baseline) ~ %g.', ...
                    mean(this.countRate), mean(this.baselineCountRate))
            end
        end
        function ie = invEfficiencyf(sesd)
            this =  mlswisstrace.TwiliteDevice.createFromSession(sesd);
            ie = this.invEfficiency_;
        end
    end

	methods 
        
        %% GET
        
        function g = get.baselineActivity(this)
            g = this.data_.baselineActivity;
        end
        function g = get.baselineActivityDensity(this)
            g = this.data_.baselineActivityDensity;
        end
        function g = get.baselineCountRate(this)
            g = this.data_.baselineCountRate;
        end
        function g = get.calibrationAvailable(this)
            g = this.calibration_.calibrationAvailable;
        end
        function g = get.catheterKit(this)
            g = this.catheter_;
        end
        function g = get.deconvCatheter(this)
            g = this.deconvCatheter_;
        end
        function     set.deconvCatheter(this, s)
            this.deconvCatheter_ = s;
        end
        function g = get.Dt(this)
            g = this.Dt_;
        end
        function     set.Dt(this, s)
            assert(isscalar(s))
            this.Dt_ = s;
        end
        function g = get.hct(this)
            g = this.catheter_.hct;
        end
        function g = get.invEfficiency(this)
            g = this.invEfficiency_;
        end
        function g = get.radialArteryKit(this)
            g = this.catheter_.radialArteryKit;
        end
        function g = get.timeCliff(this)
            g = this.timeCliff_;
        end
        function     set.timeCliff(this, s)
            assert(isscalar(s))
            this.timeCliff_ = s;
        end
        function g = get.t0_forced(this)
            g = this.t0_forced_;
        end
        function     set.t0_forced(this, s)
            assert(isnumeric(s));
            this.t0_forced_ = s;
        end
		  
        %%        
        
        function a = activity(this, varargin)
            %% is calibrated to ref-source and catheter-adjusted and shifted in worldline; Bq
            %  @param decayCorrected, default := false.
 			%  @param datetimeForDecayCorrection updates internal.
            %  @param Nt is number of time samples (1 sec each).
            
            if ~this.deconvCatheter 
                a_ = this.data_.activity(varargin{:});
                a = this.invEfficiency_*a_;
                return
            end
            this.catheter_.Measurement = this.data_.activity(varargin{:});
            a_ = this.catheter_.deconvBayes('t0_forced', this.t0_forced, varargin{:});
            a = this.invEfficiency_*a_;
        end
        function a = activityDensity(this, varargin)
            %% is calibrated to ref-source and catheter-adjusted; Bq/mL
            %  @param decayCorrected, default := false.
 			%  @param datetimeForDecayCorrection updates internal.
            %  @param Nt is number of time samples (1 sec each).
            
            a = this.activity(varargin{:})/this.data_.visibleVolume;
        end
        function c = countRate(this, varargin)
            %% has no calibrations nor catheter adjustments; in cps
            %  @param decayCorrected, default := false.
 			%  @param datetimeForDecayCorrection updates internal.
            %  @param Nt is number of time samples (1 sec each).
            
            c = this.data_.countRate(varargin{:});
        end
        function h = plotall(this, varargin)
            %% PLOTALL
            
            h = figure;
            tt = this.data_.tableTwilite;
            plot(tt.datetime, tt.coincidences, '.', varargin{:});
            ylabel('coincidence count rate / cps')
            title(sprintf('%s.plot(%s)', class(this), this.data_.tracer))
        end
    end 
    
    %% PROTECTED
    
    properties (Access = protected)
        catheter_
        deconvCatheter_
        Dt_
        invEfficiency_
        timeCliff_
        t0_forced_
    end
    
    methods (Access = protected)        
 		function this = TwiliteDevice(varargin)
 			this = this@mlpet.AbstractDevice(varargin{:});            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'hct', 45, @isnumeric);
            addParameter(ip, 'deconvCatheter', true, @islogical);
            addParameter(ip, 't0_forced', [], @isnumeric);
            addParameter(ip, 'timeCliff', @isscalar)
            parse(ip, varargin{:})
            ipr = ip.Results;
            
            if contains(this.tracer, 'fdg', IgnoreCase=true)
                model_kind = '2bolus';
            else
                model_kind = '3bolus';
            end
            this.catheter_ = mlswisstrace.Catheter_DT20190930( ...
                'Measurement', this.countRate, ...
                'hct', ipr.hct, ...
                'tracer', this.tracer, ...
                'model_kind', model_kind);
            this.invEfficiency_ = ...
                mean(this.calibration_.invEfficiency)* ...
                mlcapintec.RefSourceCalibration.invEfficiencyf();
            this.deconvCatheter_ = ipr.deconvCatheter;
            this.t0_forced_ = ipr.t0_forced;
            this.timeCliff_ = ipr.timeCliff;
 		end
    end
    
    %% DEPRECATED
    
    methods (Hidden)
        function this = imputeSteadyStateActivityDensity(this, varargin)
            this.data_ = this.data_.imputeSteadyStateActivityDensity(varargin{:});
        end        
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

