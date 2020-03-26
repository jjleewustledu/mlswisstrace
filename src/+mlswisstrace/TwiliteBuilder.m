classdef TwiliteBuilder < mlpet.AbstractAifBuilder
	%% TWILITEBUILDER is DEPRECATED 

	%  $Revision$
 	%  was created 12-Dec-2017 16:44:27 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlswisstrace/src/+mlswisstrace.
 	%% It was developed on Matlab 9.3.0.713579 (R2017b) for MACI64.  Copyright 2017 John Joowon Lee.
 	
	properties (Dependent)
        counts2specificActivity
        datetime0
        fqfilename
        fqfilenameCalibrator
 	end

	methods 
        
        %% GET
         
        function g = get.counts2specificActivity(this)
            if (isempty(this.product_) || ...
                isnan(this.product_.counts2specificActivity))
                this = this.buildCounts2specificActivity;
            end            
            g = this.product_.counts2specificActivity;            
        end
        function g = get.datetime0(this)
            g = this.datetime0_;
        end
        function g = get.fqfilename(this)
            g = this.fqfilename_;
        end
        function g = get.fqfilenameCalibrator(this)
            g = this.fqfilenameCalibrator_;
        end    
        
        %%
		  
        function this = buildCalibrated(this)
            this = this.buildCounts2specificActivity;            
            this = this.buildNative;
            this.product_.counts2specificActivity = this.calibrator_.counts2specificActivity;
            fprintf('counts2specificActivity->%g\n', this.product_.counts2specificActivity);
        end
        function this = buildCounts2specificActivity(this)
            this = this.buildCalibrator;
            this.ensureManualData;
            this.calibrator_ = this.calibrator_.correctedActivities(this.manualData_.mMRDatetime);
            % TODO:  refactor psa manipulations into an abstraction.
            psa = this.calibrator_.decayCorrection.correctedActivities( ...
                  this.manualData_.phantomSpecificActivity, this.manualData_.mMRDatetime);
            this.calibrator_.counts2specificActivity = psa(1) / mean(this.calibrator_.counts(3:end-3));
            this.calibrator_.plotCounts;
            this.product_ = this.calibrator_;
            
%             figure;
%             c_ = this.calibrator_;
%             len = min(length(c_.datetime), length(c_.counts));
%             cd_ = c_.datetime;
%             cc_ = c_.counts;
%             plot(cd_(1:len), cc_(1:len));
%             xlabel('datetime');
%             ylabel('counts');
        end
        function this = buildCalibrator(this)
            this.calibrator_ = mlswisstrace.TwiliteCalibration( ...
                'fqfilename', this.fqfilenameCalibrator, ...
                'sessionData', this.sessionData_, ...
                'manualData', this.manualData_, ...
                'doseAdminDatetime', this.manualData_.mMRDatetime, ...
                'isotope', '18F');
            this.product_ = this.calibrator_;
        end
        function this = buildNative(this)
            this.product_ = mlswisstrace.Twilite( ...
                'fqfilename', this.fqfilename, ...
                'sessionData', this.sessionData_, ...
                'manualData', this.manualData_, ...
                'doseAdminDatetime', this.datetime0, ...
                'isotope', '15O');
        end
        
 		function this = TwiliteBuilder(varargin)
 			%% TWILITEBUILDER 	
            %  @param named fqfilename for target Twilite AIF.
            %  @param named fqfilenameCalibrator for Twilite calibration AIF.   
            %  @param named datetime0  for target Twilite AIF.         
            
            this = this@mlpet.AbstractAifBuilder(varargin{:});            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'fqfilename', '',           @ischar);
            addParameter(ip, 'fqfilenameCalibrator', '', @ischar);
            addParameter(ip, 'datetime0', NaT,           @isdatetime);
            parse(ip, varargin{:});            
            this.fqfilename_           = ip.Results.fqfilename;
            this.fqfilenameCalibrator_ = ip.Results.fqfilenameCalibrator;
            this.datetime0_            = ip.Results.datetime0;
            
            % populate this.fqfilename*_ using mlraichle.StudyCensus as needed
            if (isempty(this.fqfilename_) || isempty(this.fqfilenameCalibrator_))
                this.studyCensus_ = mlraichle.StudyCensus('sessionData', this.sessionData_);
                this.fqfilename_           = this.studyCensus_.arterialSamplingCrv;
                this.fqfilenameCalibrator_ = this.studyCensus_.calibrationCrv;                
            end
            
            % default for mlpet.AbstractAifBuilder.manualData_
            if (isempty(this.manualData_))
                this.manualData_ = mlsiemens.XlsxObjScanData('sessionData', this.sessionData_);
            end            
 		end
    end

    %% PROTECTED
    
    properties (Access = protected)
        datetime0_
        fqfilename_
        fqfilenameCalibrator_
        studyCensus_
    end
    
    methods (Access = protected)
        function ensureManualData(this)
            md = this.manualData_;
            assert(~isempty(md), 'mlswisstrace.TwiliteBuilder.ensureManualData');
            assert(md.mMRDatetime - md.phantomDatetime < hours(24));
            psa = md.phantomSpecificActivity;
            assert(isnumeric(psa), 'mlswisstrace.TwiliteBuilder.ensureManualData');
            assert(isfinite(psa), 'mlswisstrace.TwiliteBuilder.ensureManualData');
            assert(psa > 0, 'mlswisstrace.TwiliteBuilder.ensureManualData');
        end
    end
    
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

