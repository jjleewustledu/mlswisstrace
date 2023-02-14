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
        function test_hct(this)
            this.testObj.hct = 45;
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
            
            dt_CO = datetime(2019, 5, 23, 11, 29, 21, 'TimeZone', 'America/Chicago');
            twil_ = mlswisstrace.Twilite.createFromDatetime(dt_CO);
            
            this.testObj.hct = 45;
            this.testObj.timeInterpolants = twil_.timeInterpolants;
            this.testObj.Measurement = twil_.counts;
            this.testObj.plotall()
        end
        function test_plotall_OO(this)
        end
        function test_plotall_HO(this)
        end
        function test_deconv(this)
            cd(fullfile(getenv('SINGULARITY_HOME'), ...
                'CCIR_01351', 'rawdata', 'cnda.wustl.edu', 'R01AA_103_P1', 'Analytic_Chemistry'))
            inveff = (37e3/191.809); % counts/s to Bq/mL
            idx0 = 1030;
            idx_toss = 77;

            crv = mlswisstrace.CrvData.createFromFilename('091522_P01_AA_D1.crv');            
            disp(crv)

            M_ = crv.timetable().Coincidence(idx0:end-idx_toss)*inveff;
            cath = mlswisstrace.Catheter_DT20190930( ...
                'Measurement', M_, ...
                't0', 14.9, ...
                'hct', 41.6, ...
                'tracer', '18F'); % t0 reflects rigid extension + Luer valve + cath in Twilite cradle
            M = zeros(size(crv.timetable().Coincidence));
            M(idx0:end-idx_toss) = cath.deconvBayes();
            crv_deconv = crv;
            crv_deconv.filename = '091522_P01_AA_D1_deconv.crv';
            crv_deconv.coincidence = M;
            crv_deconv.writecrv();
            disp(crv_deconv)

            syringe_t0 = ["12:12:43" "12:13:33" "12:14:28" "12:15:31" "12:16:21" "12:17:38" "12:19:26" "12:21:24" "12:23:20" "12:25:18" "12:27:19" "12:32:19" "12:37:15" "12:52:10" "13:06:57" "13:22:19" "13:37:48"]';
            syringe_tf = ["12:12:50" "12:13:37" "12:14:32" "12:15:34" "12:16:24" "12:17:39" "12:19:29" "12:21:30" "12:23:24" "12:25:22" "12:27:21" "12:32:26" "12:27:18" "12:52:15" "13:07:01" "13:22:26" "13:37:52"]';
            gcounter = [4.38 2.85 3.34 3.36 2.94 2.94 2.72 2.67 2.67 2.64 2.93 2.81 3.44 3.58 3.77 3.22 3.60]*1e3;
            syringe_t0 = datetime(syringe_t0, 'InputFormat', 'HH:mm:ss', 'TimeZone', 'America/Chicago');
            syringe_t0.Month = 9;
            syringe_t0.Day = 15;
            syringe_tf = datetime(syringe_tf, 'InputFormat', 'HH:mm:ss', 'TimeZone', 'America/Chicago');
            syringe_tf.Month = 9;
            syringe_tf.Day = 15;
            syringe_tmid = mean([syringe_t0 syringe_tf], 2);
            crv_syringes = mlswisstrace.CrvData('091522_P01_AA_D1_syringes.crv', 'time', syringe_tmid, 'coincidence', gcounter);
            crv_syringes.writecrv();

            data.crv = crv;
            data.crv_tt = crv.timetable;
            data.crv_tt = data.crv_tt(idx0:end,:);

            data.crv_deconv = crv_deconv;
            data.crv_deconv_tt = crv_deconv.timetable;
            data.crv_deconv_tt = data.crv_deconv_tt(idx0:end,:);
            data.crv_deconv = crv_deconv;
            data.crv_deconv_tt = data.crv_deconv_tt(idx0:end,:);

            data.crv_syringes = crv_syringes;
            data.crv_syringes_tt = crv_syringes.timetable;

            figure; 
            plot(data.crv.time(idx0:end), data.crv.coincidence(idx0:end)*inveff, '.')
            hold on
            plot(data.crv_deconv_tt.Time, data.crv_deconv_tt.Coincidence, '-')
            plot(data.crv_syringes_tt.Time(1:end-6), data.crv_syringes_tt.Coincidence(1:end-6), 'o') % magic number for syringes

            save('test_deconv.mat', 'cath', 'data');
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

