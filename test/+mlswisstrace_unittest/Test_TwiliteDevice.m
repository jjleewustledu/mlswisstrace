classdef Test_TwiliteDevice < matlab.unittest.TestCase
	%% TEST_TWILITEDEVICE 

	%  Usage:  >> results = run(mlswisstrace_unittest.Test_TwiliteDevice)
 	%          >> result  = run(mlswisstrace_unittest.Test_TwiliteDevice, 'test_dt')
 	%  See also:  file:///Applications/Developer/MATLAB_R2014b.app/help/matlab/matlab-unit-test-framework.html

	%  $Revision$
 	%  was created 14-Mar-2020 20:08:18 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlswisstrace/test/+mlswisstrace_unittest.
 	%% It was developed on Matlab 9.7.0.1296695 (R2019b) Update 4 for MACI64.  Copyright 2020 John Joowon Lee.
 	
	properties
        datetime0                  = datetime(2019,5,23,13,00,53,859, 'TimeZone', mlpipeline.ResourcesRegistry.instance().preferredTimeZone); 
        datetimeF                  = datetime(2019,5,23,13, 3,41,859, 'TimeZone', mlpipeline.ResourcesRegistry.instance().preferredTimeZone); 
        datetimeMeasured           = datetime(2019,5,23, 9,42,37,859, 'TimeZone', mlpipeline.ResourcesRegistry.instance().preferredTimeZone);         
        datetimeForDecayCorrection = datetime(2019,5,23,12,59,00,000, 'TimeZone', mlpipeline.ResourcesRegistry.instance().preferredTimeZone); 
        radMeas        
 		registry
        sesd
        sesf_ho = 'CCIR_00559/ses-E03056/HO_DT20190523125900.000000-Converted-AC'
        sesf_oo = 'CCIR_00559/ses-E03056/OO_DT20190523123738.000000-Converted-AC'
        sesf_oc = 'CCIR_00559/ses-E03056/OC_DT20190523122016.000000-Converted-AC'
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
            o = this.testObj;
            this.verifyEqual(mean(o.baseline), 80.016666666666666)
            this.verifyEqual( std(o.baseline), 7.896559359462456)
            this.verifyTrue( o.calibrationAvailable)
            this.verifyEqual(o.hct, 39.8, 'RelTol', 1e-4)
            this.verifyEqual(o.datetimeForDecayCorrection, this.datetimeForDecayCorrection)
            this.verifyEqual(o.decayCorrected, false)
            this.verifyEqual(o.timeForDecayCorrection, 1.178214100000000e+04)
            this.verifyEqual(o.datetime0, this.datetime0)
            this.verifyEqual(o.datetimeF, this.datetimeF)
            this.verifyEqual(length(o.datetimeInterpolants), 169)
            this.verifyEqual(o.datetimeMeasured, this.datetimeMeasured)
            this.verifyEqual(o.datetimeWindow, duration(0,2,48))
            this.verifyEqual(length(o.datetimes), 169)
            this.verifyEqual(o.index0, 11897)
            this.verifyEqual(o.indexF, 12065)
            this.verifyEqual(o.time0, 11896)
            this.verifyEqual(o.timeF, 12064)
            this.verifyEqual(o.timeWindow, 168)
            disp(o)
        end
        function test_invEfficiencyf(this)
            this.verifyEqual(this.testObj.invEfficiencyf(this.sesd), 1.587388992738947, 'RelTol', 1e-10)
        end
        function test_plot_ho(this)
            plot(this.testObj)            
            plot(this.testObj, 'this.datetime', 'this.countRate')
        end
        function test_plot_oo(this)
            sesd_ = mlraichle.SessionData.create(this.sesf_oo);
            o = mlswisstrace.TwiliteDevice.createFromSession(sesd_);
            plot(o)            
            plot(o, 'this.datetime', 'this.countRate')
        end
        function test_plot_oc(this)
            sesd_ = mlraichle.SessionData.create(this.sesf_oc);
            o = mlswisstrace.TwiliteDevice.createFromSession(sesd_);
            plot(o)            
            plot(o, 'this.datetime', 'this.countRate')
        end
	end

 	methods (TestClassSetup)
		function setupTwiliteDevice(this)
            this.sesd = mlraichle.SessionData.create(this.sesf_ho);
            this.radMeas = mlpet.CCIRRadMeasurements.createFromSession(this.sesd);
 		end
	end

 	methods (TestMethodSetup)
		function setupTwiliteDeviceTest(this)
 			this.testObj = mlswisstrace.TwiliteDevice.createFromSession(this.sesd);
 			this.addTeardown(@this.cleanTestMethod);
 		end
	end

	properties (Access = private)
 	end

	methods (Access = private)
		function cleanTestMethod(this)
 		end
	end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

