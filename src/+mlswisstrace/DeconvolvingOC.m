classdef DeconvolvingOC < mlswisstrace.DeconvolvingPLaif
	%% DECONVOLVINGOC  

	%  $Revision$
 	%  was created 29-Aug-2018 03:25:02 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlswisstrace/src/+mlswisstrace.
 	%% It was developed on Matlab 9.4.0.813654 (R2018a) for MACI64.  Copyright 2018 John Joowon Lee.
 	    
    methods (Static)        
        function this = plotPLaif(varargin)
            ip = inputParser;
            addRequired(ip, 'times', @isnumeric);
            addRequired(ip, 'sActivity', @isnumeric);
            addOptional(ip, 'label', 'mlswisstrace.DeconvolvingPLaif', @ischar);
            parse(ip, varargin{:});
            t = ip.Results.times;
            sa = ip.Results.sActivity;
            
            import mlswisstrace.*;
            this = mlswisstrace.DeconvolvingOC( ...
                {t t}, ...
                {sa sa.*DeconvolvingOC.decayCorrection(t)}, ...
                'QType', 'SumSquaredResiduals');
            
            this.S0 = 4e7;
            this.a  = 0.001;
            this.b  = 0.2;
            this.e  = 0;   % steady-state contribution
            this.f  = 0.9; % fraction of S0 for recirculation
            this.g  = 0.05;
            this.p  = 1;
            this.q  = 0.3;
            this.t0 = 25;
            this.t1 = 0; % recirculation starts at t0 + t1
            this.plot;
        end
        function this = runPLaif(varargin)
            ip = inputParser;
            addRequired(ip, 'times', @isnumeric);
            addRequired(ip, 'sActivity', @isnumeric);
            addOptional(ip, 'label', 'mlswisstrace.DeconvolvingPLaif', @ischar);
            parse(ip, varargin{:});
            t = ip.Results.times;
            sa = ip.Results.sActivity;
            
            import mlswisstrace.*;
            this = mlswisstrace.DeconvolvingOC( ...
                {t t}, ...
                {sa sa.*DeconvolvingOC.decayCorrection(t)}, ...
                'QType', 'SumSquaredResiduals');
            
            this.S0 = 4e7;
            this.a  = 0.004;
            this.b  = 0.2;
            this.e  = 0;   % steady-state contribution
            this.f  = 0.9; % fraction of S0 for recirculation
            this.g  = 0.05;
            this.p  = 1;
            this.q  = 0.3;
            this.t0 = 20;
            this.t1 = 0; % recirculation starts at t0 + t1
            this = this.estimateParameters(this.mapParams);
            this.plot;
            %saveFigures(sprintf('fig_%s_%s', this.fileprefix, ip.Results.label));  
        end
        function dc   = decayCorrection(times)
            rad = mlpet.Radionuclides('[15O]');
            dc = 2.^((times - 1)/rad.halflife);
        end
    end

	methods         
        function m = getMapParams(this)
            m = containers.Map;
            m('S0') = struct('fixed', 0, 'min', this.S0/1e2, 'mean', this.S0, 'max', 1e2*this.S0);
            m('a')  = struct('fixed', 0, 'min', 1e-4,        'mean', this.a,  'max', 1e-2); 
            m('b')  = struct('fixed', 0, 'min', 1e-2,        'mean', this.b,  'max', 1);
            m('e')  = struct('fixed', 1, 'min', 0,           'mean', this.e,  'max', 0.2);
            m('f')  = struct('fixed', 0, 'min', 0.5,         'mean', this.f,  'max', 0.99);
            m('g')  = struct('fixed', 1, 'min', 0,           'mean', this.g,  'max', 0.5);
            m('p')  = struct('fixed', 1, 'min', 0.5,         'mean', this.p,  'max', 1); 
            m('q')  = struct('fixed', 0, 'min', 0.1,         'mean', this.q,  'max', 0.5); 
            m('t0') = struct('fixed', 0, 'min', 0,           'mean', this.t0, 'max', 1e2); 
            m('t1') = struct('fixed', 0, 'min', 0,           'mean', this.t1, 'max', 20);
        end
        function ed = estimateDataFast(this, S0, a, b, e, f, g, p, q, t0, t1)
            ed{1} = this.specificActivity(   S0, a, b, e, f, g, p, q, t0, t1, this.times{1}, this.kernel);
            ed{2} = this.specificActivity(   S0, a, b, e, f, g, p, q, t0, t1, this.times{2}, this.kernel) .* ...
                    this.decayCorrection(this.times{2});
        end
        function plot(this, varargin)
            figure;
            plot(this.independentData{1}, this.itsDeconvSpecificActivity, ...
                 this.independentData{1}, this.itsSpecificActivity, ...
                 this.independentData{2}, this.itsSpecificActivity .* this.decayCorrection(this.independentData{2}), ...
                 this.independentData{1}, this.dependentData{1}, ...
                 this.independentData{2}, this.dependentData{2}, ...
                 varargin{:});
            legend( ...
                'deconv Bayesian AIF', ...
                'Bayesian AIF', 'Bayesian AIF d.c.', ...
                'data [^{15}O] AIF', 'data [^{15}O] AIF d.c.');
            title(this.detailedTitle, 'Interpreter', 'none');
            xlabel(this.xLabel);
            ylabel(this.yLabel);
        end
        
        function this = DeconvolvingOC(varargin)
            this = this@mlswisstrace.DeconvolvingPLaif(varargin{:});
        end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

