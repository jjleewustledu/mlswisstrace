classdef Test_TwiliteBuilder < matlab.unittest.TestCase
	%% TEST_TWILITEBUILDER 

	%  Usage:  >> results = run(mlswisstrace_unittest.Test_TwiliteBuilder)
 	%          >> result  = run(mlswisstrace_unittest.Test_TwiliteBuilder, 'test_dt')
 	%  See also:  file:///Applications/Developer/MATLAB_R2014b.app/help/matlab/matlab-unit-test-framework.html

	%  $Revision$
 	%  was created 24-Jan-2018 17:43:43 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlswisstrace/test/+mlswisstrace_unittest.
 	%% It was developed on Matlab 9.3.0.713579 (R2017b) for MACI64.  Copyright 2018 John Joowon Lee.
 	
	properties
        ccirRadMeasurementsDir = fullfile(getenv('HOME'), 'Documents', 'private', '')
        doseAdminDatetimeHO = datetime(2016,9,23,11,32-2,25-24, 'TimeZone',mlkinetics.Timing.PREFERRED_TIMEZONE)
 		registry
        sessd
        sessf = 'HYGLY28'
        sessp
 		testObj
        vnum = 1
 	end

	methods (Test)
		function test_ctor(this)
 			import mlswisstrace.*;
            this.verifyClass(this.testObj, 'mlswisstrace.TwiliteBuilder');
        end
        function test_buildNative(this)
            this.testObj = this.testObj.buildNative;
            native       = this.testObj.product;
            this.verifyClass(native, 'mlswisstrace.Twilite');
            native.plot;
            native.plotCounts;
            native.plotSpecificActivity; % calibrator.counts2specificActivity == nan
        end
        function test_buildCalibrator(this)
            this.testObj = this.testObj.buildCalibrator;
            calibrator   = this.testObj.product;
            this.verifyClass(calibrator, 'mlswisstrace.TwiliteCalibration0');
            calibrator.plot;
            calibrator.plotCounts;
            calibrator.plotSpecificActivity; % calibrator.counts2specificActivity == nan
        end
		function test_buildCalibrated(this)
            this.testObj = this.testObj.buildCalibrated;
            calibrated   = this.testObj.product;
            this.verifyClass(calibrated, 'mlswisstrace.Twilite');
            %calibrated.plot;
            %calibrated.plotCounts;
            %calibrated.plotSpecificActivity;
            
            this.verifyEqual(length(calibrated.times), 286);  
            this.verifyEqual(calibrated.times(1), 0);       
            this.verifyEqual(calibrated.times(end), 285);
            this.verifyEqual(calibrated.specificActivity(1:3), ...
                1e3*[7.123592148347424   2.039590646288643  -0.926076896578980], 'RelTol', 1e-9);
            this.verifyEqual(calibrated.specificActivity(60:62), ...
                1e3*[78.723279969008601  66.436943005699888  73.639278466949818], 'RelTol', 1e-9);
            this.verifyEqual(calibrated.specificActivity(120:122), ...
                1e3*[20.257262695332610  19.833595903494377  27.035931364744318], 'RelTol', 1e-9);
 		end
		function test_buildCounts2specificActivity(this)
            this.testObj = this.testObj.buildCounts2specificActivity;
            this.verifyEqual(this.testObj.counts2specificActivity, 423.667, 'RelTol', 1e-3);
        end
		function test_counts2specificActivity(this)
            this.verifyEqual(this.testObj.counts2specificActivity, 423.667, 'RelTol', 1e-3);
        end
		function test_dispCounts2specificActivity(this)
            fprintf('%g Bq s/(mL counts) for %s V%i on %s', ...
                this.testObj.counts2specificActivity, ...
                this.testObj.sessionData.sessionFolder, ...
                char(this.testObj.sessionData.datetime));
        end
	end

 	methods (TestClassSetup)
		function setupTwiliteBuilder(this)
 			import mlswisstrace.*;
            setenv('CCIR_RAD_MEASUREMENTS_DIR', this.ccirRadMeasurementsDir);
            this.sessp = fullfile(getenv('PPG'), 'jjlee2', this.sessf, '');
            this.sessd = mlraichle.SessionData( ...
                'studyData', mlraichle.StudyData, ...
                'sessionPath', this.sessp, ...
                'tracer', 'HO');
 			this.testObj_ = TwiliteBuilder( ...
                'sessionData', this.sessd, ...
                'datetime0', this.doseAdminDatetimeHO);
 		end
	end

 	methods (TestMethodSetup)
		function setupTwiliteBuilderTest(this)
 			this.testObj = this.testObj_;
 			this.addTeardown(@this.cleanFiles);
 		end
	end

	properties (Access = private)
 		testObj_
 	end

	methods (Access = private)
		function cleanFiles(this)
 		end
	end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

