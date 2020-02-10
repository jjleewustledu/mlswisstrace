classdef Test_Catheter_DT20190930 < matlab.unittest.TestCase
	%% TEST_CATHETER_DT20190930 

	%  Usage:  >> results = run(mlswisstrace_unittest.Test_Catheter_DT20190930)
 	%          >> result  = run(mlswisstrace_unittest.Test_Catheter_DT20190930, 'test_dt')
 	%  See also:  file:///Applications/Developer/MATLAB_R2014b.app/help/matlab/matlab-unit-test-framework.html

	%  $Revision$
 	%  was created 09-Feb-2020 13:56:59 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlswisstrace/test/+mlswisstrace_unittest.
 	%% It was developed on Matlab 9.7.0.1296695 (R2019b) Update 4 for MACI64.  Copyright 2020 John Joowon Lee.
 	
	properties
        Measurement
 		registry
 		testObj
 	end

	methods (Test)
		function test_afun(this)
 			import mlswisstrace.*;
 			this.assumeEqual(1,1);
 			this.verifyEqual(1,1);
 			this.assertEqual(1,1);
        end
        function test_ctor(this)
            this.testObj.hct = 45;
            this.testObj.t0 = 8.5;
            this.testObj.timeInterpolants = 0:1:299;
            
            figure
            hold on
            for h = 26:2:46
                this.testObj.hct = h;
                plot(this.testObj.timeInterpolants, this.testObj.kernel)
            end
            hold off
        end
        function test_plotall_boxcar(this)
            % kernel, Measurement, Fourier deconv, aifModel, aifKnown
            
            this.testObj.hct = 45;
            this.testObj.t0 = 8.5;
            this.testObj.timeInterpolants = 0:1:299;
            
            tbl_ = this.calibrationTable_(1,:);            
            [this.testObj.timeInterpolants,dt0] = this.observations2times(tbl_.observations);
            [box,idx0,idxF] = this.boxcar( ...
                'tracerModel', this.tracerModel, ...
                'times', this.testObj.timeInterpolants, ...
                'datetime0', dt0, ...
                'inflow', tbl_.inflow, ...
                'outflow', tbl_.outflow);
            box = 0.567*box;
            this.testObj.Measurement = this.calibrationData_.coincidence(idx0:idxF);
            this.testObj.plotall('aifKnown', box)
        end
        function test_plotall_CO(this)
            % 2019 May 23            
            
            twiliteData_ = mlswisstrace.Twilite.createFromDatetime();
            
            this.testObj.hct = 45;
            this.testObj.timeInterpolants = ;
            this.testObj.Measurement = twiliteData_.coincidence(idx0:idxF);
            this.testObj.plotall()
        end
        function test_plotall_OO(this)
        end
        function test_plotall_HO(this)
        end
        function test_deconv(this)
        end
        function test_aifModel(this)
        end
	end

 	methods (TestClassSetup)
		function setupCatheter_DT20190930(this)
 			import mlswisstrace.*;
            this.calibrationData_ = TwiliteCatheterCalibration.create();
            this.calibrationTable_ = this.calibrationData_.tabulateCalibrationMeasurements();
 			this.testObj_ = Catheter_DT20190930;
 		end
	end

 	methods (TestMethodSetup)
		function setupCatheter_DT20190930Test(this)
 			this.testObj = this.testObj_;
 			this.addTeardown(@this.cleanTestMethod);
 		end
    end
    
    %% PRIVATE

	properties (Access = private)
        calibrationData_
        calibrationTable_
 		testObj_
 	end

	methods (Access = private)
		function cleanTestMethod(this)
        end
        
        function [box,idx0,idxF] = boxcar(this, varargin)
            %% 
            %  @return Twilite counts/s
            %  @return idx0
            %  @return idxF
            
            ip = inputParser;
            addParameter(ip, 'tracerModel', [], @(x) isa(x, 'mlpet.TracerModel'))
            addParameter(ip, 'times', [], @isnumeric)
            addParameter(ip, 'datetime0', NaT, @isdatetime)
            addParameter(ip, 'inflow', NaT, @isdatetime)
            addParameter(ip, 'outflow', NaT, @isdatetime)
            parse(ip, varargin{:})
            ipr = ip.Results;
            
            datetimeF = ipr.datetime0 + seconds(ipr.times(end) - ipr.times(1) + 1);
            
            sec_a = floor(seconds(ipr.inflow  - ipr.datetime0));
            sec_b = floor(seconds(ipr.outflow - ipr.inflow));
            sec_c = floor(seconds(datetimeF   - ipr.outflow));
            dt_a  = ipr.datetime0 + seconds(0:1:sec_a-1);
            dt_b  = dt_a(end)     + seconds(1:1:sec_b);
            dt_c  = dt_b(end)     + seconds(1:1:sec_c+1);
            mdl   = ipr.tracerModel;
            box   = [eps*ones(1, sec_a), mdl.twiliteCounts(dt_b), eps*ones(1, sec_c)];
            
            [~,idx0] = min(abs(this.calibrationData_.datetime - dt_a(1)));
            [~,idxF] = min(abs(this.calibrationData_.datetime - dt_c(end)));
            idxF = idxF - 1;
        end
        function [t,dt0] = observations2times(this, obs)
            if iscell(obs)
                obs = obs{1};
            end
            assert(isdatetime(obs))
            if 2 == length(obs)
                Nsec = seconds(obs(2) - obs(1));
                t = 0:1:Nsec-1;
                dt0 = obs(1);
                return
            end
            if length(obs) > 2
                t = seconds(obs - obs(1));                
                dt0 = obs(1);
                return
            end
            t = this.calibrationData_.times;
            dt0 = this.calibrationData_.datetime0;
        end
        function mdl = tracerModel(this)
            xlsx = this.calibrationData_.manualData;
            act = xlsx.countsFdg.TRUEDECAY_APERTURECORRGe_68_Kdpm_G(1)*(1000/60);
            mt  = xlsx.countsFdg.TIMEDRAWN_Hh_mm_ss(1);
            mdl = mlpet.TracerModel( ...
                'activity', act, ...
                'activityUnits', 'Bq/mL', ...
                'measurementTime', mt);
            
            %mdl = mlpet.TracerModel( ...
            %    'activity', 3.7084573e+06, ...
            %    'activityUnits', 'Bq/mL', ...
            %    'measurementTime', datetime(2019,9,30,16,58,0, 'TimeZone', 'America/Chicago'));
        end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

