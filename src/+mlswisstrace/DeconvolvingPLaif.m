classdef DeconvolvingPLaif < mlperfusion.AbstractPLaif
	%% DeconvolvingPLaif  

	%  $Revision$
 	%  was created 22-May-2017 21:06:54 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/Local/src/mlcvl/mlswisstrace/src/+mlswisstrace.
 	%% It was developed on Matlab 9.2.0.538062 (R2017a) for MACI64.  Copyright 2017 John Joowon Lee.
 	
	properties
        S0 = 8e6
        a  = 0.1
        b  = 1
        e  = 0.01
        f  = 0 % fraction of S0 for recirculation
        g  = 0.05
        p  = 0.4
        t0 = 29
        t1 = 0 % recirculation starts at t0 + t1
        
        xLabel = 'times/s'
        yLabel = 'activity'
 	end
    
    properties (Dependent)
        detailedTitle
        kernel
        mapParams 
    end
    
    methods %% GET
        function dt = get.detailedTitle(this)
            dt = sprintf('%s\nS0 %g, a %g, b %g, e %g, f %g, g %g, p %g, t0 %g, t1 %g', ...
                         this.baseTitle, this.S0, this.a, this.b, this.e, this.f, this.g, this.p, this.t0, this.t1);
        end
        function g  = get.kernel(this)
            g = this.kernel_;
        end
        function m  = get.mapParams(this)
            m = containers.Map;
            m('S0') = struct('fixed', 0, 'min', this.S0/30, 'mean', this.S0, 'max', 30*this.S0);
            m('a')  = struct('fixed', 0, 'min', 0.02,       'mean', this.a,  'max', 20); 
            m('b')  = struct('fixed', 0, 'min', 0.02,       'mean', this.b,  'max', 20);
            m('e')  = struct('fixed', 0, 'min', 0,          'mean', this.e,  'max', 0.2);
            m('f')  = struct('fixed', 1, 'min', 0,          'mean', this.f,  'max', 0.2);
            m('g')  = struct('fixed', 0, 'min', 0.001,      'mean', this.g,  'max', 0.1);
            m('p')  = struct('fixed', 0, 'min', 0.1,        'mean', this.p,  'max', 2); 
            m('t0') = struct('fixed', 0, 'min', 0,          'mean', this.t0, 'max', 60); 
            m('t1') = struct('fixed', 1, 'min', 0,          'mean', this.t1, 'max', 20); 
        end
    end
    
    methods (Static)
        function this = runPLaif(times, becq)
            this = mlswisstrace.DeconvolvingPLaif({times}, {becq});
            this = this.estimateParameters(this.mapParams);
            this.plot;
            saveFigures(sprintf('fig_%s', this.fileprefix));  
        end 
        function dsa  = deconvSpecificActivity(S0, a, b, e, f, g, p, t0, t1, t)
            import mlswisstrace.*;
            dsa = S0 * DeconvolvingPLaif.kAif(a, b, e, f, g, p, t0, t1, t);
        end
        function sa   = specificActivity(S0, a, b, e, f, g, p, t0, t1, t, krnl)
            import mlswisstrace.*;
            sa = conv(DeconvolvingPLaif.deconvSpecificActivity(S0, a, b, e, f, g, p, t0, t1, t), krnl);
            sa = sa(1:length(t));
        end 
        function kA   = kAif(a, b, e, f, g, p, t0, t1, t)
            import mlswisstrace.*;
            %% exp(-PLaif1Training.LAMBDA_DECAY_15O*(t - t0)) .* PLaif1Training.Heaviside(t, t0) .* ...
            
            if (f > 0 && t1 > 0)
                kA = (1 - f)*DeconvolvingPLaif.bolusFlowFractal(a, b, p, t0, t) + ...
                          f *DeconvolvingPLaif.bolusFlowFractal(a, b, p, t0 + t1, t) + ...
                             DeconvolvingPLaif.bolusSteadyStateTerm(e, g, t0, t);
                return
            end
            if (e > 0)
                kA = DeconvolvingPLaif.bolusFlowFractal(a, b, p, t0, t) + ...
                     DeconvolvingPLaif.bolusSteadyStateTerm(e, g, t0, t);
                return
            end
            kA = DeconvolvingPLaif.bolusFlowFractal(a, b, p, t0, t);
        end     
        function kConcentration(varargin)
            error('mlswisstrace:notImplemented', 'DeconvolvingPLaif.kConcentration');
        end
        function this = simulateMcmc(S0, a, b, e, f, g, p, t0, t1, t, mapParams, krnl)
            import mlswisstrace.*;     
            sa   = DeconvolvingPLaif.specificActivity(      S0, a, b, e, f, g, p, t0, t1, t, krnl);
            this = DeconvolvingPLaif({t}, {sa});
            this = this.estimateParameters(mapParams) %#ok<NOPRT>
            this.plot;
        end   
    end
    
	methods 
		  
 		function this = DeconvolvingPLaif(varargin)
 			%% DeconvolvingPLaif
 			%  Usage:  this = DeconvolvingPLaif()
 			this = this@mlperfusion.AbstractPLaif(varargin{:});           
            this = this.loadKernel;
            this = this.buildJeffreysPrior;
            this.expectedBestFitParams_ = ...
                [this.S0 this.a this.b this.e this.f this.g this.p this.t0 this.t1]';
        end
        
        function this = simulateItsMcmc(this)
            import mlswisstrace.*;
            this = DeconvolvingPLaif.simulateMcmc(this.S0, this.a, this.b, this.e, this.f, this.g, this.p, this.t0, this.t1, this.times{1}, this.mapParams);
        end
        function wc   = itsDeconvSpecificActivity(this)
            wc = mlswisstrace.DeconvolvingPLaif.deconvSpecificActivity(this.S0, this.a, this.b, this.e, this.f, this.g, this.p, this.t0, this.t1, this.times{1});
        end
        function wc   = itsSpecificActivity(this)
            wc = mlswisstrace.DeconvolvingPLaif.specificActivity(this.S0, this.a, this.b, this.e, this.f, this.g, this.p, this.t0, this.t1, this.times{1}, this.kernel_);
        end
        function ka   = itsKAif(this)
            ka = mlperfusion.PLaif1Training.kAif(this.a, this.b, this.e, this.g, this.p, this.t0, this.t1, this.times{1});
        end
        function kc   = itsKConcentration(~, kc)
        end
        function this = estimateParameters(this, varargin)
            ip = inputParser;
            addOptional(ip, 'mapParams', this.mapParams, @(x) isa(x, 'containers.Map'));
            parse(ip, varargin{:});
            
            [this.S0,this.t0] = this.estimateS0t0(this.independentData{1}, this.dependentData{1});
            
            this = this.runMcmc(ip.Results.mapParams); %, 'keysToVerify', {'S0' 'a' 'b' 'e' 'f' 'g' 'p' 't0'});
        end
        function ed   = estimateDataFast(this, S0, a, b, e, f, g, p, t0, t1)
            ed{1} = this.specificActivity(           S0, a, b, e, f, g, p, t0, t1, this.times{1}, this.kernel_);
        end
%%        function ps   = adjustParams(this, ps)
%             theParams = this.theParameters;
%             if (this.mapParams('b').fixed || this.mapParams('g').fixed)
%                 return
%             end
%             if (ps(theParams.paramsIndices('b')) < ps(theParams.paramsIndices('g')))
%                 tmp                              = ps(theParams.paramsIndices('g'));
%                 ps(theParams.paramsIndices('g')) = ps(theParams.paramsIndices('b'));
%                 ps(theParams.paramsIndices('b')) = tmp;
%             end
%         end  

        function plot(this, varargin)
            figure;
            plot(this.independentData{1}, this.itsSpecificActivity, ...
                 this.independentData{1}, this.itsDeconvSpecificActivity, ...
                 this.independentData{1}, this.dependentData{1}, varargin{:});
            legend('Bayesian AIF', 'deconv Bayesian AIF', 'data [^{15}O] AIF');
            title(this.detailedTitle, 'Interpreter', 'none');
            xlabel(this.xLabel);
            ylabel(this.yLabel);
        end
        function plotParVars(this, par, vars)
            assert(lstrfind(par, properties('mlswisstrace.DeconvolvingPLaif')));
            assert(isnumeric(vars));
            switch (par)
                case 'S0'
                    for v = 1:length(vars)
                        args{v} = { vars(v) this.a  this.b  this.e  this.f  this.g  this.p  this.t0  this.t1 ...
                                    this.independentData{1} this.independentData{2} };  %#ok<AGROW>
                    end
                case 'a'
                    for v = 1:length(vars)
                        args{v} = { this.S0 vars(v) this.b  this.e  this.f  this.g  this.p  this.t0  this.t1 ...
                                    this.independentData{1} this.independentData{2} };   %#ok<AGROW>
                    end
                case 'b'
                    for v = 1:length(vars)
                        args{v} = { this.S0 this.a  vars(v) this.e  this.f  this.g  this.p  this.t0  this.t1 ...
                                    this.independentData{1} this.independentData{2} };   %#ok<AGROW>
                    end
                case 'e'
                    for v = 1:length(vars)
                        args{v} = { this.S0 this.a  this.b  vars(v) this.f  this.g  this.p  this.t0  this.t1 ...
                                    this.independentData{1} this.independentData{2} };   %#ok<AGROW>
                    end
                case 'g'
                    for v = 1:length(vars)
                        args{v} = { this.S0 this.a  this.b  this.e  this.f  vars(v) this.p  this.t0  this.t1 ...
                                    this.independentData{1} this.independentData{2} };   %#ok<AGROW>
                    end
                case 'p'
                    for v = 1:length(vars)
                        args{v} = { this.S0 this.a  this.b  this.e  this.f  this.g  vars(v) this.t0  this.t1 ...
                                    this.independentData{1} this.independentData{2} };   %#ok<AGROW>
                    end
                case 't0'
                    for v = 1:length(vars)
                        args{v} = { this.S0 this.a  this.b  this.e  this.f  this.g  this.p  vars(v)  this.t1 ...
                                    this.independentData{1} this.independentData{2} };   %#ok<AGROW>
                    end
            end
            this.plotParArgs(par, args, vars);
        end  
 	end 
    
    %% PRIVATE
    
    properties (Access = private)
        expectedBestFitParams_
        kernel_
        kernelRange_ = 12:40
        kernelBestFilename_ = '/Users/jjlee/MATLAB-Drive/mlarbelaez/src/+mlarbelaez/kernelBest.mat'
    end
    
    methods (Access = private)
        function this = loadKernel(this)            
            load(this.kernelBestFilename_);
            this.kernel_ = kernelBest(this.kernelRange_);
            this.kernel_ = this.kernel_ / sum(this.kernel_);             
        end
    end    

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

