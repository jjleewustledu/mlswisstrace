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
        
        %%
		  
        function this = buildCalibrator(this)
            this.product_ = mlswisstrace.TwiliteCalibration( ...
                'fqfilename', this.fqfilenameCalibrator, ...
                'sessionData', this.sessionData_, ...
                'doseAdminDatetime', this.datetime0, ...
                'isotope', '15O');
        end
        function this = buildNative(this)
            this.product_ = mlswisstrace.Twilite( ...
                'fqfilename', this.fqfilename, ...
                'sessionData', this.sessionData_, ...
                'scannerData', this.scannerData_, ...
                'manualData', this.manualData_, ...
                'doseAdminDatetime', this.datetime0, ...
                'isotope', '15O');
        end
        function this = buildCalibrated(this)
            this = this.buildCalibrator;
            cal  = this.product;
            cal  = cal.correctedActivities(0, this.datetime0);
            cal.counts2specificActivity = ...
                this.manualData_.phantomSpecificActivity('tzero', this.datetime0) / ...
                mean(cal.boluses(1).counts(this.bolusTimesIndices(cal)));
            
            this = this.buildNative;
            nat  = this.product;
            nat.counts2specificActivity = cal.counts2specificActivity;            
            this.product_ = nat;
        end
 		function this = TwiliteBuilder(varargin)
 			%% TWILITEBUILDER 	
            %  @param fqfilename
            
            this = this@mlpet.AbstractAifBuilder(varargin{:});
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'fqfilename',           @(x) ischar(x) && strcmp(x(end-3:end), '.crv'));
            addParameter(ip, 'fqfilenameCalibrator', @(x) ischar(x) && strcmp(x(end-3:end), '.crv'));
            addParameter(ip, 'datetime0', this.manualData_.mMRDatetime, ...
                                                     @isdatetime);
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
    
    methods (Access = protected)
        function t = bolusTimesIndices(~, twil)
            t = 1:length(twil.boluses(1).times);
        end
    end
    
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

