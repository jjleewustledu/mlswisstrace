classdef Test_Twilite < matlab.unittest.TestCase
	%% TEST_TWILITE 

	%  Usage:  >> results = run(mlswisstrace_unittest.Test_Twilite)
 	%          >> result  = run(mlswisstrace_unittest.Test_Twilite, 'test_dt')
 	%  See also:  file:///Applications/Developer/MATLAB_R2014b.app/help/matlab/matlab-unit-test-framework.html

	%  $Revision$
 	%  was created 23-Jan-2017 19:39:09
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/MATLAB-Drive/mlswisstrace/test/+mlswisstrace_unittest.
 	%% It was developed on Matlab 9.1.0.441655 (R2016b) for MACI64.
 	

	properties
        doseAdminDatetimeOC = datetime(2016,9,23,10,49-2,57-24, 'TimeZone', mldata.TimingData.PREFERRED_TIMEZONE);
        doseAdminDatetimeOO = datetime(2016,9,23,11,15-2,29-24, 'TimeZone', mldata.TimingData.PREFERRED_TIMEZONE);
        doseAdminDatetimeHO = datetime(2016,9,23,11,32-2,25-24, 'TimeZone', mldata.TimingData.PREFERRED_TIMEZONE);
        
        fqfn = '/data/nil-bluearc/raichle/PPGdata/jjlee2/Documents/HYGLY28_VISIT_2_23sep2016_D1.crv'
        fqfnman = '/data/nil-bluearc/raichle/PPGdata/jjlee2/Documents/CCIRRadMeasurements 2016sep23.xlsx'
        mand
 		registry
        sessd
        sessp = '/data/nil-bluearc/raichle/PPGdata/jjlee2/HYGLY28/V2'
 		testObj
        vnumber = 2
        tracer = 'HO'
 	end

	methods (Test)
		function test_afun(this)
 			import mlswisstrace.*;
 			this.assumeEqual(1,1);
 			this.verifyEqual(1,1);
 			this.assertEqual(1,1);
        end
        function test_ctor(this)
            this.verifyClass(this.testObj, 'mlswisstrace.Twilite');
            this.verifyEqual(this.testObj.datetime0, this.doseAdminDatetimeHO);
            this.verifyEqual(this.testObj.doseAdminDatetime, this.doseAdminDatetimeHO);
            this.verifyEqual(this.testObj.dt, 1);
            this.verifyEqual(this.testObj.index0, 1);
            this.verifyEqual(this.testObj.indexF, 7715);
            this.verifyEqual(this.testObj.time0, 0);
            this.verifyEqual(this.testObj.timeF, 7714);
            this.verifyEqual(this.testObj.timeDuration, 7714);
            this.verifyEqual(this.testObj.times(1), 0);
            this.verifyEqual(this.testObj.times(end), 7714);
            this.verifyEqual(this.testObj.timeMidpoints(1),   0.5, 'RelTol', 1e-14);
            this.verifyEqual(this.testObj.timeMidpoints(end), 7714.5);
            this.verifyEqual(this.testObj.taus(1),   1, 'RelTol', 1e-14);
            this.verifyEqual(this.testObj.taus(end), 1);
            this.verifyEqual(this.testObj.isotope, '15O');
            this.verifyEqual(this.testObj.W, nan);
            this.verifyEqual(size(this.testObj.tableTwilite), [12392 9]);
        end
        function test_plot(this)
            plot(this.testObj, '.');
        end
        function test_specificActivity(this)
        end
        function test_timeInterpolants(this)
        end
        function test_timeMidpointInterpolants(this)
        end
        function test_shiftTimes(this)
        end
        function test_shiftWorldlines(this)
        end
	end

 	methods (TestClassSetup)
		function setupTwilite(this)
 			import mlswisstrace.*;
            this.sessd = mlraichle.SessionData( ...
                'studyData', mlraichle.StudyData', 'sessionPath', this.sessp, 'vnumber', this.vnumber, 'tracer', this.tracer);
            this.mand = mlsiemens.XlsxObjScanData( ...
                'sessionData', this.sessd, ...
                'fqfilename', this.fqfnman);
 			this.testObj_ = Twilite( ...
                'fqfilename', this.fqfn, ...
                'sessionData', this.sessd, ...
                'manualData', this.mand, ...
                'isotope', '15O', ...
                'doseAdminDatetime', this.doseAdminDatetimeHO);
 		end
	end

 	methods (TestMethodSetup)
		function setupTwiliteTest(this)
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

