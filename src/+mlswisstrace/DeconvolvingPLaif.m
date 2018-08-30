classdef DeconvolvingPLaif < handle & mlbayesian.AbstractMcmcStrategy
	%% DeconvolvingPLaif 
    %  See also mlarbelaez.Betadcv3.silentGETTKE.  For gaussian kernel, sigma ~ E.
    % 
    % % KERNEL CALCULATION:  U ~ time, E ~ 1/(2 sigma^2)
    % for I = 1:this.nbinMax
    %     U = AK1 * ((I - 1) * TIMPBINE - T0);
    %     if (U <= 0. || E * U^2 > 20.)
    %         BSRF(I) = 0.;
    %     else
    %         R = 1. / (1. + U);
    %         BSRF(I) = AK1 * TIMPBINE * R * exp(-E * U^2) * (2. * E * U + R);
    %     end
    % end
    %
    % function [T,AK,E]            = silentGETTKE(this)
    % 
    %     import mlarbelaez.Betadcv2.*;            
    %     if (this.Hct > 1)
    %         this.Hct = this.Hct / 100.;
    %     end
    %     if (this.catheterId == 1) 
    %         % 35    cm @  5.00 cc/min        1  (standard)
    %         T = 3.4124 - 3.4306 * (this.Hct - .3552);
    %         AK = 0.2919 - 0.5463 * (this.Hct - .3552);
    %         E = 0.0753 - 0.1621 * (this.Hct - .3552);
    %     else
    %         % 35+10 cm @  5.00 cc/min        2  (extension)
    %         T = 5.8971 - 3.2983 * (this.Hct - .3523);
    %         AK = 0.2095 - 0.1476 * (this.Hct - .3523);
    %         E = 0.0302 - 0.0869 * (this.Hct - .3523);
    %     end
    %     return
    % end 

	%  $Revision$
 	%  was created 22-May-2017 21:06:54 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/Local/src/mlcvl/mlswisstrace/src/+mlswisstrace.
 	%% It was developed on Matlab 9.2.0.538062 (R2017a) for MACI64.  Copyright 2017 John Joowon Lee.
 	
    properties (Constant)
        EMPIRICAL_DISP_FORM = 'Lorentz'; % broadens this.kernel_:  Exp, Gauss or Lorentz
        EMPIRICAL_DISP_TAU  = 1;
    end
    
	properties
        S0 = 8e6
        a  = 0.1
        b  = 1
        e  = 0 % 0.01
        f  = 0 % fraction of S0 for recirculation
        g  = 0.05
        p  = 1 % exp stretch; try 0.4
        q  = 1 % exp stretch for recirculation
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
    
    methods
        
        %% GET
        
        function dt = get.detailedTitle(this)
            dt = sprintf('%s\nS0 %g, a %g, b %g,\ne %g, f %g, g %g,\np %g, q %g, t0 %g, t1 %g', ...
                         this.baseTitle, this.S0, this.a, this.b, this.e, this.f, this.g, this.p, this.q, this.t0, this.t1);
        end
        function g  = get.kernel(this)
            g = this.kernel_;
        end
        function m  = get.mapParams(this)
            m = this.getMapParams;
        end
        
        function m = getMapParams(this)
            m = containers.Map;
            m('S0') = struct('fixed', 0, 'min', this.S0/1e2, 'mean', this.S0, 'max', 1e2*this.S0);
            m('a')  = struct('fixed', 0, 'min', 1e-4,        'mean', this.a,  'max', 1e2); 
            m('b')  = struct('fixed', 0, 'min', 1e-2,        'mean', this.b,  'max', 1e3);
            m('e')  = struct('fixed', 1, 'min', 0,           'mean', this.e,  'max', 0.2);
            m('f')  = struct('fixed', 1, 'min', 0,           'mean', this.f,  'max', 0.1);
            m('g')  = struct('fixed', 1, 'min', 1e-4,        'mean', this.g,  'max', 0.1);
            m('p')  = struct('fixed', 1, 'min', 0.05,        'mean', this.p,  'max', 2); 
            m('q')  = struct('fixed', 1, 'min', 0.05,        'mean', this.q,  'max', 2); 
            m('t0') = struct('fixed', 0, 'min', 0,           'mean', this.t0, 'max', 1e2); 
            m('t1') = struct('fixed', 1, 'min', 0,           'mean', this.t1, 'max', 1e2);             
        end
    end
    
    methods (Static)
        function this = runPLaif(varargin)
            ip = inputParser;
            addRequired(ip, 'times', @isnumeric);
            addRequired(ip, 'sActivity', @isnumeric);
            addOptional(ip, 'label', 'mlswisstrace.DeconvolvingPLaif', @ischar);
            parse(ip, varargin{:});
            
            this = mlswisstrace.DeconvolvingPLaif( ...
                {ip.Results.times}, {ip.Results.sActivity}, 'QType', 'SumSquaredResiduals');
            this = this.estimateParameters(this.mapParams);
            this.plot;
            saveFigures(sprintf('fig_%s_%s', this.fileprefix, ip.Results.label));
        end 
        
        function sa   = convolveDispersion(sa, type, tau)
            %% CONVOLVEEMPIRICALDISPERSION adds dispersion after Bayesian estimation to account for unmeasured 
            %  dispersions such as inexact Heaviside inputs or dispersion differences between sampling (radial) artery 
            %  and the target (carotid) artery.  See also mlswisstrace.DeconvolvingPLaif.itsDeconvSpecificActivity.
            %  @param type is {'Gauss' 'Lorentz'}.
            %  @param tau is numeric.
            
            if (tau < 0.1)
                return
            end
            len = length(sa);
            t = 0:len;
            switch (type)
                case 'Exp'
                    krnl = exp(-t/tau);
                case 'Gauss'
                    krnl = exp(-(t.^2/(2*tau^2)));
                case 'Lorentz' % 2*tau == FWHH
                    krnl = (1/pi) * (tau./(t.^2 + tau^2));
                otherwise
                    error('mlswisstrace:unsupportedSwitchcase', 'DeconvolvingPLaif.convolveDispersion');
            end            
            krnl = krnl / sum(krnl);
            sa = conv(sa, krnl);
            sa = sa(1:len);
        end
        function dsa  = deconvSpecificActivity(S0, a, b, e, f, g, p, q, t0, t1, t)
            import mlswisstrace.*;
            dsa = S0 * DeconvolvingPLaif.kAif(a, b, e, f, g, p, q, t0, t1, t);
        end
        function sa   = specificActivity(S0, a, b, e, f, g, p, q, t0, t1, t, krnl)
            import mlswisstrace.*;
            sa = conv(DeconvolvingPLaif.deconvSpecificActivity(S0, a, b, e, f, g, p, q, t0, t1, t), krnl);
            sa = sa(1:length(t));
        end 
        function kA   = kAif(a, b, e, f, g, p, q, t0, t1, t)
            %% exp(-PLaif1Training.LAMBDA_DECAY_15O*(t - t0)) .* PLaif1Training.Heaviside(t, t0) .* ...
            
            import mlpet.*;
            kA = PLaif.bolusFlowFractal(a, b, p, t0, t);
            if (f > 0)
                kA = (1 - f)*kA + f*PLaif.bolusFlowFractal(a, b, q, t0 + t1, t);
            end
            if (e > 0)
                kA = (1 - e)*kA + PLaif.bolusSteadyStateTerm(e, g, t0, t);
            end
            
            import mlswisstrace.*;
            kA = DeconvolvingPLaif.convolveDispersion( ...
                kA, DeconvolvingPLaif.EMPIRICAL_DISP_FORM, DeconvolvingPLaif.EMPIRICAL_DISP_TAU);
        end     
        function kConcentration(varargin)
            error('mlswisstrace:notImplemented', 'DeconvolvingPLaif.kConcentration');
        end
        function this = simulateMcmc(S0, a, b, e, f, g, p, q, t0, t1, t, mapParams, krnl)
            import mlswisstrace.*;     
            sa   = DeconvolvingPLaif.specificActivity(S0, a, b, e, f, g, p, q, t0, t1, t, krnl);
            this = DeconvolvingPLaif({t}, {sa});
            this = this.estimateParameters(mapParams) %#ok<NOPRT>
            this.plot;
        end          
    end
    
	methods 		  
 		function this = DeconvolvingPLaif(varargin)
 			%% DeconvolvingPLaif
 			%  Usage:  this = DeconvolvingPLaif()
 			this = this@mlbayesian.AbstractMcmcStrategy(varargin{:});           
            this = this.loadKernel;
            this.expectedBestFitParams_ = ...
                [this.S0 this.a this.b this.e this.f this.g this.p this.q this.t0 this.t1]';
        end
        
        function this = simulateItsMcmc(this)
            import mlswisstrace.*;
            this = DeconvolvingPLaif.simulateMcmc(this.S0, this.a, this.b, this.e, this.f, this.g, this.p, this.q, this.t0, this.t1, this.times{1}, this.mapParams);
        end
        function wc   = itsDeconvSpecificActivity(this)
            wc = mlswisstrace.DeconvolvingPLaif.deconvSpecificActivity( ...
                this.S0, this.a, this.b, this.e, this.f, this.g, this.p, this.q, this.t0, this.t1, this.times{1});
        end
        function wc   = itsSpecificActivity(this)
            wc = mlswisstrace.DeconvolvingPLaif.specificActivity(this.S0, this.a, this.b, this.e, this.f, this.g, this.p, this.q, this.t0, this.t1, this.times{1}, this.kernel_);
        end
        function ka   = itsKAif(this)
            ka = mlswisstrace.DeconvolvingPLaif.kAif(this.a, this.b, this.e, this.f, this.g, this.p, this.q, this.t0, this.t1, this.times{1});
        end
        function kc   = itsKConcentration(~, kc)
        end
        function this = estimateParameters(this, varargin)
            ip = inputParser;
            addOptional(ip, 'mapParams', this.mapParams, @(x) isa(x, 'containers.Map'));
            parse(ip, varargin{:});
            
            [this.S0,this.t0] = mlpet.PLaif.estimateS0t0(this.independentData{1}, this.dependentData{1});
            this = this.runMcmc(ip.Results.mapParams); %, 'keysToVerify', {'S0' 'a' 'b' 'e' 'f' 'g' 'p' 'q' 't0' 't1'});
        end
        function ed   = estimateDataFast(this, S0, a, b, e, f, g, p, q, t0, t1)
            ed{1} = this.specificActivity(     S0, a, b, e, f, g, p, q, t0, t1, this.times{1}, this.kernel_);
        end
        function ps   = adjustParams(this, ps)
            theParams = this.theParameters;
            if (this.mapParams('b').fixed || this.mapParams('g').fixed || this.e < eps)
                return
            end
            if (ps(theParams.paramsIndices('b')) < ps(theParams.paramsIndices('g')))
                tmp                              = ps(theParams.paramsIndices('g'));
                ps(theParams.paramsIndices('g')) = ps(theParams.paramsIndices('b'));
                ps(theParams.paramsIndices('b')) = tmp;
            end
        end  

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
                        args{v} = { vars(v) this.a  this.b  this.e  this.f  this.g  this.p  this.q  this.t0  this.t1 ...
                                    this.independentData{1} this.kernel };  %#ok<AGROW>
                    end
                case 'a'
                    for v = 1:length(vars)
                        args{v} = { this.S0 vars(v) this.b  this.e  this.f  this.g  this.p  this.q  this.t0  this.t1 ...
                                    this.independentData{1} this.kernel };   %#ok<AGROW>
                    end
                case 'b'
                    for v = 1:length(vars)
                        args{v} = { this.S0 this.a  vars(v) this.e  this.f  this.g  this.p  this.q  this.t0  this.t1 ...
                                    this.independentData{1} this.kernel };   %#ok<AGROW>
                    end
                case 'e'
                    for v = 1:length(vars)
                        args{v} = { this.S0 this.a  this.b  vars(v) this.f  this.g  this.p  this.q  this.t0  this.t1 ...
                                    this.independentData{1} this.kernel };   %#ok<AGROW>
                    end
                case 'g'
                    for v = 1:length(vars)
                        args{v} = { this.S0 this.a  this.b  this.e  this.f  vars(v) this.p  this.q  this.t0  this.t1 ...
                                    this.independentData{1} this.kernel };   %#ok<AGROW>
                    end
                case 'p'
                    for v = 1:length(vars)
                        args{v} = { this.S0 this.a  this.b  this.e  this.f  this.g  vars(v) this.q  this.t0  this.t1 ...
                                    this.independentData{1} this.kernel };   %#ok<AGROW>
                    end
                case 'q'
                    for v = 1:length(vars)
                        args{v} = { this.S0 this.a  this.b  this.e  this.f  this.g  this.p  vars(v) this.t0  this.t1 ...
                                    this.independentData{1} this.kernel };   %#ok<AGROW>
                    end
                case 't0'
                    for v = 1:length(vars)
                        args{v} = { this.S0 this.a  this.b  this.e  this.f  this.g  this.p  this.q  vars(v)  this.t1 ...
                                    this.independentData{1} this.kernel };   %#ok<AGROW>
                    end
            end
            this.plotParArgs(par, args, vars);
        end  
 	end 
    
    %% PRIVATE
    
    properties (Access = private)
        expectedBestFitParams_
        kernel_
        kernelRange_ = 1:75
        kernelBestFilename_ = fullfile(getenv('HOME'), 'MATLAB-Drive/mlarbelaez/data/kernelBest.mat')
    end
    
    methods (Access = private)
        function this = loadKernel(this)
            load(this.kernelBestFilename_);
            this.kernel_ = kernelBest(this.kernelRange_);    
        end
    end    

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

