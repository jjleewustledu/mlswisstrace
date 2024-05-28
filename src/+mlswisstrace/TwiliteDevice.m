classdef TwiliteDevice < handle & mlpet.InputFuncDevice
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
        do_close_fig
        Dt
        % fqfileprefix
        hct
        invEfficiency
        isWholeBlood
        model_kind
        pumpRate 
        radialArteryKit
        t0_forced
    end

	methods % GET/SET 
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
        function g = get.do_close_fig(this)
            g = this.catheter_.do_close_fig;
        end
        function     set.do_close_fig(this, s)
            assert(islogical(s))
            this.catheter_.do_close_fig = s;
        end
        function g = get.Dt(this)
            g = this.Dt_;
        end
        function     set.Dt(this, s)
            assert(isscalar(s))
            this.Dt_ = s;
        end
        % function g = get.fqfileprefix(this)
        %     g = this.catheter_.fqfileprefix;
        % end
        % function     set.fqfileprefix(this, s)
        %     assert(istext(x))
        %     this.catheter_.fqfileprefix = s;
        % end
        function g = get.hct(this)
            g = this.catheter_.hct;
        end
        function     set.hct(this, s)
            assert(isscalar(s))
            if s < 1
                s = 100*s;
            end
            this.catheter_.hct = s;
        end
        function g = get.invEfficiency(this)
            g = this.invEfficiency_;
        end
        function g = get.isWholeBlood(this)
            g = this.data_.isWholeBlood;
        end
        function g = get.model_kind(this)
            g = this.catheter_.model_kind;
        end
        function     set.model_kind(this, s)
            assert(istext(s))
            this.catheter_.model_kind = s;
        end
        function g = get.pumpRate(this)
            %% default := 5 mL/min
            
            g = this.pumpRate_;
        end
        function g = get.radialArteryKit(this)
            g = this.catheter_.radialArteryKit;
        end
        function g = get.t0_forced(this)
            g = this.t0_forced_;
        end
        function     set.t0_forced(this, s)
            assert(isnumeric(s));
            this.t0_forced_ = s;
        end
    end

    methods
        function a = activity(this, varargin)
            %% is calibrated to ref-source and catheter-adjusted and shifted in worldline; Bq
            %  @param decayCorrected, default := false.
 			%  @param datetimeForDecayCorrection updates internal.
            %  @param Nt is number of time samples (1 sec each).            

            a = this.activityDensity(varargin{:})*this.data_.visibleVolume;
        end
        function a = activityDensity(this, varargin)
            %% is calibrated to ref-source and catheter-adjusted; Bq/mL
            %  @param decayCorrected, default := false.
 			%  @param datetimeForDecayCorrection updates internal.
            %  @param Nt is number of time samples (1 sec each).            
            
            if ~this.deconvCatheter 
                a_ = this.data_.activityDensity(varargin{:});
                a = this.invEfficiency_*a_;
                return
            end

            if ~isempty(this.activityDensityCached_)
                a = this.activityDensityCached_;
                return
            end

            %% deconv AIF with Catheter_DT20190930 & RadialArteryLee2024

            this.catheter_.Measurement = this.data_.activityDensity(varargin{:});
            a_ = this.catheter_.deconvBayes(varargin{:});
            a = this.invEfficiency_*a_;
            this.activityDensityCached_ = a;
        end
        function appendActivityDensity(this, varargin)
            this.data_.appendActivityDensity(varargin{:});
        end
        function c = countRate(this, varargin)
            %% has no calibrations nor catheter adjustments; in cps
            %  @param decayCorrected, default := false.
 			%  @param datetimeForDecayCorrection updates internal.
            %  @param Nt is number of time samples (1 sec each).
            
            c = this.data_.countRate(varargin{:});
        end
        function plot_deconv(this, varargin)
            this.catheter_.plot_deconv(varargin{:});
        end
        function h = plot(this, varargin)
            h = this.plotall(this, varargin{:});
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
        
    methods (Static)
        function this = createFromSession(sesd, varargin)
            rm = mlpet.CCIRRadMeasurements.createFromSession(sesd, varargin{:});
            data = mlswisstrace.TwiliteData.createFromSession( ...
                sesd, 'visibleVolume', rm.twilite.VISIBLEVolume_ML, varargin{:});
            %Dt = 2*ceil(mlswisstrace.Catheter_DT20190930.t0); % provide room for delay corrections
            %data.time0 = max(data.time0 - Dt, 0);
            hct = rm.laboratory{'Hct',1};
            if iscell(hct)
                hct = hct{1};
            end
            if istext(hct)
                hct = str2double(hct);
            end
            if isa(sesd, 'mlnipet.SessionData')
                cal = mlswisstrace.TwiliteCalibration.createFromSession( ...
                    mlswisstrace.TwiliteDevice.findCalibrationSession(sesd, varargin{:}));
                this = mlswisstrace.TwiliteDevice( ...
                    'calibration', cal, ...
                    'data', data, ...
                    'hct', hct, ...
                    't0_forced', sesd.t0_forced);
            else
                cal = mlswisstrace.TwiliteCalibration.createFromSession( ...
                    mlswisstrace.TwiliteDevice.findCalibrationSession(sesd, varargin{:}));
                fqfp = sprintf('%s_%s', sesd.imagingContext.fqfp, stackstr());
                this = mlswisstrace.TwiliteDevice( ...
                    'calibration', cal, ...
                    'data', data, ...
                    'hct', hct, ...
                    'fqfileprefix', fqfp, ...
                    'do_close_fig', true);
            end
            
            if max(this.countRate) < 10*std(this.baselineCountRate) + mean(this.baselineCountRate)
                error('mlswisstrace:ValueError', ...
                    'TwiliteDevice.createFromSession:  mean(countRate) ~ %g but mean(baseline) ~ %g.', ...
                    mean(this.countRate), mean(this.baselineCountRate))
            end
        end
        function sesd = findCalibrationSession(sesd0, varargin)
            %% assumed calibration is performed at end of session

            if isa(sesd0, 'mlnipet.SessionData')
                scanfold = globFoldersT(fullfile(sesd0.sessionPath, 'FDG_DT*-Converted-AC'));
                sesd = sesd0.create(fullfile(sesd0.projectFolder, sesd0.sessionFolder, mybasename(scanfold{end})));
                return
            end
            if isa(sesd0, 'mlpipeline.ImagingMediator')
                scans = glob(fullfile(strcat(sesd0.subjectPath, '-phantom'), '**', 'sub-*_ses-*_trc-fdg_*Static*.nii.gz'))';
                if isempty(scans)
                    scans = glob(fullfile(sesd0.subjectPath, '**', 'sub-*_ses-*_trc-fdg_proc-static-phantom*_pet.nii.gz'))';
                end
                if isempty(scans)
                    scans = glob(fullfile(sesd0.subjectPath, '**', 'sub-*_ses-*_trc-fdg_proc-delay0-BrainMoCo2-createNiftiStatic-phantom.nii.gz')); 
                    % e.g.: sub-108250_ses-20221207120651_trc-fdg_proc-delay0-BrainMoCo2-createNiftiStatic-phantom.nii.gz
                end
                if isempty(scans)
                    scans = glob(fullfile(sesd0.subjectPath, '**', 'sub-*_ses-*_Phantom*Static*.nii.gz'));
                end
                if isempty(scans)
                    scans = glob(fullfile(sesd0.subjectPath, '**', 'sub-*_ses-*_Static*Phantom*.nii.gz'));
                end
                if isempty(scans)
                    scans = glob(fullfile(sesd0.subjectPath, '**', 'sub-*_ses-*_FDG_Static*.nii.gz'));
                end
                sesd = sesd0.create(scans{1}); 
                return
            end
            error('mlpet:RuntimeError', stackstr())
        end
        function ie = invEfficiencyf(sesd)
            this =  mlswisstrace.TwiliteDevice.createFromSession(sesd);
            ie = this.invEfficiency_;
        end
    end

    %% PROTECTED
    
    properties (Access = protected)
        activityDensityCached_ %% MUST reset to empty if TwiliteData objects change
        catheter_
        deconvCatheter_
        Dt_
        invEfficiency_
        pumpRate_
        t0_forced_
    end
    
    methods (Access = protected)        
 		function this = TwiliteDevice(varargin)
 			this = this@mlpet.InputFuncDevice(varargin{:});            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'hct', 45, @isnumeric);
            addParameter(ip, 'deconvCatheter', true, @islogical);
            addParameter(ip, 't0_forced', [], @isnumeric);
            addParameter(ip, 'fqfileprefix', '', @istext);
            addParameter(ip, 'do_close_fig', false, @islogical);
            addParameter(ip, 'model_kind', '3bolus', @istext);
            addParameter(ip, 'pumpRate', 5, @isnumeric)
            parse(ip, varargin{:});
            ipr = ip.Results;
            
            this.catheter_ = mlswisstrace.Catheter_DT20190930( ...
                'Measurement', this.countRate, ...
                'hct', ipr.hct, ...
                'tracer', this.tracer, ...
                'model_kind', ipr.model_kind, ...
                'fqfileprefix', ipr.fqfileprefix, ...
                'do_close_fig', ipr.do_close_fig);
            this.fqfileprefix = ipr.fqfileprefix;
            this.invEfficiency_ = ...
                mean(this.calibration_.invEfficiency)* ...
                mlcapintec.RefSourceCalibration.invEfficiencyf();
            this.deconvCatheter_ = ipr.deconvCatheter;
            this.t0_forced_ = ipr.t0_forced;
            this.activityDensityCached_ = [];
            this.pumpRate_ = ipr.pumpRate;
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

