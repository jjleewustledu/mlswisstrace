classdef RadialArteryLee2021Model 
	%% RADIALARTERYLEE2021MODEL  

	%  $Revision$
 	%  was created 14-Mar-2021 17:21:03 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlswisstrace/src/+mlswisstrace.
 	%% It was developed on Matlab 9.9.0.1592791 (R2020b) Update 5 for MACI64.  Copyright 2021 John Joowon Lee.
 	
    properties (Constant) 
        ks_names = {'\alpha' '\beta' 'p' 'dp_F' 't_0' 'steadystate\_fraction' 'bolus_2\_fraction' 'bolus_2\_delay' 'recirc\_fraction' 'recirc\_delay' 'amplitude\_fraction' '\gamma'}
    end
    
	properties 	
        kernel
 		map
        model_kind
        t0_forced
        times_sampled
        tracer
    end
    
    methods (Static)
        function rho = decay_corrected(rho, tracer, t0)
            arguments
                rho double
                tracer {mustBeTextScalar}
                t0 double = 0
            end
            import mlswisstrace.RadialArteryLee2021Model.halflife
            times = (0:(length(rho)-1)) - t0;
            times(1:t0+1) = 0;
            rho = rho .* 2.^(times/halflife(tracer));
        end
        function rho = deconvolved(ks, N, kernel, tracer, model_kind)
            amplitude = ks(11);
            soln = mlswisstrace.RadialArteryLee2021Model.solution(ks, N, tracer, model_kind);
            baseline_frac = ks(9);
            if kernel == 1
                rho = (1 - baseline_frac)*soln;
                return
            end

            % adjust kernel integral as trapz; rescale soln informed by losses from convolutions
            conv_sk = conv(soln, kernel);
            max_sk = max(conv_sk(1:N));
            card_kernel = trapz(kernel);
            %rho = (1 - baseline_frac)*card_kernel*soln; % produces deconvolutions too small by factor of 0.5
            rho = (1 - baseline_frac)*(card_kernel/max_sk)*soln; 
        end
        function tau = halflife(tracer)
            switch upper(tracer)
                case {'FDG' '18F' 'RO948' 'MK6240' 'GTP1' 'ASEM' 'AZAN'}
                    tau = 1.82951 * 3600; % +/- 0.00034 h * sec/h
                case {'HO' 'CO' 'OC' 'OO' '15O'}
                    tau = 122.2416;
                otherwise
                    error('mlswisstrace:ValueError', ...
                        'RadialArteryLee2021Model.halflife.tracer = %s', tracer)
            end            
        end
        function loss = loss_function(ks, kernel, tracer, model_kind, measurement_)
            import mlswisstrace.RadialArteryLee2021Model.sampled
            import mlswisstrace.RadialArteryLee2021Model.decay_corrected
            
            N = length(measurement_);
            estimation = sampled(ks, N, kernel, tracer, model_kind); % \in [0 1] 
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
            m('k1') = struct('min',  0.5,   'max',   1.5,  'init',  0.5,  'sigma', 0.05); % alpha
            m('k2') = struct('min',  0.05,  'max',   0.15, 'init',  0.05, 'sigma', 0.05); % beta in 1/sec
            m('k3') = struct('min',  1,     'max',   3,    'init',  1,    'sigma', 0.05); % p
            m('k4') = struct('min',  0,     'max',   1,    'init',  0,    'sigma', 0.05); % |dp2| for 2nd bolus
            m('k5') = struct('min',  0,     'max', 120,    'init',  0,    'sigma', 0.05); % t0 in sec
            m('k6') = struct('min',  0.1,   'max',   0.3,  'init',  0.2,  'sigma', 0.05); % steady-state fraction in (0, 1), for rising baseline
            m('k7') = struct('min',  0,     'max',   0.1,  'init',  0.05, 'sigma', 0.05); % recirc fraction < 0.5, for 2nd bolus
            m('k8') = struct('min', 15,     'max',  90,    'init', 30,    'sigma', 0.05); % recirc delay in sec
            m('k9') = struct('min',  0,     'max',   0.5,  'init',  0,    'sigma', 0.05); % baseline amplitude fraction \approx 0.05
        end    
        function qs = sampled(ks, N, kernel, tracer, model_kind)
            %% @return the Bayesian estimate of the measured AIF, including baseline, scaled to unity.
            
            baseline_frac = 1 - ks(11);
            scale_frac = 1 - baseline_frac;
            
            if kernel == 1
                W = 10;
                qs = mlswisstrace.RadialArteryLee2021Model.solution(ks, N+W-1, tracer, model_kind);
                qs = mlswisstrace.RadialArteryLee2021Model.move_window(qs, W=W);
                qs = qs/max(qs); % \in [0 1]
                qs = scale_frac*qs + baseline_frac; % \in [0 1]
                return
            end

            qs = mlswisstrace.RadialArteryLee2021Model.solution(ks, N, tracer, model_kind);
            if kernel ~= 1
                qs = conv(qs, kernel);
            end
            qs = qs(1:N);
            qs = qs/max(qs); % \in [0 1] 
            qs = scale_frac*qs + baseline_frac; % \in [0 1]   
                
        end
        function qs = solution(ks, N, tracer, model_kind)
            %% @return the idealized true AIF without baseline, scaled to unity.
            
            import mlswisstrace.RadialArteryLee2021Model
            switch model_kind
                case '1bolus'
                    qs = RadialArteryLee2021Model.solution_1bolus(ks, N, tracer, ks(3));
                case '2bolus'
                    qs = RadialArteryLee2021Model.solution_2bolus(ks, N, tracer, ks(3));
                case '3bolus'
                    qs = RadialArteryLee2021Model.solution_3bolus(ks, N, tracer);
                otherwise
                    error('mlswisstrace:ValueError', ...
                        'RadialArteryLee2021Model.solution.model_kind = %s', model_kind)
            end
        end
        function qs = solution_1bolus(ks, N, tracer, p)
            %% stretched gamma distribution

            import mlswisstrace.RadialArteryLee2021Model.slide
            import mlswisstrace.RadialArteryLee2021Model.halflife
            t = 0:N-1;
            t0 = ks(5);
            a = ks(1);
            b = ks(2);
            
            if (t(1) >= t0) 
                t_ = t - t0;
                qs = t_.^a .* exp(-(b*t_).^p);
            else % k is complex for t - t0 < 0
                t_ = t - t(1);
                qs = t_.^a .* exp(-(b*t_).^p);
                qs = slide(qs, t, t0 - t(1));
            end
            assert(all(imag(qs) == 0))
            qs = qs .* 2.^(-t/halflife(tracer));
            qs = qs/max(qs); % \in [0 1] 
        end
        function qs = solution_2bolus(ks, N, tracer, p)
            %% stretched gamma distribution + rising steadystate

            import mlswisstrace.RadialArteryLee2021Model.slide
            import mlswisstrace.RadialArteryLee2021Model.halflife
            t = 0:N-1;
            t0 = ks(5);
            a = ks(1);
            b = ks(2);
            g = ks(2);
            ss_frac = ks(6);
            
            if (t(1) >= t0) 
                t_ = t - t0;
                k_ = t_.^a .* exp(-(b*t_).^p);
                ss_ = 1 - exp(-g*t_);
                qs = (1 - ss_frac)*k_ + ss_frac*ss_;
            else % k is complex for t - t0 < 0
                t_ = t - t(1);
                k_ = t_.^a .* exp(-(b*t_).^p);
                ss_ = 1 - exp(-g*t_);
                qs = (1 - ss_frac)*k_ + ss_frac*ss_;
                qs = slide(qs, t, t0 - t(1));
            end
            assert(all(imag(qs) == 0))
            qs = qs .* 2.^(-t/halflife(tracer));
            qs = qs/max(qs); % \in [0 1] 
        end
        function qs = solution_3bolus(ks, N, tracer)
            %% stretched gamma distribution + rising steadystate + auxiliary stretched gamma distribution; 
            %  forcing p2 = p - dp2 < p, to be more dispersive

            import mlswisstrace.RadialArteryLee2021Model.solution_1bolus
            import mlswisstrace.RadialArteryLee2021Model.solution_2bolus
            import mlswisstrace.RadialArteryLee2021Model.slide
            recirc_frac = ks(7);
            recirc_delay = ks(8);
            
            qs2 = solution_2bolus(ks, N, tracer, ks(3));
            qs1 = solution_1bolus(ks, N, tracer, ks(3) - ks(4));
            qs1 = slide(qs1, 0:N-1, recirc_delay);
            qs = (1 - recirc_frac)*qs2 + recirc_frac*qs1;
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
        function qs = move_window(qs, opts)
            arguments
                qs double
                opts.W double
            end
            
            P = length(qs)-opts.W+1;
            N = P/opts.W;
            P1 = P + opts.W - 1;
            L = tril(ones(P,P1), opts.W-1) - tril(ones(P,P1), -1);
            L = L/opts.W;
            qs = asrow(L*ascol(qs));
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
            %  @param  model_kind is char.
            %  @param map is containers.Map.
            %  @param kernel is numeric.
            %  @param t0_forced is scalar, default empty.
            %  @param times_sampled is numeric.
            
            import mlswisstrace.RadialArteryLee2021Model.preferredMap
            
            ip = inputParser;
            ip.PartialMatching = false;
            ip.KeepUnmatched = true;
            addParameter(ip, 'tracer', [], @istext)
            addParameter(ip, 'model_kind', [], @istext)
            addParameter(ip, 'map', preferredMap(), @(x) isa(x, 'containers.Map'))
            addParameter(ip, 'kernel', 1, @isnumeric)
            addParameter(ip, 't0_forced', [], @isnumeric)
            addParameter(ip, 'times_sampled', [], @isnumeric)
            parse(ip, varargin{:})
            ipr = ip.Results;
            this.tracer = convertStringsToChars(upper(ipr.tracer));
            this.model_kind = convertStringsToChars(ipr.model_kind);
            this.map = ipr.map;
            this.t0_forced = ipr.t0_forced;
            this = this.adjustMapForTracer();
            this = this.adjustMapForModelKind();
            this.kernel = ipr.kernel;
            this.times_sampled = ipr.times_sampled; 			
 		end
    end 
    
    %% PROTECTED
    
    methods (Access = protected)     
        function this = adjustMapForModelKind(this)
            switch lower(this.model_kind)
                case '1bolus'        
                    this.map('k4') = struct('min',  0,     'max',   0,    'init',  0,    'sigma', 0.05); % dp2 for 2nd bolus

                    this.map('k6') = struct('min',  0,     'max',   0,    'init',  0,    'sigma', 0.05); % steady-state fraction in (0, 1), for rising baseline
                    this.map('k7') = struct('min',  0,     'max',   0,    'init',  0,    'sigma', 0.05); % recirc fraction < 0.5, for 2nd bolus
                    this.map('k8') = struct('min',  0,     'max',   0,    'init',  0,    'sigma', 0.05); % recirc delay in sec
                case '2bolus'
                    this.map('k4') = struct('min',  0,     'max',   0,    'init',  0,    'sigma', 0.05); % dp2 for 2nd bolus

                    this.map('k7') = struct('min',  0,     'max',   0,    'init',  0,    'sigma', 0.05); % recirc fraction < 0.5, for 2nd bolus
                    this.map('k8') = struct('min',  0,     'max',   0,    'init',  0,    'sigma', 0.05); % recirc delay in sec
                case '3bolus'
                otherwise
            end
            if ~isempty(this.t0_forced)
                this.map('k5') = struct('min', this.t0_forced, 'max', this.t0_forced, 'init', this.t0_forced, 'sigma', 0.05); % t0 in sec
            end
        end
        function this = adjustMapForTracer(this)
            switch upper(this.tracer)
                case {'RO948', 'MK6240', 'GTP1', 'ASEM', 'AZAN'}
                    this.map('k1') = struct('min', 0.5,   'max',  10,    'init',  5,    'sigma', 0.05); % alpha
                    this.map('k2') = struct('min', 0.01,  'max',   0.15, 'init',  0.05, 'sigma', 0.05); % beta
                    this.map('k3') = struct('min', 0.25,  'max',   4,    'init',  2,    'sigma', 0.05); % p
                    this.map('k4') = struct('min', 0,     'max',   2,    'init',  1,    'sigma', 0.05); % dp2 for 2nd bolus
                    this.map('k5') = struct('min', 0,     'max',  30,    'init',  0,    'sigma', 0.05); % t0 in sec   
                    this.map('k6') = struct('min', 0.05,  'max',   0.5,  'init',  0.05, 'sigma', 0.05); % steady-state fraction in (0, 1)  
                    this.map('k7') = struct('min', 0.05,  'max',   0.25, 'init',  0.05, 'sigma', 0.05); % recirc fraction < 0.5, for 2nd bolus
                    this.map('k8') = struct('min', 5,     'max',  20,    'init', 10,    'sigma', 0.05); % recirc delay in sec
                case {'FDG' '18F'}
                    this.map('k5') = struct('min',  0,    'max',  30,    'init',  0,    'sigma', 0.05); % t0 in sec   
                    this.map('k6') = struct('min', 0.05,  'max',   0.5,  'init',  0.05, 'sigma', 0.05); % steady-state fraction in (0, 1)  
                    this.map('k7') = struct('min', 0.05,  'max',   0.25, 'init',  0.05, 'sigma', 0.05); % recirc fraction < 0.5, for 2nd bolus
                    this.map('k8') = struct('min', 5,     'max',  20,    'init', 10,    'sigma', 0.05); % recirc delay in sec
                case {'HO' 'OH'}
%                    this.map('k9') = struct('min',  0.05, 'max',   0.25, 'init',  0.05, 'sigma', 0.05); % baseline amplitude fraction \approx 0.05
                case {'CO' 'OC'}  
                    this.map('k1') = struct('min',  0.1,  'max',  10,    'init',  0.25, 'sigma', 0.05); % alpha
                    this.map('k2') = struct('min', 10,    'max',  25,    'init', 15,    'sigma', 0.05); % beta
                    this.map('k3') = struct('min',  0.25, 'max',   1,    'init',  0.5,  'sigma', 0.05); % p

                    this.map('k5') = struct('min',  0,    'max',  30,    'init',  0,    'sigma', 0.05); % t0 in sec            
                    this.map('k6') = struct('min',  0.05, 'max',   0.5,  'init',  0.05, 'sigma', 0.05); % steady-state fraction in (0, 1)      

                    this.map('k8') = struct('min', 30,    'max', 120,    'init', 60,    'sigma', 0.05); % recirc delay in sec
%                    this.map('k9') = struct('min',  0.02, 'max',   0.5,  'init',  0.1,  'sigma', 0.05); % baseline amplitude fraction \approx 0.05
                case 'OO'
                    % allow double inhalation
                    this.map('k1') = struct('min', 1,     'max',   5,    'init',  1,    'sigma', 0.05); % alpha
                    this.map('k2') = struct('min', 0.1,   'max',  25,    'init',  0.1,  'sigma', 0.05); % beta

                    this.map('k5') = struct('min', 5,     'max',  30,    'init',  0,    'sigma', 0.05); % t0 in sec   

                    this.map('k7') = struct('min', 0.05,  'max',   0.49, 'init',  0.05, 'sigma', 0.05); % recirc fraction < 0.5, for 2nd bolus
                    this.map('k8') = struct('min', eps,   'max',  30,    'init', 15,    'sigma', 0.05); % recirc delay in sec
%                    this.map('k9') = struct('min',  0.05, 'max',   0.25, 'init',  0.05, 'sigma', 0.05); % baseline amplitude fraction \approx 0.05
                otherwise
                    % noninformative
            end

            if ~isempty(this.t0_forced)
                this.map('k5') = struct('min', this.t0_forced-1, 'max', this.t0_forced+1, 'init', this.t0_forced, 'sigma', 0.05); % t0 in sec
            end
        end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

