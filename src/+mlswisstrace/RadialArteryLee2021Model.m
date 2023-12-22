classdef RadialArteryLee2021Model < handle & mlsystem.IHandle
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

    properties (Dependent)
        artery
        artery_interpolated % double
    end

    methods %% GET
        function g = get.artery(this)
            g = copy(this.artery_);
        end
        function g = get.artery_interpolated(this)
            if ~isempty(this.artery_interpolated_)
                g = this.artery_interpolated_;
                return
            end

            this.artery_interpolated_ = asrow(this.artery.imagingFormat.img);
            g = this.artery_interpolated_;
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
            addParameter(ip, 'Measurement', [], @(x) isnumeric(x));
            parse(ip, varargin{:})
            ipr = ip.Results;
            this.tracer = convertStringsToChars(upper(ipr.tracer));
            this.model_kind = convertStringsToChars(ipr.model_kind);
            this.map = ipr.map;
            this.t0_forced = ipr.t0_forced;
            this.adjustMapForTracer();
            this.adjustMapForModelKind();
            this.kernel = ipr.kernel;
            this.artery_ = mlfourd.ImagingContext2(ipr.Measurement);
            this.times_sampled = 0:(length(ipr.Measurement)-1);
        end
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
            
            % adjust kernel integral as trapz; rescale soln informed by losses from convolutions
            conv_sk = conv(soln, kernel);
            max_sk = max(conv_sk(1:N));
            card_kernel = trapz(kernel);
            %rho = amplitude*card_kernel*soln; % produces deconvolutions
            %inconsistent with measuremed observations
            rho = amplitude*(card_kernel/max_sk)*soln; 
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
            m('k1')  = struct('min',  0.5,   'max',   2,    'init',  0.5,  'sigma', 0.05); % alpha
            m('k2')  = struct('min',  0.05,  'max',   0.15, 'init',  0.05, 'sigma', 0.05); % beta in 1/sec
            m('k3')  = struct('min',  0.25,  'max',   3,    'init',  1,    'sigma', 0.05); % p
            m('k4')  = struct('min', -1,     'max',   0,    'init', -0.5,  'sigma', 0.05); % dp2 for last bolus; p2 = p1 + dp2
            m('k5')  = struct('min',  0,     'max',  30,    'init',  0,    'sigma', 0.05); % t0 in sec
            m('k6')  = struct('min',  0,     'max',   0.2,  'init',  0.05, 'sigma', 0.05); % steady-state fraction in (0, 1), for rising baseline
            m('k7')  = struct('min',  0.3,   'max',   0.7,  'init',  0.3,  'sigma', 0.05); % 2nd bolus fraction
            m('k8')  = struct('min',  0,     'max',  20,    'init',  0,    'sigma', 0.05); % 2nd bolus delay
            m('k9')  = struct('min',  0.2,   'max',   0.4,  'init',  0.3,  'sigma', 0.05); % recirc fraction 
            m('k10') = struct('min',  0,     'max',  20,    'init', 10,    'sigma', 0.05); % recirc delay 
            m('k11') = struct('min',  0.5,   'max',   1,    'init',  0.95, 'sigma', 0.05); % amplitude fraction above baseline \approx 0.95
            m('k12') = struct('min',  0.01,  'max',   0.2,  'init',  0.1,  'sigma', 0.05); % g for steady-state accumulation 
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
            
            import mlaif.ArteryLee2021Model
            switch model_kind
                case '1bolus'
                    qs = ArteryLee2021Model.solution_1bolus(ks, N, tracer, ks(3));
                case '2bolus'
                    qs = ArteryLee2021Model.solution_2bolus(ks, N, tracer, ks(3));
                case '3bolus'
                    qs = ArteryLee2021Model.solution_3bolus(ks, N, tracer);
                case '4bolus'
                    qs = ArteryLee2021Model.solution_4bolus(ks, N, tracer);
                otherwise
                    error('mlaif:ValueError', ...
                        'RadialArteryLee2021Model.solution.model_kind = %s', model_kind)
            end
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
    
    %% PROTECTED

    properties (Access = protected)
        artery_
        artery_interpolated_
    end
    
    methods (Access = protected)
        function adjustMapForTracer(this)
            Data.tracer = this.tracer;
            this.map = mlaif.ArteryLee2021Model.static_adjustMapForTracer(this.map, Data);
        end
        function adjustMapForModelKind(this)
            Data.model_kind = this.model_kind;
            Data.t0_forced = this.t0_forced;
            this.map = mlaif.ArteryLee2021Model.static_adjustMapForModelKind(this.map, Data);
        end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

