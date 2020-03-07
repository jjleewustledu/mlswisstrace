classdef Test_Munk2008 < matlab.unittest.TestCase
	%% TEST_Munk2008 

	%  Usage:  >> results = run(mlswisstrace_unittest.Test_Munk2008)
 	%          >> result  = run(mlswisstrace_unittest.Test_Munk2008, 'test_dt')
 	%  See also:  file:///Applications/Developer/MATLAB_R2014b.app/help/matlab/matlab-unit-test-framework.html

	%  $Revision$
 	%  was created 06-Feb-2020 18:51:30 by jjlee,
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
	end

 	methods (TestClassSetup)
		function setupMunk2008(this)
            import mlswisstrace.*            
            tcc = TwiliteCatheterCalibration.create();
            tbl = tcc.tabulateCalibrationMeasurements();
            %disp(tcc)
            %tcc.plotCounts()            
            %disp(tbl(1,:))
            this.testObj_ = Munk2008( ...
                'calibrationData', tcc, ...
                'calibrationTable', tbl(5,:));
            this.testObj_.sigma0 = 0.2;
 		end
	end

 	methods (TestMethodSetup)
		function setupMunk2008Test(this)
 			this.testObj = this.testObj_;
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

