classdef RadialArteryLee2021Model 
	%% RADIALARTERYLEE2021MODEL  

	%  $Revision$
 	%  was created 14-Mar-2021 17:21:03 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlswisstrace/src/+mlswisstrace.
 	%% It was developed on Matlab 9.9.0.1592791 (R2020b) Update 5 for MACI64.  Copyright 2021 John Joowon Lee.
 	
    properties (Constant)
        knames = {'\alpha' '\beta' 'p' '\gamma' 't_0' 'recirc\_fraction' 'bolus\_fraction' 'bolus\_delay' 'baseline\_fraction'}
    end
    
	properties 	
        kernel
 		map
        times_sampled
        tracer
    end
    
    methods (Static)
        function rho = decay_corrected(rho, tracer)
            import mlswisstrace.RadialArteryLee2021Model.halflife
            times = 0:(length(rho)-1);
            rho = rho .* 2.^(times/halflife(tracer));
        end
        function rho = deconvolved(ks, kernel, tracer, model_kind)
            N = length(kernel);
            soln = mlswisstrace.RadialArteryLee2021Model.solution(ks, N, tracer, model_kind);
            baseline_frac = ks(end);
            conv_sk = conv(soln, kernel);
            max_sk = max(conv_sk(1:N));
            card_kernel = trapz(kernel);
            rho = (1 - baseline_frac)*(card_kernel/max_sk)*soln; 
        end
        function tau = halflife(tracer)
            switch upper(tracer)
                case 'FDG'
                    tau = 1.82951 * 3600; % +/- 0.00034 h * sec/h
                case {'HO' 'CO' 'OC' 'OO'}                    
                    tau = 122.2416;
                otherwise
                    error('mlswisstrace:ValueError', ...
                        'RadialArteryLee2021Model.halflife.tracer = %s', tracer)
            end            
        end
        function loss = loss_function(ks, kernel, tracer, model_kind, measurement_)
            import mlswisstrace.RadialArteryLee2021Model.sampled
            import mlswisstrace.RadialArteryLee2021Model.decay_corrected
            
            estimation = sampled(ks, kernel, tracer, model_kind); % \in [0 1] 
            measurement = measurement_/max(measurement_); % \in [0 1] 
            positive = measurement > 0.01;
            eoverm = estimation(positive)./measurement(positive);
            
            estimation_dc = decay_corrected(estimation, tracer);
            estimation_dc = estimation_dc/max(estimation_dc); % \in [0 1]  
            measurement_dc = decay_corrected(measurement_, tracer);
            measurement_dc = measurement_dc/max(measurement_dc); % \in [0 1]             
            eoverm_dc = estimation_dc(positive)./measurement_dc(positive);
            
            loss = mean(abs(1 - 0.5*eoverm - 0.5*eoverm_dc));
        end
        function m = preferredMap()
            m = containers.Map;
            m('k1') = struct('min', 0.005, 'max',   5,    'init', 0.05,  'sigma', 0.05); % alpha
            m('k2') = struct('min', 0.01,  'max',   1,    'init', 0.15,  'sigma', 0.05); % beta
            m('k3') = struct('min', 0.1,   'max',  10,    'init', 1.8,   'sigma', 0.05); % p
            m('k4') = struct('min', 0.001, 'max',   0.1,  'init', 0.008, 'sigma', 0.05); % gamma
            m('k5') = struct('min', 0,     'max', 100,    'init', 0,     'sigma', 1   ); % t0
            m('k6') = struct('min', 0.01,  'max',   0.2,  'init', 0.1,   'sigma', 0.05); % recirc fraction in (0, 1)
            m('k7') = struct('min', 0.01,  'max',   0.2,  'init', 0.1,   'sigma', 0.05); % bolus fraction < 0.5, for 2nd bolus
            m('k8') = struct('min', 0.02,  'max',   0.2,  'init', 0.15,  'sigma', 0.05); % bolus delay fraction \in [0, 1]
            m('k9') = struct('min', 0,     'max',   0.25, 'init', 0.1,   'sigma', 0.05); % baseline fraction \approx 0.05
        end    
        function qs = sampled(ks, kernel, tracer, model_kind)
            %% @return the Bayesian estimate of the measured AIF, including baseline, scaled to unity.
            
            N = length(kernel);
            baseline_frac = ks(9);
            scale_frac = 1 - baseline_frac;
            
            qs = mlswisstrace.RadialArteryLee2021Model.solution(ks, N, tracer, model_kind);
            qs = conv(qs, kernel);            
            qs = qs(1:N);
            qs = qs/max(qs); % \in [0 1] 
            qs = scale_frac*qs + baseline_frac; % \in [0 1]   
        end
        function qs = sampled1(ks, kernel, tracer, model_kind)
            %% @return the Bayesian estimate of the measured AIF, including baseline, scaled to unity.
            
            N = length(kernel);
            baseline = ks(9);
            
            qs = mlswisstrace.RadialArteryLee2021Model.deconvolved(ks, kernel, tracer, model_kind);
            qs = conv(qs, kernel);            
            qs = qs(1:N);
            qs = qs + baseline; % \in [0 1]   
        end
        function qs = solution(ks, N, tracer, model_kind)
            %% @return the idealized true AIF without baseline, scaled to unity.
            
            import mlswisstrace.RadialArteryLee2021Model
            switch model_kind
                case '1bolus'
                    qs = RadialArteryLee2021Model.solution_1bolus(ks, N, tracer);
                case '2bolus'
                    qs = RadialArteryLee2021Model.solution_2bolus(ks, N, tracer);
                case '3bolus'
                    qs = RadialArteryLee2021Model.solution_3bolus(ks, N, tracer);
                otherwise
                    error('mlswisstrace:ValueError', ...
                        'RadialArteryLee2021Model.solution.model_kind = %s', model_kind)
            end
        end
        function qs = solution_1bolus(ks, N, tracer)
            import mlswisstrace.RadialArteryLee2021Model.halflife
            t = 0:N-1;
            t0 = ks(5);
            a = ks(1);
            b = ks(2);
            p = ks(3);
            
            if (t(1) >= t0) 
                t_ = t - t0;
                qs = t_.^a .* exp(-(b*t_).^p);
            else % k is complex for t - t0 < 0
                t_ = t - t(1);
                qs = t_.^a .* exp(-(b*t_).^p);
                qs = mlswisstrace.RadialArteryLee2021Model.slide(qs, t, t0 - t(1));
            end
            assert(all(imag(qs) == 0))
            qs = qs .* 2.^(-t/halflife(tracer));
            qs = qs/max(qs); % \in [0 1] 
        end
        function qs = solution_2bolus(ks, N, tracer)
            import mlswisstrace.RadialArteryLee2021Model.halflife
            t = 0:N-1;
            t0 = ks(5);
            a = ks(1);
            b = ks(2);
            p = ks(3);
            g = ks(4);
            recirc_frac = ks(6);
            
            if (t(1) >= t0) 
                t_ = t - t0;
                k_ = t_.^a .* exp(-(b*t_).^p);
                r_ = 1 - exp(-g*t_);
                qs = (1 - recirc_frac)*k_ + recirc_frac*r_;
            else % k is complex for t - t0 < 0
                t_ = t - t(1);
                k_ = t_.^a .* exp(-(b*t_).^p);
                r_ = 1 - exp(-g*t_);
                qs = (1 - recirc_frac)*k_ + recirc_frac*r_;
                qs = mlswisstrace.RadialArteryLee2021Model.slide(qs, t, t0 - t(1));
            end
            assert(all(imag(qs) == 0))
            qs = qs .* 2.^(-t/halflife(tracer));
            qs = qs/max(qs); % \in [0 1] 
        end
        function qs = solution_3bolus(ks, N, tracer)
            import mlswisstrace.RadialArteryLee2021Model.solution_1bolus
            import mlswisstrace.RadialArteryLee2021Model.solution_2bolus
            import mlswisstrace.RadialArteryLee2021Model.slide
            bolus_frac = ks(7);
            bolus_delay = ks(8)*N;
            
            qs2 = solution_2bolus(ks, N, tracer);
            qs3 = slide(qs2, 0:N-1, bolus_delay);
            qs = (1 - bolus_frac)*qs2 + bolus_frac*qs3;
            qs = qs/max(qs); % \in [0 1] 
        end
        
        %% UTILITIES
          
        function [vec,T] = ensureRow(vec)
            if (~isrow(vec))
                vec = vec';
                T = true;
                return
            end
            T = false; 
        end    
        function conc = slide(conc, t, Dt)
            %% SLIDE slides discretized function conc(t) to conc(t - Dt);
            %  Dt > 0 will slide conc(t) towards later times t.
            %  Dt < 0 will slide conc(t) towards earlier times t.
            %  It works for inhomogeneous t according to the ability of interp1 to interpolate.
            %  It may not preserve information according to the Nyquist-Shannon theorem.  
            
            import mlswisstrace.RadialArteryLee2021Model;
            [conc,trans] = RadialArteryLee2021Model.ensureRow(conc);
            t            = RadialArteryLee2021Model.ensureRow(t);
            
            tspan = t(end) - t(1);
            tinc  = t(2) - t(1);
            t_    = [(t - tspan - tinc) t];   % prepend times
            conc_ = [zeros(size(conc)) conc]; % prepend zeros
            conc_(isnan(conc_)) = 0;
            conc  = interp1(t_, conc_, t - Dt); % interpolate onto t shifted by Dt; Dt > 0 shifts to right
            
            if (trans)
                conc = conc';
            end
        end
    end

	methods 
		  
 		function this = RadialArteryLee2021Model(varargin)
 			%% RADIALARTERYLEE2021MODEL
 			%  @param tracer is char.
            %  @param map is containers.Map.
            %  @param kernel is numeric.
            %  @param times_sampled is numeric.
            
            import mlswisstrace.RadialArteryLee2021Model.preferredMap
            
            ip = inputParser;
            ip.PartialMatching = false;
            ip.KeepUnmatched = true;
            addParameter(ip, 'tracer', [], @ischar)
            addParameter(ip, 'map', preferredMap(), @(x) isa(x, 'containers.Map'))
            addParameter(ip, 'kernel', [], @isnumeric)
            addParameter(ip, 'times_sampled', [], @isnumeric)
            parse(ip, varargin{:})
            ipr = ip.Results;
            this.tracer = upper(ipr.tracer);
            this.map = ipr.map;
            this = this.adjustMapForTracer();
            this.kernel = ipr.kernel;
            this.times_sampled = ipr.times_sampled; 			
 		end
    end 
    
    %% PROTECTED
    
    methods (Access = protected)        
        function this = adjustMapForTracer(this)
            switch upper(this.tracer)
                case 'FDG'                    
                case 'HO'
                case {'CO' 'OC'}  
                    this.map('k1') = struct('min', 0.001, 'max',   1,    'init',  0.01,  'sigma', 0.05); % alpha
                    this.map('k2') = struct('min', 1,     'max',  20,    'init',  5,     'sigma', 0.05); % beta
                    this.map('k3') = struct('min', 0.1,   'max',   0.5,  'init',  0.25,  'sigma', 0.05); % p
                    this.map('k4') = struct('min', 1,     'max',  20,    'init',  1,     'sigma', 0.05); % gamma
            
                    this.map('k6') = struct('min', 0.01,  'max',   0.5,  'init',  0.05,  'sigma', 0.05); % recirc fraction in (0, 1)
                    this.map('k7') = struct('min', 0,     'max',   0.05, 'init',  0,     'sigma', 0.05); % bolus fraction < 0.5, for 2nd bolus
                    this.map('k8') = struct('min', 0,     'max',   0.5,  'init',  0,     'sigma', 0.05); % bolus delay fraction \in [0, 1]
                case 'OO'
                otherwise
                    % noninformative
            end
        end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

