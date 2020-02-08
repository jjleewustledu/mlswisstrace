classdef Test_CatheterModel2 < matlab.unittest.TestCase
	%% TEST_CATHETERMODEL2 

	%  Usage:  >> results = run(mlswisstrace_unittest.Test_CatheterModel2)
 	%          >> result  = run(mlswisstrace_unittest.Test_CatheterModel2, 'test_dt')
 	%  See also:  file:///Applications/Developer/MATLAB_R2014b.app/help/matlab/matlab-unit-test-framework.html

	%  $Revision$
 	%  was created 03-Feb-2020 18:33:55 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlswisstrace/test/+mlswisstrace_unittest.
 	%% It was developed on Matlab 9.7.0.1261785 (R2019b) Update 3 for MACI64.  Copyright 2020 John Joowon Lee.
 	
	properties
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
        function test_plotMap(this)
            this.testObj.plotMap
        end
        function test_run(this)
            disp(datestr(now))
            main = this.testObj.run(this.testObj);
            disp(main.apply.results)
        end
        function test_run_varying(this)
%            this.testObj.run_varying(this.testObj, 'STEP_Initial', [.1 .05 .01 .005 .001])
            this.testObj.run_varying(this.testObj, 'MCMC_Counter', [30 40 60 70])
%            this.testObj.run_varying(this.testObj, 'MAX', [500 1000 2000 4000])
%            this.testObj.run_varying(this.testObj, 'n', [10 15 20])
        end
	end

 	methods (TestClassSetup)
		function setupCatheterModel2(this)            
            import mlswisstrace.*
            
            tcc = TwiliteCatheterCalibration.create();
            tbl = tcc.tabulateCalibrationMeasurements();
            %disp(tcc)
            %tcc.plotCounts()            
            %disp(tbl(1,:))
            this.testObj_ = CatheterModel2( ...
                'calibrationData', tcc, ...
                'calibrationTable', tbl(5,:));
            %this.testObj_.fixed_scale = 0.4802;
            this.testObj_.sigma0 = 0.02;
 		end
	end

 	methods (TestMethodSetup)
		function setupCatheterModel2Test(this)
 			this.testObj = copy(this.testObj_);
 			this.addTeardown(@this.cleanTestMethod);
            rng('default')
 		end
	end

	properties (Access = private)
 		testObj_
 	end

	methods (Access = private)
		function cleanTestMethod(this)
 		end
	end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

