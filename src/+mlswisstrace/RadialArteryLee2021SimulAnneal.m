classdef RadialArteryLee2021SimulAnneal < mloptimization.SimulatedAnnealing
	%% RADIALARTERYLEE2021SIMULANNEAL  

	%  $Revision$
 	%  was created 14-Mar-2021 17:21:10 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlswisstrace/src/+mlswisstrace.
 	%% It was developed on Matlab 9.9.0.1592791 (R2020b) Update 5 for MACI64.  Copyright 2021 John Joowon Lee.
 	
	properties
        ks0
        ks_lower
        ks_upper   
        model_kind
        quiet = false
        visualize = false
        visualize_anneal = false
        zoom = 1
 	end
    
	properties (Dependent) 
        kernel  
        ks
        ks_names
        tracer
    end

	methods
        
        %% GET
        
        function g = get.kernel(this)
            g = this.model.kernel;
        end
        function g = get.ks(this)
            g = this.results_.ks;
        end
        function g = get.ks_names(~)
            g = mlswisstrace.RadialArteryLee2021Model.knames;
        end
        function g = get.tracer(this)
            g = this.model.tracer;
        end
        
        %%
        
        function fprintfModel(this)
            fprintf('RadialArteryLee2021SimulAnneal:\n');  
            fprintf('%s %s:\n', this.tracer, this.model_kind); 
            for ky = 1:length(this.ks)
                fprintf('\t%s = %g\n', this.ks_names{ky}, this.ks(ky));
            end 
            fprintf('\tloss = %g\n', this.loss())
            for ky = this.map.keys
                fprintf('\tmap(''%s'') => %s\n', ky{1}, struct2str(this.map(ky{1})));
            end
        end
        function Q = loss(this)
            Q = this.results_.sse;
        end
        function h = plot_dc(this, varargin)
            ip = inputParser;
            addParameter(ip, 'showKernel', true, @islogical)
            addParameter(ip, 'xlim', [-10 200], @isnumeric)
            addParameter(ip, 'ylim', [], @isnumeric)
            addParameter(ip, 'zoom', [], @isnumeric)
            parse(ip, varargin{:})
            ipr = ip.Results;
            this.zoom = ipr.zoom;
            decay_corrected = @mlswisstrace.RadialArteryLee2021Model.decay_corrected;
            deconvolved = @mlswisstrace.RadialArteryLee2021Model.deconvolved;
            sampled = @mlswisstrace.RadialArteryLee2021Model.sampled;
            N = length(this.kernel);
            M = decay_corrected(this.Measurement, this.tracer);
            M0 = max(this.Measurement);
            
            h = figure;
            samp = M0*sampled(this.ks, this.kernel, this.tracer, this.model_kind);
            samp = decay_corrected(samp, this.tracer);
            deconvolved = M0*deconvolved(this.ks, this.kernel, this.tracer, this.model_kind);
            times = 0:N-1;
            
            if isempty(this.zoom)
                this.zoom = max(deconvolved)/max(this.kernel)/2;
            end
            if this.zoom ~= 1
                leg_kern = sprintf('kernel x%g', this.zoom);
            else
                leg_kern = 'kernel';
            end
            if ipr.showKernel
                plot(times, M, 'o', ...
                    times, samp, ':', ...
                    times, deconvolved, '-', ...
                    times, this.zoom*this.kernel, '--')
                legend({'measured', 'estimated', 'deconvolved', leg_kern})
            else
                plot(times, M, 'o', ...
                    times, samp, ':', ...
                    times, deconvolved, '-')
                legend({'measured', 'estimated', 'deconvolved', leg_kern})
            end
            if ~isempty(ipr.xlim); xlim(ipr.xlim); end
            if ~isempty(ipr.ylim); ylim(ipr.ylim); end
            xlabel('times / s')
            ylabel('activity / (Bq/mL)')
            annotation('textbox', [.25 .5 .5 .2], 'String', sprintfModel(this), 'FitBoxToText', 'on', 'FontSize', 10, 'LineStyle', 'none')
            dbs = dbstack;
            title([dbs(1).name ' DECAY-CORRECTED for ' this.tracer], 'Interpreter', 'none')
        end
        function h = plot(this, varargin)
            ip = inputParser;
            addParameter(ip, 'showKernel', true, @islogical)
            addParameter(ip, 'xlim', [-10 200], @isnumeric)
            addParameter(ip, 'ylim', [], @isnumeric)
            addParameter(ip, 'zoom', [], @isnumeric)
            parse(ip, varargin{:})
            ipr = ip.Results;
            this.zoom = ipr.zoom;
            N = length(this.kernel);
            M = this.Measurement;
            M0 = max(M);
                        
            h = figure;
            samp = M0*this.model.sampled(this.ks, this.kernel, this.tracer, this.model_kind);
            deconvolved = M0*this.model.deconvolved(this.ks, this.kernel, this.tracer, this.model_kind);
            times = 0:N-1;
            
            if isempty(this.zoom)
                this.zoom = max(deconvolved)/max(this.kernel)/2;
            end
            if this.zoom ~= 1
                leg_kern = sprintf('kernel x%g', this.zoom);
            else
                leg_kern = 'kernel';
            end
            if ipr.showKernel
                plot(times, M, 'o', ...
                    times, samp, ':', ...
                    times, deconvolved, '-', ...
                    times, this.zoom*this.kernel, '--')
                legend({'measured', 'estimated', 'deconvolved', leg_kern})
            else
                plot(times, M, 'o', ...
                    times, samp, ':', ...
                    times, deconvolved, '-')
                legend({'measured', 'estimated', 'deconvolved', leg_kern})
            end
            if ~isempty(ipr.xlim); xlim(ipr.xlim); end
            if ~isempty(ipr.ylim); ylim(ipr.ylim); end
            xlabel('times / s')
            ylabel('activity / (Bq/mL)')
            annotation('textbox', [.25 .5 .5 .2], 'String', sprintfModel(this), 'FitBoxToText', 'on', 'FontSize', 10, 'LineStyle', 'none')
            dbs = dbstack;
            title(dbs(1).name)
        end
        function save(this)
            save([this.fileprefix '.mat'], this);
        end
        function saveas(this, fn)
            save(fn, this);
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
 			[ks_,sse,exitflag,output] = simulannealbnd( ...
                @(ks__) ipr.loss_function( ...
                       ks__, this.kernel, this.tracer, this.model_kind, double(this.Measurement)), ...
                this.ks0, this.ks_lower, this.ks_upper, options); 
            
            this.results_ = struct('ks0', this.ks0, 'ks', ks_, 'sse', sse, 'exitflag', exitflag, 'output', output); 
            if ~this.quiet
                fprintfModel(this)
            end
            if this.visualize
                plot(this)
            end
        end 
        function s = sprintfModel(this)
            s = sprintf('RadialArteryLee2021SimulAnneal:\n');
            s = [s sprintf('%s %s:\n', this.tracer, this.model_kind)];
            for ky = 1:length(this.ks)
                s = [s sprintf('\t%s = %g\n', this.ks_names{ky}, this.ks(ky))]; %#ok<AGROW>
            end
            s = [s sprintf('\tloss = %g\n', this.loss())];
            for ky = this.map.keys
                s = [s sprintf('\tmap(''%s'') => %s\n', ky{1}, struct2str(this.map(ky{1})))]; %#ok<AGROW>
            end
        end
		  
 		function this = RadialArteryLee2021SimulAnneal(varargin)
            %% @param tracer is in {'CO' 'OC' 'OO' 'HO' 'FDG'}.
            %  @param model_kind is char.
            
            this = this@mloptimization.SimulatedAnnealing(varargin{:});
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'model_kind', [], @ischar)
            parse(ip, varargin{:})
            ipr = ip.Results;
            assert(~isempty(ipr.model_kind))
            this.model_kind = ipr.model_kind;
 			
            [this.ks_lower,this.ks_upper,this.ks0] = remapper(this);
 		end
 	end 
    
    %% PROTECTED
    
    methods (Access = protected)
        function [m,sd] = find_result(this, lbl)
            ks_ = this.ks;
            assert(strcmp(lbl(1), 'k'))
            ik = str2double(lbl(2));
            m = ks_(ik);
            sd = 0;
        end
        function [lb,ub,ks0] = remapper(this)
            for i = 1:this.map.Count
                lbl = sprintf('k%i', i);
                lb(i)  = this.map(lbl).min; %#ok<AGROW>
                ub(i)  = this.map(lbl).max; %#ok<AGROW>
                ks0(i) = this.map(lbl).init; %#ok<AGROW>
            end
        end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

