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
        fqCrv
        fqCrvCal
 		registry
        sessp
 		testObj
        
        doseAdminDatetimeHO  = datetime(2016,9,23,11,32-2,25-24, 'TimeZone', mldata.TimingData.PREFERRED_TIMEZONE);
        doseAdminDatetimeCal = datetime(2016,9,23,14,9,52,       'TimeZone', mldata.TimingData.PREFERRED_TIMEZONE);
 	end

	methods (Test)
		function test_ctor(this)
 			import mlswisstrace.*;
            this.verifyClass(this.testObj, 'mlswisstrace.TwiliteBuilder');
        end
        function test_buildCalibrator(this)
            this.testObj = this.testObj.buildCalibrator;
            calibrator   = this.testObj.product;
            this.verifyClass(calibrator, 'mlswisstrace.TwiliteCalibration');
            calibrator.plot;
            calibrator.plotCounts;
            % calibrator.plotSpecificActivity; % calibrator.counts2specificActivity == nan
        end
        function test_buildNative(this)
            this.testObj = this.testObj.buildNative;
            native       = this.testObj.product;
            this.verifyClass(native, 'mlswisstrace.Twilite');
            native.plot;
            native.plotCounts;
            % native.plotSpecificActivity; % calibrator.counts2specificActivity == nan
        end
		function test_buildCalibrated(this)
            this.testObj = this.testObj.buildCalibrated;
            calibrated   = this.testObj.product;
            this.verifyClass(calibrated, 'mlswisstrace.Twilite');
            calibrated.plot;
            calibrated.plotCounts;
            calibrated.plotSpecificActivity;
            
            this.verifyEqual(length(calibrated.times), 358);  
            this.verifyEqual(calibrated.times(1), 0);       
            this.verifyEqual(calibrated.times(end), 357);
            this.verifyEqual(calibrated.specificActivity(1:3), ...
                [8.348512858610855   2.989932512153655  -0.135906023279712], 'RelTol', 1e-9);
            this.verifyEqual(calibrated.specificActivity(60:62), ...
                [83.815186071216402  70.865283567278183  78.456605724759214], 'RelTol', 1e-9);
            this.verifyEqual(calibrated.specificActivity(120:122), ...
                [22.191512086958621  21.744963724753855  29.336285882234886], 'RelTol', 1e-9);
 		end
	end

 	methods (TestClassSetup)
		function setupTwiliteBuilder(this)
 			import mlswisstrace.*;
            setenv('CCIR_RAD_MEASUREMENTS_DIR', this.ccirRadMeasurementsDir);
            this.sessp = fullfile(getenv('PPG'), 'jjlee2', 'HYGLY28', '');
            sessd = mlraichle.SessionData( ...
                'studyData', mlraichle.StudyData, ...
                'sessionPath', this.sessp, ...
                'sessionDate', datetime('23-Sep-2016'), ...
                'tracer', 'HO');
%             scand = mlsiemens.BiographMMR( ...
%                 mlfourd.NIfTId.load(fullfile(this.sessp, 'V1', 'HO1_V1-AC', 'ho1v1r1.4dfp.ifh')), ...
%                 'sessionData', sessd);
            mand = mlsiemens.XlsxObjScanData('sessionData', sessd);
%             calibb = mlpet.CalibrationBuilder( ...
%                 );
            this.fqCrv = fullfile(getenv('CCIR_RAD_MEASUREMENTS_DIR'), 'HYGLY28_VISIT_2_23sep2016_D1.crv');
            this.fqCrvCal = fullfile(getenv('CCIR_RAD_MEASUREMENTS_DIR'), 'HYGLY28_VISIT_2_23sep2016_twilite_cal_D1.crv');
 			this.testObj_ = TwiliteBuilder( ...
                'fqfilename', this.fqCrv, ...
                'fqfilenameCalibrator', this.fqCrvCal, ...
                'sessionData', sessd, ...
                'manualData', mand, ...
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

