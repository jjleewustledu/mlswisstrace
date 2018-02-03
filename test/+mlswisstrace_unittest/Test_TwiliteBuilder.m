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
        fqXlsx
        fqCrv
        fqCrvCal
 		registry
        sessp
 		testObj
 	end

	methods (Test)
		function test_ctor(this)
 			import mlswisstrace.*;
            this.verifyClass(this.testObj.product, 'mlswisstrace.TwiliteBuilder');
 		end
		function test_buildCalibrated(this)
 			import mlswisstrace.*;
            this.testObj = this.testObj.buildCalibrated;
            calibrated   = this.testObj.product;
            this.verifyClass(calibrated, 'mlswisstrace.Twilite');
            this.verifyEqual(calibrated.specificActivity(1:10), [], 'RelTol', 1e-3);
            this.verifyEqual(calibrated.specificActivity(60:70), [], 'RelTol', 1e-3);
            this.verifyEqual(calibrated.specificActivity(120:130), [], 'RelTol', 1e-3);
 		end
	end

 	methods (TestClassSetup)
		function setupTwiliteBuilder(this)
 			import mlswisstrace.*;
            this.sessp = fullfile(getenv('PPG'), 'jjlee2', 'HYGLY28', '');
            sessd = mlraichle.SessionData( ...
                'studyData', mlraichle.StudyData, ...
                'sessionPath', this.sessp, ...
                'sessionDate', datetime('23-Sep-2016'), ...
                'tracer', 'HO');
%             scand = mlsiemens.BiographMMR( ...
%                 mlfourd.NIfTId.load(fullfile(this.sessp, 'V1', 'HO1_V1-AC', 'ho1v1r1.4dfp.ifh')), ...
%                 'sessionData', sessd);
            this.fqXlsx = fullfile(getenv('PPG'), 'jjlee2', 'Documents', 'CCIRRadMeasurements 2016sep23.xlsx');
            mand = mlsiemens.XlsxObjScanData( ...
                'sessionData', sessd, ...
                'fqfilename', this.fqXlsx);
%             calibb = mlpet.CalibrationBuilder( ...
%                 );
            this.fqCrv = fullfile(getenv('PPG'), 'jjlee2', 'Documents', 'HYGLY28_VISIT_2_23sep2016_D1.crv');
            this.fqCrvCal = fullfile(getenv('PPG'), 'jjlee2', 'Documents', 'HYGLY28_VISIT_2_23sep2016_twilite_cal_D1.crv');
 			this.testObj_ = TwiliteBuilder( ...
                'fqfilename', this.fqCrv, ...
                'fqfilenameCalibrator', this.fqCrvCal, ...
                'sessionData', sessd, ...
                'manualData', mand);
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

