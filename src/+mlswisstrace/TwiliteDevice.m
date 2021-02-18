classdef TwiliteDevice < handle & mlpet.AbstractDevice
	%% TWILITEDEVICE  

	%  $Revision$
 	%  was created 18-Oct-2018 14:00:25 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlswisstrace/src/+mlswisstrace.
 	%% It was developed on Matlab 9.4.0.813654 (R2018a) for MACI64.  Copyright 2018 John Joowon Lee.
 	
	properties (Dependent)
        baseline
 		calibrationAvailable
        deconvCatheter
        Dt
        hct
 	end
    
    methods (Static)
        function this = createFromSession(varargin)
            import mlswisstrace.TwiliteDevice.findCalibrationSession
            
            data = mlswisstrace.TwiliteData.createFromSession(varargin{:});
            Dt   = 2*ceil(mlswisstrace.Catheter_DT20190930.t0); % provide room for delay corrections
            data.time0 = data.time0 - Dt;
            rm   = mlpet.CCIRRadMeasurements.createFromSession(varargin{:});
            hct  = rm.fromPamStone{'Hct',1};
            if iscell(hct)
                hct = hct{1};
            end
            if ischar(hct)
                hct = str2double(hct);
            end
            this = mlswisstrace.TwiliteDevice( ...
                'calibration', mlswisstrace.TwiliteCalibration.createFromSession( ...
                    findCalibrationSession(varargin{:})), ...
                'data', data, ...
                'hct', hct);
        end
        function ie = invEfficiencyf(sesd)
            this =  mlswisstrace.TwiliteDevice.createFromSession(sesd);
            ie = this.invEfficiency_;
        end
    end

	methods 
        
        %% GET
        
        function g = get.baseline(this)
            g = this.data_.baseline;
        end
        function g = get.calibrationAvailable(this)
            g = this.calibration_.calibrationAvailable;
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
		  
        %%        
        
        function a = activity(this, varargin)
            %% is calibrated to ref-source and catheter-adjusted and shifted in worldline; Bq
            %  @param decayCorrected, default := false.
 			%  @param datetimeForDecayCorrection updates internal.
            
            if ~this.deconvCatheter                
                a = this.invEfficiency_*this.data_.activity(varargin{:});
                return
            end
            this.catheter_.Measurement = this.invEfficiency_*this.data_.activity(varargin{:});
            a = this.catheter_.deconv();
            a = a .* 2.^(this.catheter_.t0/this.halflife);
        end
        function a = activityDensity(this, varargin)
            %% is calibrated to ref-source and catheter-adjusted; Bq/mL
            %  @param decayCorrected, default := false.
 			%  @param datetimeForDecayCorrection updates internal.
            
            a = this.activity(varargin{:})/this.data_.visibleVolume;
        end
        function c = countRate(this, varargin)
            %% has no calibrations nor catheter adjustments; in cps
            %  @param decayCorrected, default := false.
 			%  @param datetimeForDecayCorrection updates internal.
            
            c = this.data_.countRate(varargin{:});
        end
        function this = imputeSteadyStateActivityDensity(this, varargin)
            this.data_ = this.data_.imputeSteadyStateActivityDensity(varargin{:});
        end
    end 
    
    %% PROTECTED
    
    properties (Access = protected)
        catheter_
        deconvCatheter_
        Dt_
        invEfficiency_
    end
    
    methods (Access = protected)        
 		function this = TwiliteDevice(varargin)
 			%% TWILITEDEVICE
            
            import mlswisstrace.TwiliteDevice.findCalibrationSession   
            import mlcapintec.RefSourceCalibration
            
 			this = this@mlpet.AbstractDevice(varargin{:});
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'hct', 45, @isnumeric)
            addParameter(ip, 'deconvCatheter', true, @islogical)
            parse(ip, varargin{:})
            
            this.catheter_ = mlswisstrace.Catheter_DT20190930( ...
                'Measurement', this.countRate, 'hct', ip.Results.hct);
            this.invEfficiency_ = mean(this.calibration_.invEfficiency) * RefSourceCalibration.invEfficiencyf();
            this.deconvCatheter_ = ip.Results.deconvCatheter;
 		end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

