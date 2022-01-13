classdef Test_RadialArteryLee2021 < matlab.unittest.TestCase
	%% TEST_RADIALARTERYLEE2021 

	%  Usage:  >> results = run(mlswisstrace_unittest.Test_RadialArteryLee2021)
 	%          >> result  = run(mlswisstrace_unittest.Test_RadialArteryLee2021, 'test_dt')
 	%  See also:  file:///Applications/Developer/MATLAB_R2014b.app/help/matlab/matlab-unit-test-framework.html

	%  $Revision$
 	%  was created 14-Mar-2021 17:12:35 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlswisstrace/test/+mlswisstrace_unittest.
 	%% It was developed on Matlab 9.9.0.1592791 (R2020b) Update 5 for MACI64.  Copyright 2021 John Joowon Lee.
 	
	properties
        hct = 45
        N = 300
 		registry
 		testObj
        tracer = 'OO'
 	end

	methods (Test)
		function test_solve(this) 	
 			import mlswisstrace.*;		
 			obj = RadialArteryLee2021( ...
                'tracer', this.tracer, ...
                'kernel', this.kernel(this.N), ...
                'model_kind', '3bolus', ...
                'Measurement', this.Simulation());
            obj = obj.solve();
            plot(obj)
        end
		function test_solve_noisy(this) 	
 			import mlswisstrace.*;		
 			obj = RadialArteryLee2021( ...
                'tracer', this.tracer, ...
                'kernel', this.kernel(this.N), ...
                'model_kind', '3bolus', ...
                'Measurement', this.Simulation('noise', 0.02));
            obj = obj.solve();
            plot(obj)
        end
        function test_Measurement(this)
            M = this.Measurement(this.tracer);
            plot(0:length(M)-1, M)
        end
		function test_solve_Measurement(this) 	
 			import mlswisstrace.*;	            
            M = this.Measurement(this.tracer);
            N_ = length(M);
 			obj = RadialArteryLee2021( ...
                'tracer', this.tracer, ...
                'kernel', this.kernel(N_), ...
                'model_kind', '3bolus', ...
                'Measurement', M);
            obj = obj.solve();
            plot(obj, 'xlim', [-10 300])
            plot_dc(obj, 'xlim', [-10 300])
            
            figure
            plot(obj.deconvolved)
        end
        function test_solution_1bolus(this)	
 			import mlswisstrace.*;
            Nk = 5;
            ks_names = RadialArteryLee2021Model.knames(1:Nk);
            ks_init = [0.5 0.1 1 0 0];
            ks_combinations = [ 0.1 0.5 1 2 ; ...
                                0.05 0.1 0.2 0.4; ...
                                0.5 1 1.5 2; ...
                                Inf Inf Inf Inf; ...
                                0 10 20 40];
                            
            figure;
            for ik = 1:Nk
                subplot(Nk, 1, ik)
                ylabel(['\delta ' ks_names{ik}])
                ks = ks_init;
                hold('on')
                for icomb = 1:4
                    ks(ik) = ks_combinations(ik, icomb);
                    qs = RadialArteryLee2021Model.solution_1bolus(ks, 120, 'HO', ks(3));
                    plot(0:119, qs);
                end
                C = cellfun(@(x) num2str(x), num2cell(ks_combinations(ik,:)), 'UniformOutput', false);
                legend(C)
                hold('off')
            end
        end
        function test_solution_2bolus(this)	
 			import mlswisstrace.*;
            Nk = 6;
            ks_names = RadialArteryLee2021Model.knames(1:Nk);
            ks_init = [0.5 0.1 1 0.1 0 0.25];
            ks_combinations = [ 0.1 0.5 1 2 ; ...
                                0.05 0.1 0.2 0.4; ...
                                0.5 1 1.5 2; ...
                                0.05 0.02 0.01 0.005; ...
                                0 10 20 40; ...
                                0.05 0.1 0.2 0.4];
                            
            figure;
            for ik = 1:Nk
                subplot(Nk, 1, ik)
                ylabel(['\delta ' ks_names{ik}])
                ks = ks_init;
                hold('on')
                for icomb = 1:4
                    ks(ik) = ks_combinations(ik, icomb);
                    qs = RadialArteryLee2021Model.solution_2bolus(ks, 120, 'HO', ks(3));
                    plot(0:119, qs);
                end
                C = cellfun(@(x) num2str(x), num2cell(ks_combinations(ik,:)), 'UniformOutput', false);
                legend(C)
                hold('off')
            end
        end
        function test_solution_3bolus(this)	
 			import mlswisstrace.*;
            Nk = 8;
            ks_names = RadialArteryLee2021Model.knames(1:Nk);
            ks_init = [0.5 0.2 1.5 0.01 0 0.25 0.1 0.1];
            ks_combinations = [ 0.1 0.5 1 2 ; ...
                                0.05 0.1 0.2 0.4; ...
                                0.5 1 1.5 2; ...
                                0.05 0.02 0.01 0.005; ...
                                0 10 20 40; ...
                                0.05 0.1 0.2 0.4; ...
                                0.01 0.05 0.1 0.2; ...
                                0.1 0.2 0.3 0.4];
                            
            figure;
            for ik = 1:Nk
                subplot(Nk, 1, ik)
                ylabel(['\delta ' ks_names{ik}])
                ks = ks_init;
                hold('on')
                for icomb = 1:4
                    ks(ik) = ks_combinations(ik, icomb);
                    qs = RadialArteryLee2021Model.solution_3bolus(ks, 120, 'HO');
                    plot(0:119, qs);
                end
                C = cellfun(@(x) num2str(x), num2cell(ks_combinations(ik,:)), 'UniformOutput', false);
                legend(C)
                hold('off')
            end
        end
        function test_solution_CO(this)	
 			import mlswisstrace.*;
            Nk = 8;
            ks_names = RadialArteryLee2021Model.knames(1:Nk);
            ks_init = [0.05 10 0.4 3 0 0.1 0.05 0.25 0.1];
            ks_combinations = [ 0.05 0.5 1 2; ...
                                1 5 10 20; ...
                                0.1 0.25 0.5 0.75; ...
                                0.01 0.1 1 5; ...
                                0 10 20 40; ...
                                0.01 0.05 0.1 0.2; ...
                                0.005 0.0075 0.01 0.1; ...
                                0.05 0.1 0.2 0.3];
                            
            figure;
            for ik = 1:Nk
                subplot(Nk, 1, ik)
                ylabel(['\delta ' ks_names{ik}])
                ks = ks_init;
                hold('on')
                for icomb = 1:4
                    ks(ik) = ks_combinations(ik, icomb);
                    qs = RadialArteryLee2021Model.solution_3bolus(ks, 120, 'CO');
                    plot(0:119, qs);
                end
                C = cellfun(@(x) num2str(x), num2cell(ks_combinations(ik,:)), 'UniformOutput', false);
                legend(C)
                hold('off')
            end
        end
        function test_sampled(this)
 			import mlswisstrace.*;
            Nk = 8;
            ks_names = RadialArteryLee2021Model.knames(1:Nk);
            ks_init = [0.05 0.15 1.8 0.008 0 0.1 0.1 0.15 0.1];
            ks_combinations = [ 0.005 0.1 1 5; ...
                                0.01 0.1 0.5 1; ...
                                0.1 1 3 10; ...
                                0.1 0.05 0.01 0.001; ...
                                0 10 20 40; ...
                                0.01 0.05 0.1 0.2; ...
                                0.01 0.05 0.1 0.5; ...
                                0.1 0.15 0.2 0.25];
            krnl = this.kernel(120);
                            
            figure;
            for ik = 1:Nk
                subplot(Nk, 1, ik)
                ylabel(['\delta ' ks_names{ik}])
                ks = ks_init;
                hold('on')
                for icomb = 1:4
                    ks(ik) = ks_combinations(ik, icomb);
                    qs = RadialArteryLee2021Model.sampled(ks, krnl, 'HO', '3bolus');
                    plot(0:119, qs);
                end
                C = cellfun(@(x) num2str(x), num2cell(ks_combinations(ik,:)), 'UniformOutput', false);
                legend(C)
                hold('off')
            end
        end
	end

 	methods (TestClassSetup)
		function setupRadialArteryLee2021(this)
 			import mlswisstrace.*;
 		end
	end

 	methods (TestMethodSetup)
		function setupRadialArteryLee2021Test(this)
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
        function k = kernel(this, N)
            %% including regressions on catheter data of 2019 Sep 30
            
            a =  0.0072507*this.hct - 0.13201;
            b =  0.0059645*this.hct + 0.69005;
            p = -0.0014628*this.hct + 0.58306;
            t =  0:N-1;
            w =  0.00040413*this.hct + 1.2229;
            t0 = 9.8671; % mean from data of 2019 Sep 30
            
            if (t(1) >= t0) % saves extra flops from slide()
                t_   = t - t0;
                k = t_.^a .* exp(-(b*t_).^p);
                k = abs(k);
            else
                t_   = t - t(1);
                k = t_.^a .* exp(-(b*t_).^p);
                k = mlswisstrace.RadialArteryLee2021Model.slide(abs(k), t, t0 - t(1));
            end
            
            k = k .* (1 + w*t); % better to apply slide, simplifying w
            sumk = sum(k);
            if sumk > eps
                k = k/sumk;
            end            
        end
        function M = Measurement(this, tracer)
            dev = mlswisstrace.TwiliteDevice.createFromSession(this.sessionData(tracer));
            M = dev.countRate();
        end
        function S = Simulation(this, varargin)
            ip = inputParser;
            addParameter(ip, 'tracer', this.tracer, @ischar)
            addParameter(ip, 'noise', [], @isnumeric)
            addParameter(ip, 'N', this.N, @isnumeric)
            parse(ip, varargin{:})
            ipr = ip.Results;
            
            import mlswisstrace.*;
            krnl = this.kernel(ipr.N);
            switch upper(ipr.tracer)
                case {'OC' 'CO'}
                    ks = [0.01 20 0.25 3 0 0.1 0.05 0.25 0.1];
                    model_kind = '3bolus';
                case 'OO'
                    ks = [0.05 0.15 1.8 0.008 0 0.1 0.1 0.15 0.1];
                    model_kind = '3bolus';
                case 'HO'                    
                    ks = [0.05 0.15 1.8 0.008 0 0.1 0.1 0.15 0.1];
                    model_kind = '3bolus';
                case 'FDG'
                otherwise
                    error('mlswisstrace_unittest:ValueError', ...
                        'Test_RadialArteryLee2021.Simluation.tracer = %s', ipr.tracer)
            end
            S = RadialArteryLee2021Model.sampled(ks, krnl, ipr.tracer, model_kind);
            if ~isempty(ipr.noise)
                S = S + ipr.noise*randn(size(S));
            end
        end
        function sesd = sessionData(~, tracer)
            switch upper(tracer)
                case {'OC' 'CO'}
                    sesd = mlraichle.SessionData.create('CCIR_00559/ses-E03056/OC_DT20190523122016.000000-Converted-AC');
                case 'OO'
                    sesd = mlraichle.SessionData.create('CCIR_00559/ses-E03056/OO_DT20190523114543.000000-Converted-AC');
                case 'HO'
                    sesd = mlraichle.SessionData.create('CCIR_00559/ses-E03056/HO_DT20190523120249.000000-Converted-AC');
                case 'FDG'
                    sesd = mlraichle.SessionData.create('CCIR_00559/ses-E03056/FDG_DT20190523132832.000000-Converted-AC');
                otherwise
                    error('mlswisstrace_unittest:ValueError', ...
                        'Test_RadialArteryLee2021.sessionData.tracer = %s', tracer)
            end
        end
	end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

