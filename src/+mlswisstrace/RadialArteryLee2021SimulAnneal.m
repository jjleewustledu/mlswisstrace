classdef RadialArteryLee2021SimulAnneal < mlpet.ArterySimulAnneal
	%% RADIALARTERYLEE2021SIMULANNEAL  

	%  $Revision$
 	%  was created 14-Mar-2021 17:21:10 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlswisstrace/src/+mlswisstrace.
 	%% It was developed on Matlab 9.9.0.1592791 (R2020b) Update 5 for MACI64.  Copyright 2021 John Joowon Lee.
 	
	properties
 	end
    
	properties (Dependent) 
    end

	methods
        function h = plot(this, varargin)
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'showKernel', true, @islogical)
            addParameter(ip, 'xlim', [-10 200], @isnumeric)
            addParameter(ip, 'ylim', [], @isnumeric)
            addParameter(ip, 'zoom', [], @isnumeric)
            addParameter(ip, 'scaling', 1, @isnumeric)
            parse(ip, varargin{:})
            ipr = ip.Results;
            if this.kernel == 1
                ipr.showKernel = false;
            end
            this.zoom = ipr.zoom;
            Meas = this.Measurement;  
            N = length(Meas);                     
            Model = this.rescaleModelEstimate( ...
                this.model.sampled(this.ks, N, this.kernel, this.tracer, this.model_kind));
            Deconvolved = this.rescaleModelEstimate( ...
                this.model.deconvolved(this.ks, N, this.kernel, this.tracer, this.model_kind));
            times = 0:N-1;
            if isempty(this.zoom)
                this.zoom = max(Deconvolved)/max(this.kernel)/2;
            end
            

            % build legends
            if this.zoom ~= 1
                leg_kern = sprintf('kernel x%g', this.zoom);
            else
                leg_kern = 'kernel';
            end 

            % plotting implementation
            h = figure;
            if ipr.showKernel
                hold('on')
                plot(times, Meas, 'o', 'MarkerEdgeColor', "#0072BD")
                plot(times, Model, '--', 'Color', "#A2142F", 'LineWidth', 2)
                plot(times, Deconvolved, '-', 'Color', "#0072BD", 'LineWidth', 2)
                plot(times, this.zoom*this.kernel(1:N), '--', 'Color', "#EDB120", 'LineWidth', 2)
                legend({'measured', 'estimated', 'deconvolved', leg_kern}, 'FontSize', 12)
                hold('off')
            else
                hold('on')
                plot(times, Meas, 'o', 'MarkerEdgeColor', "#0072BD")
                plot(times, Model, '--', 'Color', "#A2142F", 'LineWidth', 2)
                plot(times, Deconvolved, '-', 'Color', "#0072BD", 'LineWidth', 2)
                legend({'measured', 'estimated', 'deconvolved'}, 'FontSize', 12)
                hold('off')
            end
            if ~isempty(ipr.xlim); xlim(ipr.xlim); end
            if ~isempty(ipr.ylim); ylim(ipr.ylim); end
            xlabel('times / s', FontSize=14, FontWeight='bold')
            ylabel('activity / Bq', FontSize=14, FontWeight='bold')
            annotation('textbox', [.5 .5 .3 .3], 'String', sprintfModel(this), 'FitBoxToText', 'on', 'FontSize', 10, 'LineStyle', 'none')
            title(clientname(false, 2), FontSize=14)
            set(gcf, position=[300,100,1000,618])
        end
        function this = solve(this, varargin)
            %% @param required loss_function is function_handle.
            
            ip = inputParser;
            addRequired(ip, 'loss_function', @(x) isa(x, 'function_handle'))
            parse(ip, varargin{:})
            ipr = ip.Results;
            
            options_fmincon = optimoptions('fmincon', ...
                'FunctionTolerance', 1e-12, ...
                'OptimalityTolerance', 1e-12, ...
                'TolCon', 1e-14, ...
                'TolX', 1e-14);
            if this.visualize_anneal
                options = optimoptions('simulannealbnd', ...
                    'AnnealingFcn', 'annealingboltz', ...
                    'FunctionTolerance', eps, ...
                    'HybridFcn', {@fmincon, options_fmincon}, ...
                    'InitialTemperature', 20, ...
                    'MaxFunEvals', 50000, ...
                    'ReannealInterval', 200, ...
                    'TemperatureFcn', 'temperatureexp', ...
                    'Display', 'diagnose', ...
                    'PlotFcns', {@saplotbestx,@saplotbestf,@saplotx,@saplotf,@saplotstopping,@saplottemperature});
            else
                options = optimoptions('simulannealbnd', ...
                    'AnnealingFcn', 'annealingboltz', ...
                    'FunctionTolerance', eps, ...
                    'HybridFcn', {@fmincon, options_fmincon}, ...
                    'InitialTemperature', 20, ...
                    'MaxFunEvals', 50000, ...
                    'ReannealInterval', 200, ...
                    'TemperatureFcn', 'temperatureexp');
            end
 			[ks_,loss,exitflag,output] = simulannealbnd( ...
                @(ks__) ipr.loss_function( ...
                       ks__, this.kernel, this.tracer, this.model_kind, double(this.Measurement)), ...
                this.ks0, this.ks_lower, this.ks_upper, options); 
            
            this.product_ = struct('ks0', this.ks0, 'ks', ks_, 'loss', loss, 'exitflag', exitflag, 'output', output); 
            if ~this.quiet
                fprintfModel(this)
            end
            if this.visualize
                plot(this)
            end
        end 
		  
 		function this = RadialArteryLee2021SimulAnneal(varargin)
            this = this@mlpet.ArterySimulAnneal(varargin{:});
 		end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

