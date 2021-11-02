classdef Test_TwiliteData < matlab.unittest.TestCase
	%% TEST_TWILITE 

	%  Usage:  >> results = run(mlswisstrace_unittest.Test_TwiliteData)
 	%          >> result  = run(mlswisstrace_unittest.Test_TwiliteData, 'test_dt')
 	%  See also:  file:///Applications/Developer/MATLAB_R2014b.app/help/matlab/matlab-unit-test-framework.html

	%  $Revision$
 	%  was created 23-Jan-2017 19:39:09
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/MATLAB-Drive/mlswisstrace/test/+mlswisstrace_unittest.
 	%% It was developed on Matlab 9.1.0.441655 (R2016b) for MACI64. 	

	properties
        doseAdminDatetime1st = datetime(2019,5,23,11,29,21, 'TimeZone', mlpipeline.ResourcesRegistry.instance().preferredTimeZone);
        doseAdminDatetimeOC  = datetime(2019,5,23,12,22,53, 'TimeZone', mlpipeline.ResourcesRegistry.instance().preferredTimeZone);
        doseAdminDatetimeOO  = datetime(2019,5,23,12,40,17, 'TimeZone', mlpipeline.ResourcesRegistry.instance().preferredTimeZone);
        doseAdminDatetimeHO  = datetime(2019,5,23,13,0,52,  'TimeZone', mlpipeline.ResourcesRegistry.instance().preferredTimeZone);
        
        fqfn_o15_crv = fullfile(getenv('CCIR_RAD_MEASUREMENTS_DIR'), 'Twilite/CRV/o15_dt20190523.crv')
        fqfn_fdg_crv = fullfile(getenv('CCIR_RAD_MEASUREMENTS_DIR'), 'Twilite/CRV/fdg_dt20190523.crv')
        fqfnRadm = fullfile(getenv('CCIR_RAD_MEASUREMENTS_DIR'), 'CCIRRadMeasurements 2019may23.xlsx')
        radm
 		registry
        sesd_fdg
        sesf_fdg = 'CCIR_00559/ses-E03056/FDG_DT20190523154204.000000-Converted-AC';
        sesp_fdg = fullfile(getenv('SINGULARITY_HOME'), 'CCIR_00559/ses-E03056/FDG_DT20190523154204.000000-Converted-AC'); 
        sesd_ho
        sesf_ho  = 'CCIR_00559/ses-E03056/HO_DT20190523125900.000000-Converted-AC';
        sesp_ho  = fullfile(getenv('SINGULARITY_HOME'), 'CCIR_00559/ses-E03056/HO_DT20190523125900.000000-Converted-AC');        
        sesd_oo
        sesf_oo  = 'CCIR_00559/ses-E03056/OO_DT20190523123738.000000-Converted-AC';
        sesp_oo  = fullfile(getenv('SINGULARITY_HOME'), 'CCIR_00559/ses-E03056/OO_DT20190523123738.000000-Converted-AC');        
        sesd_oc
        sesf_oc  = 'CCIR_00559/ses-E03056/OC_DT20190523122016.000000-Converted-AC';
        sesp_oc  = fullfile(getenv('SINGULARITY_HOME'), 'CCIR_00559/ses-E03056/OC_DT20190523122016.000000-Converted-AC');
 		testObj
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
            o = this.testObj;
            this.verifyClass(o, 'mlswisstrace.TwiliteData');
            disp(o)
            
            this.verifyEqual(o.pumpRate, 5)
            this.verifyEqual(o.tableTwilite{1,'datetime'}, datetime(2019,5,23,13,13,30.804, 'TimeZone', 'America/Chicago'))
            this.verifyEqual(o.tableTwilite{1,'coincidences'}, 88)
            this.verifyEqual(o.tableTwilite{1,'channel1'}, 1153)
            this.verifyEqual(o.tableTwilite{1,'channel2'}, 1065)
            this.verifyEqual(o.datetimeForDecayCorrection, datetime(2019,5,23,15,42,04, 'TimeZone', 'America/Chicago'))
            this.verifyEqual(o.halflife, 6.586236000000000e+03)
            this.verifyEqual(o.isotope, '18F');
            this.verifyEqual(o.datetimeMeasured, datetime(2019,5,23,13,13,30.804, 'TimeZone', 'America/Chicago'))
            this.verifyEqual(o.dt, 1)            
            this.verifyEqual(o.index0, 1);
            this.verifyEqual(o.indexF, 9526);
            this.verifyEqual(o.indices, 1:9526);
            this.verifyEqual(o.taus, ones(1, 9526));
            this.verifyEqual(o.time0, 0);
            this.verifyEqual(o.timeF, 9525);
            this.verifyEqual(o.timeWindow, 9525);
            this.verifyEqual(o.times, 0:9525);

            this.verifyEqual(size(o.countRate), [1 9526]);
            this.verifyEqual(size(o.activity), [1 9526]);
            this.verifyEqual(size(o.activityDensity), [1 9526]);
        end
        function test_plot_fdg(this)
            plot(this.testObj);
            plot(this.testObj, ...
                'this.times', ...
                'this.activityDensity(''decayCorrected'', true)')
        end
        function test_plot_ho(this)
 			import mlswisstrace.*;			
 			o = TwiliteData.createFromSession(this.sesd_ho);
            o.datetimeForDecayCorrection = this.doseAdminDatetimeHO;
            disp(o)
            fprintf('HO datetimeForDecayCorrection: %s\n', o.datetimeForDecayCorrection)
            fprintf('HO timeForDecayCorrection: %s\n', o.timeForDecayCorrection)
            plot(o);
            p = plot(o, ...
                'this.times(11910:12070)', ...
                'this.activityDensity(''decayCorrected'', true, ''index0'', 11910, ''indexF'', 12070)');
        end
        function test_plot_oo(this)
 			import mlswisstrace.*;			
 			o = TwiliteData.createFromSession(this.sesd_oo);
            o.datetimeForDecayCorrection = this.doseAdminDatetimeOO;
            disp(o)
            fprintf('OO datetimeForDecayCorrection: %s\n', o.datetimeForDecayCorrection)
            fprintf('OO timeForDecayCorrection: %s\n', o.timeForDecayCorrection)
            plot(o);
            p = plot(o, ...
                'this.times(10670:10850)', ...
                'this.activityDensity(''decayCorrected'', true, ''index0'', 10670, ''indexF'', 10850)');
        end
        function test_plot_oc(this)
 			import mlswisstrace.*;			
 			o = TwiliteData.createFromSession(this.sesd_oc);
            o.datetimeForDecayCorrection = this.doseAdminDatetimeOC;
            disp(o)
            fprintf('OC datetimeForDecayCorrection: %s\n', o.datetimeForDecayCorrection)
            fprintf('OC timeForDecayCorrection: %s\n', o.timeForDecayCorrection)
            plot(o);
            p = plot(o, ...
                'this.times(8550:8710)', ...
                'this.activityDensity(''decayCorrected'', true, ''index0'', 8550, ''indexF'', 8710)');
        end
        function test_findBaseline(this)
 			import mlswisstrace.*;			
 			o = TwiliteData.createFromSession(this.sesd_oc);
            o.findBaseline(this.doseAdminDatetime1st);
            this.verifyEqual(mean(o.baseline), 79.002655005466181, 'RelTol', 1e-12)
            this.verifyEqual(std( o.baseline), 8.867088941807351,  'RelTol', 1e-12)
        end
        function test_findBolus(this)
 			import mlswisstrace.*;			
 			o = TwiliteData.createFromSession(this.sesd_oc);
            o.findBaseline(this.doseAdminDatetime1st);
            o.findBolus(this.doseAdminDatetimeOC);
            this.verifyEqual(o.index0, 9629)
            this.verifyEqual(o.indexF, 9901)
            p = plot(o, ...
                'this.times(this.index0:this.indexF)', ...
                'this.activityDensity(''decayCorrected'', true, ''index0'', this.index0, ''indexF'',this.indexF)');
        end
        function test_countRate(this)
        end
        function test_activityDensity(this)
        end
        function test_timeInterpolants(this)
        end
        function test_shiftWorldlines(this)
 			import mlswisstrace.*;			
 			o = TwiliteData.createFromSession(this.sesd_ho);
            o.datetimeForDecayCorrection = this.doseAdminDatetimeHO;
            o.index0 = 11910;
            o.indexF = 12070;
            disp(o)
            fprintf('HO datetimeForDecayCorrection: %s\n', o.datetimeForDecayCorrection)
            fprintf('HO timeForDecayCorrection: %s\n', o.timeForDecayCorrection)
            plot(o);
            o.shiftWorldlines(-60);
            plot(o);
            title('Test\_TwiliteData.test\_shiftWorldlines()')
        end
	end

 	methods (TestClassSetup)
		function setupTwilite(this)
            this.sesd_fdg = mlraichle.SessionData.create(this.sesf_fdg);
            this.sesd_ho  = mlraichle.SessionData.create(this.sesf_ho);
            this.sesd_oo  = mlraichle.SessionData.create(this.sesf_oo);
            this.sesd_oc  = mlraichle.SessionData.create(this.sesf_oc);
            this.radm     = mlpet.RadMeasurements.createFromSession('sessionData', this.sesd_fdg);
 		end
	end

 	methods (TestMethodSetup)
		function setupTwiliteTest(this) 
 			import mlswisstrace.*;			
 			this.testObj = TwiliteData.createFromSession(this.sesd_fdg);
            this.testObj.datetimeForDecayCorrection = datetime(this.sesd_fdg);
 			this.addTeardown(@this.cleanFiles);
 		end
	end

	methods (Access = private)
		function cleanFiles(this)
 		end
	end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

