classdef TwiliteBuilder < mlpet.AbstractAifBuilder
	%% TWILITEBUILDER  

	%  $Revision$
 	%  was created 12-Dec-2017 16:44:27 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlswisstrace/src/+mlswisstrace.
 	%% It was developed on Matlab 9.3.0.713579 (R2017b) for MACI64.  Copyright 2017 John Joowon Lee.
 	
	properties (Dependent)
        datetime0
        fqfilename
        fqfilenameCalibrator
        counts2specificActivity
 	end

	methods 
        
        %% GET
        
        function g = get.datetime0(this)
            g = this.datetime0_;
        end
        function g = get.fqfilename(this)
            g = this.fqfilename_;
        end
        function g = get.fqfilenameCalibrator(this)
            g = this.fqfilenameCalibrator_;
        end     
        function g = get.counts2specificActivity(this)
            g = this.product_.counts2specificActivity;
        end
        
        %%
		  
        function this = buildCalibrator(this)
            this.product_ = mlswisstrace.TwiliteCalibration( ...
                'fqfilename', this.fqfilenameCalibrator, ...
                'sessionData', this.sessionData_, ...
                'manualData', this.manualData_, ...
                'doseAdminDatetime', this.manualData_.mMRDatetime, ...
                'isotope', '18F');
            this.calibrator_ = this.product_;
        end
        function this = buildNative(this)
            this.product_ = mlswisstrace.Twilite( ...
                'fqfilename', this.fqfilename, ...
                'sessionData', this.sessionData_, ...
                'manualData', this.manualData_, ...
                'doseAdminDatetime', this.datetime0, ...
                'isotope', '15O');
        end
        function this = buildCalibrated(this)
            this = this.buildCalibrator;
            this.calibrator_ = this.calibrator_.correctedActivities(this.manualData_.mMRDatetime);
            % TODO:  refactor psa manipulations into an abstraction.
            psa = this.calibrator_.decayCorrection.correctedActivities( ...
                  this.manualData_.phantomSpecificActivity, this.manualData_.mMRDatetime);
            this.calibrator_.counts2specificActivity = psa(1) / mean(this.calibrator_.counts(3:end-3));
            
            this = this.buildNative;
            this.product_.counts2specificActivity = this.calibrator_.counts2specificActivity;
            fprintf('counts2specificActivity->%g\n', this.product_.counts2specificActivity);
        end
        
 		function this = TwiliteBuilder(varargin)
 			%% TWILITEBUILDER 	
            %  @param named fqfilename for target Twilite AIF.
            %  @param named datetime0  for target Twilite AIF.
            %  @param named fqfilenameCalibrator for Twilite calibration AIF.            
            
            this = this@mlpet.AbstractAifBuilder(varargin{:});            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'fqfilename',           @(x) ischar(x) && strcmp(x(end-3:end), '.crv'));
            addParameter(ip, 'fqfilenameCalibrator', @(x) ischar(x) && strcmp(x(end-3:end), '.crv'));
            addParameter(ip, 'datetime0', NaT,       @isdatetime);
            parse(ip, varargin{:});            
            this.fqfilename_           = ip.Results.fqfilename;
            this.fqfilenameCalibrator_ = ip.Results.fqfilenameCalibrator;
            this.datetime0_            = ip.Results.datetime0;
 		end
    end 

    %% PROTECTED
    
    properties (Access = protected)
        datetime0_
        fqfilename_
        fqfilenameCalibrator_
    end
    
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

