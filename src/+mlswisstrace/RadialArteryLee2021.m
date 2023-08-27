classdef RadialArteryLee2021 < handle & mlio.AbstractHandleIO & matlab.mixin.Heterogeneous & matlab.mixin.Copyable
	%% RADIALARTERYLEE2021 provides a strategy design pattern for inferring cerebral AIFs
    %  from measurements sampling the radial artery and a model kernel for delay and dispersion
    %  from the cannulation of the radial artery.

	%  $Revision$
 	%  was created 14-Mar-2021 17:12:35 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlswisstrace/src/+mlswisstrace.
 	%% It was developed on Matlab 9.9.0.1592791 (R2020b) Update 5 for MACI64.  Copyright 2021 John Joowon Lee.
 	
	properties  
        measurement % expose for performance when used strategies for solve
        model       %
    end

    properties (Dependent)
        strategy
    end

	methods

        %% GET

        function g = get.strategy(this)
            g = this.strategy_;
        end

        %%

        function rho = deconvolved(this)
            M0 = max(this.measurement);
            N = length(this.measurement);
            ks = this.strategy_.ks;
            mdl = this.model;
            rho = M0*this.model.deconvolved(ks, N, mdl.kernel, mdl.tracer, mdl.model_kind);
        end
        function Q = loss(this)
            Q = this.strategy_.loss();
        end
        function h = plot(this, varargin)
            h = this.strategy_.plot(varargin{:});
            set(h, position=[100,100,1000,618])
        end
        function h = plot_dc(this, varargin)
            h = this.strategy_.plot_dc(varargin{:});
        end
        function rho = sampled(this)
            M0 = max(this.measurement);
            N = length(this.measurement);
            ks = this.strategy_.ks;
            mdl = this.model;
            p = [];
            error('mlswisstrace:notImplementedError', 'RadialArteryLee2021.sampled')
        end
        function this = solve(this, varargin)
            %% @param required loss_function is function_handle.
            
            this.strategy_ = solve(this.strategy_, @mlswisstrace.RadialArteryLee2021Model.loss_function);
        end
        function writetable(this)
            rho_Bq_mL = this.deconvolved()';
            N = length(rho_Bq_mL);
            times_sec = (0:N-1)';
            T = table(times_sec, rho_Bq_mL);
            writetable(T, strcat(this.fqfileprefix, '-deconvolved.csv'));
        end
		  
 		function this = RadialArteryLee2021(varargin)
 			%% RADIALARTERYLEE2021
            %  @param Measurement is numeric.  *****
            %  @param solver is in {'simulanneal'}.

            %  for mlswisstrace.RadialArteryLee2021Model: 
            %  @param tracer \in {'CO' 'OC' 'OO' 'HO' 'FDG'}, passed to model.  *****
            %  @param model_kind is char, e.g. '1bolus', '2bolus', '3bolus', passed to model.  *****
            %  @param map is a containers.Map.  Default := RadialArteryLee2021Model.preferredMap.
 			%  @param kernel is numeric, default := 1.
            %  @param t0_forced is scalar, default empty, passed to model.  *****
            %
            %  for mlswisstrace.RadialArteryLee2021SimulAnneal:
            %  @param context is mlswisstrace.RadialArteryLee2021.
            %  @param fileprefix.
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'Measurement', [], @(x) isnumeric(x));
            addParameter(ip, 'solver', 'simulanneal', @ischar);
            parse(ip, varargin{:});
            ipr = ip.Results;
            this.measurement = ipr.Measurement;            
 			this.model = mlswisstrace.RadialArteryLee2021Model(varargin{:});
                        
            switch lower(ipr.solver)
                case 'simulanneal'
                    this.strategy_ = mlswisstrace.RadialArteryLee2021SimulAnneal( ...
                        'context', this, varargin{:});
                otherwise
                    error('mlswisstrace:NotImplementedError', ...
                        'RadialArteryLee2021.ipr.solver->%s', ipr.solver)
            end
 			
 		end
 	end 
    
    %% PROTECTED
    
    properties (Access = protected)
        strategy_ % for solve
    end
    
    methods (Access = protected)
        function that = copyElement(this)
            %%  See also web(fullfile(docroot, 'matlab/ref/matlab.mixin.copyable-class.html'))
            
            that = copyElement@matlab.mixin.Copyable(this);
            that.strategy_ = copy(this.strategy_);
        end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

