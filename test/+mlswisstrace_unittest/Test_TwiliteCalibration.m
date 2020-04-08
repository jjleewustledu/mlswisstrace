classdef Test_TwiliteCalibration < matlab.unittest.TestCase
	%% TEST_TWILITECALIBRATION 

	%  Usage:  >> results = run(mlswisstrace_unittest.Test_TwiliteCalibration)
 	%          >> result  = run(mlswisstrace_unittest.Test_TwiliteCalibration, 'test_dt')
 	%  See also:  file:///Applications/Developer/MATLAB_R2014b.app/help/matlab/matlab-unit-test-framework.html

	%  $Revision$
 	%  was created 07-Mar-2020 10:56:37 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlswisstrace/test/+mlswisstrace_unittest.
 	%% It was developed on Matlab 9.7.0.1296695 (R2019b) Update 4 for MACI64.  Copyright 2020 John Joowon Lee.
 	
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
        function test_legacy_ctor(~)
            fqfn = fullfile(getenv('HOME'), 'Documents', 'private', 'Twilite', 'CRV', 'fdg_dt20190523.crv');
            sesd = mlraichle.SessionData.create('CCIR_00559/ses-E03056/FDG_DT20190523154204.000000-Converted-AC');
            mand = mlpet.CCIRRadMeasurements.createFromSession(sesd);
            obj = mlswisstrace.TwiliteCalibration0( ...
                'fqfilename', fqfn, ...
                'sessionData', sesd, ...
                'manualData', mand, ...
                'doseAdminDatetime', datetime(2019,5,23,15,42,0, 'TimeZone', 'America/Chicago'), ...
                'isotope', '18F');
            disp(obj)
        end
        function test_legacy_factory(~)
            obj = mlswisstrace.TwiliteCalibration0.createFromDate( ...
                datetime(2019,5,23,15,42,0, 'TimeZone', 'America/Chicago'));
            disp(obj)
        end
        function test_TwiliteCalibration(this)
            ses = mlraichle.SessionData.create('CCIR_00559/ses-E03056/FDG_DT20190523154204.000000-Converted-AC');
            obj = mlswisstrace.TwiliteCalibration.createFromSession(ses);
            disp(obj)            
            this.verifyTrue(obj.calibrationAvailable)
            this.verifyEqual(length(obj.invEfficiency), 9)
            this.verifyEqual(mean(obj.invEfficiency), 1.621730386414504, 'RelTol', 1e-12)
            obj.plot()
        end
        function test_census(this)
            singularity = getenv('SINGULARITY_HOME');
            for proj = globFoldersT(fullfile(singularity, 'CCIR_*'))
                for ses = globFoldersT(fullfile(proj{1}, 'ses-E*'))
                    for fdg = globFoldersT(fullfile(ses{1}, 'FDG_DT*-Converted-AC'))
                        str = fullfile(mybasename(proj{1}), mybasename(ses{1}), mybasename(fdg{end}));
                        sesd = mlraichle.SessionData.create(str);
                        try
                            if datetime(sesd) > datetime(2016, 4, 1, 'TimeZone', 'America/Chicago')
                                disp(sesd)
                                tcal = mlswisstrace.TwiliteCalibration.createFromSession(sesd);
                                this.verifyTrue(isrow(tcal.invEfficiencyf(sesd)));
                                tcal.plot()
                            end
                        catch ME
                            handwarning(ME)
                        end
                    end
                end
            end
        end
        function test_arrayOutOfBounds(this)
            sesd = mlraichle.SessionData.create('CCIR_00559/ses-E216027/FDG_DT20170613135932.000000-Converted-AC');
            disp(sesd)
            tcal = mlswisstrace.TwiliteCalibration.createFromSession(sesd);
            this.verifyTrue(isrow(tcal.invEfficiencyf(sesd)));
            tcal.plot()
            
        end
        function test_findProximalSession(this)
            sesd = mlraichle.SessionData.create('CCIR_00754/ses-E186470/FDG_DT20160408121938.000000-Converted-AC');
            disp(sesd)
            tcal = mlswisstrace.TwiliteCalibration.createFromSession(sesd);
            tcal.plot()            
            
        end
        function test_shortCalibration(this)
            sesd = mlraichle.SessionData.create('CCIR_00559/ses-E251344/FDG_DT20180601125239.000000-Converted-AC');
            disp(sesd)
            tcal = mlswisstrace.TwiliteCalibration.createFromSession(sesd);
            this.verifyTrue(isrow(tcal.invEfficiencyf(sesd)));
            tcal.plot()            
            
        end
	end

 	methods (TestClassSetup)
		function setupTwiliteCalibration(this)
 			import mlswisstrace.*;
 			this.testObj_ = [];
        end
	end

 	methods (TestMethodSetup)
		function setupTwiliteCalibrationTest(this)
 			this.testObj = this.testObj_;
 			this.addTeardown(@this.cleanTestMethod);
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

