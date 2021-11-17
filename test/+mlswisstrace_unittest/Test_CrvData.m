classdef Test_CrvData < matlab.unittest.TestCase
	%% TEST_CRVDATA 

	%  Usage:  >> results = run(mlswisstrace_unittest.Test_CrvData)
 	%          >> result  = run(mlswisstrace_unittest.Test_CrvData, 'test_dt')
 	%  See also:  file:///Applications/Developer/MATLAB_R2014b.app/help/matlab/matlab-unit-test-framework.html

	%  $Revision$
 	%  was created 02-Nov-2021 13:18:20 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlswisstrace/test/+mlswisstrace_unittest.
 	%% It was developed on Matlab 9.11.0.1769968 (R2021b) for MACI64.  Copyright 2021 John Joowon Lee.
 	
	properties
        crvFile = fullfile(getenv('CCIR_RAD_MEASUREMENTS_DIR'), ...
            'Twilite', 'CRV_0993', '0993_009_all_20190530.crv')
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
            disp(this.testObj)
        end
        function test_dtTag(this)
            this.verifyEqual(this.testObj.dateTag, '_dt20190530');
        end
        function test_globbed(~)
            for g = globT('0993_*.crv')
                crvdat = mlswisstrace.CrvData(g{1});
                if contains(g{1}, 'subject')
                    figure
                    plot(crvdat)
                    crvdat.writecrv(crvdat.prefix2filename('o15'))
                end
                if contains(g{1}, {'phantom' 'calibrat'})
                    figure
                    plot(crvdat)
                    crvdat.writecrv(crvdat.prefix2filename('fdg'))
                end
            end
        end
        function test_plot(this)
            figure;
            this.testObj.plot()
            this.testObj.XLabel = 'duration';
            figure;
            this.testObj.plot()
            this.testObj.XLabel = 'seconds';
            figure;
            this.testObj.plot()
        end
        function test_plotChannels(this)
            this.testObj.plotChannels()
        end
        function test_plotAll(this)
            this.testObj.plotAll()
        end
        function test_prefix2filename(this)
            this.verifyEqual(this.testObj.prefix2filename('o15'), 'o15_dt20190530.crv');
            this.verifyEqual(this.testObj.prefix2filename('fdg'), 'fdg_dt20190530.crv');
        end
        function test_split(this)
            %[a,b] = this.testObj.split(duration(3,15,0,0));
            %[a,b] = this.testObj.split(seconds(duration(3,15,0,0)));
            [a,b] = this.testObj.split(datetime(2019,5,30,12,40,0, 'TimeZone', 'America/Chicago'));
            figure
            a.plot()
            figure
            b.plot()
        end
        function test_writecrv(this)
            import mlswisstrace.*;
            [a,b] = this.testObj.split(datetime(2019,5,30,12,40,0, 'TimeZone', 'America/Chicago'));
            a.writecrv('o15_dt20190530.crv')
            b.writecrv('fdg_dt20190530.crv')
            a1 = CrvData('o15_dt20190530.crv');
            b1 = CrvData('fdg_dt20190530.crv');
            figure; a1.plot();
            figure; b1.plot();
        end
	end

 	methods (TestClassSetup)
		function setupCrvData(this)
 			import mlswisstrace.*;
            cd(fileparts(this.crvFile)) % containing folder
 			this.testObj_ = CrvData(this.crvFile);
 		end
	end

 	methods (TestMethodSetup)
		function setupCrvDataTest(this)
 			this.testObj = this.testObj_;
 			this.addTeardown(@this.cleanTestMethod);
 		end
	end

	properties (Access = private)
 		testObj_
 	end

	methods (Access = private)
		function cleanTestMethod(this)
            if isfile('a.crv')
                delete("a.crv")
            end
            if isfile('b.crv')
                delete("b.crv")
            end
 		end
	end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

