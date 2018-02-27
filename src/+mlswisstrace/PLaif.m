classdef PLaif < mlperfusion.AbstractPLaif
	%% PLAIF  

	%  $Revision$
 	%  was created 22-May-2017 21:06:54 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/Local/src/mlcvl/mlswisstrace/src/+mlswisstrace.
 	%% It was developed on Matlab 9.2.0.538062 (R2017a) for MACI64.  Copyright 2017 John Joowon Lee.
 	
	properties
        S0 = 7e6
        a  = 0.09
        b  = 0.5
        e  = 0.002
        f  = 0.1 % fraction of S0 for recirculation
        g  = 0.0005
        p  = 0.3
        t0 = 32 
        t1 = 13 % recirculation starts at t0 + t1
        
        xLabel = 'times/s'
        yLabel = 'activity'
 	end
    
    properties (Dependent)
        detailedTitle
        mapParams 
    end
    
    methods %% GET
        function dt = get.detailedTitle(this)
            dt = sprintf('%s\nS0 %g, a %g, b %g, e %g, f %g, g %g, p %g, t0 %g, t1 %g', ...
                         this.baseTitle, this.S0, this.a, this.b, this.e, this.f, this.g, this.p, this.t0, this.t1);
        end
        function m  = get.mapParams(this)
            m = containers.Map;
            m('S0') = struct('fixed', 0, 'min', this.S0/30, 'mean', this.S0, 'max', 30*this.S0);
            m('a')  = struct('fixed', 0, 'min', 0.0001,     'mean', this.a,  'max', 10); 
            m('b')  = struct('fixed', 0, 'min', 0.01,       'mean', this.b,  'max', 3);
            m('e')  = struct('fixed', 0, 'min', 0,          'mean', this.e,  'max', 0.01);
            m('f')  = struct('fixed', 0, 'min', 0,          'mean', this.f,  'max', 0.2);
            m('g')  = struct('fixed', 0, 'min', 0.0001,     'mean', this.g,  'max', 0.1);
            m('p')  = struct('fixed', 0, 'min', 0.1,        'mean', this.p,  'max', 2); 
            m('t0') = struct('fixed', 0, 'min', 0,          'mean', this.t0, 'max', 60); 
            m('t1') = struct('fixed', 0, 'min', 0,          'mean', this.t1, 'max', 30); 
        end
    end
    
    methods (Static)
        function this = doHygly28V1(varargin)
            ip = inputParser;
            addParameter(ip, 'k4', [], @isnumeric);
            parse(ip, varargin{:});
            
            studyd = mlraichle.StudyData;
            studyd.subjectsFolder = 'jjlee2';
            sessd = mlraichle.SessionData( ...
                'studyData', studyd, 'sessionPath', fullfile(studyd.subjectsDir, 'HYGLY28', ''));
            sessd.tracer = 'FDG';
            sessd.attenuationCorrected = true;
            pth = fullfile(sessd.sessionPath, 'V1', 'TylerBlazey', 'PLaif', '');
            cd(pth);
            import mlswisstrace.*;
            dta = PLaif.csv2dta(fullfile(pth, 'HYGLY28_V1_AIF.csv'));
            this = PLaif.runPLaif(dta.times(1:20), dta.specificActivity(1:20));
        end
        function dta = csv2dta(fqfn)
            t = readtable(fqfn);
            dta.times = t.Time_Secs';
            dta.specificActivity = t.AIF';
        end
        function this = runPLaif(times, becq)
            this = mlswisstrace.PLaif({times}, {becq});
            this = this.estimateParameters(this.mapParams);
            this.plot;
            saveFigures(sprintf('fig_%s', this.fileprefix));  
        end    
        function wc   = specificActivity(S0, a, b, e, f, g, p, t0, t1, t)
            import mlswisstrace.*;
            wc = S0 * PLaif.kAif(a, b, e, f, g, p, t0, t1, t);
        end 
        function kA   = kAif(a, b, e, f, g, p, t0, t1, t)
            import mlswisstrace.*;
            %% exp(-PLaif1Training.LAMBDA_DECAY_15O*(t - t0)) .* PLaif1Training.Heaviside(t, t0) .* ...
            kA = (1 - f)*PLaif.bolusFlowFractal(a, b, p, t0, t) + ...
                      f *PLaif.bolusFlowFractal(a, b, p, t0 + t1, t) + ...
                         PLaif.bolusSteadyStateTerm(e, g, t0, t);
        end        
        function kc   = kConcentration(kc)
        end 
        function mdl  = model(varargin)
            mdl = mlswisstrace.PLaif.kConcentration(varargin{:});
        end
        function this = simulateMcmc(S0, a, b, e, f, g, p, t0, t1, t, mapParams)
            import mlswisstrace.*;     
            wellCnts = PLaif.specificActivity(      S0, a, b, e, f, g, p, t0, t1, t);
            this     = PLaif({t}, {wellCnts});
            this     = this.estimateParameters(mapParams) %#ok<NOPRT>
            this.plot;
        end   
    end
    
	methods 
		  
 		function this = PLaif(varargin)
 			%% PLAIF
 			%  Usage:  this = PLaif()
 			this = this@mlperfusion.AbstractPLaif(varargin{:});
            this.expectedBestFitParams_ = ...
                [this.S0 this.a this.b this.e this.f this.g this.p this.t0 this.t1]';
        end
        
        function this = simulateItsMcmc(this)
            import mlswisstrace.*;
            this = PLaif.simulateMcmc(this.S0, this.a, this.b, this.e, this.f, this.g, this.p, this.t0, this.t1, this.times{1}, this.mapParams);
        end
        function wc   = itsSpecificActivity(this)
            wc = mlswisstrace.PLaif.specificActivity(this.S0, this.a, this.b, this.e, this.f, this.g, this.p, this.t0, this.t1, this.times{1});
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
            ed{1} = this.specificActivity(           S0, a, b, e, f, g, p, t0, t1, this.times{1});
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
                 this.independentData{1}, this.dependentData{1}, varargin{:});
            legend('Bayesian AIF', 'data AIF');            
            title(this.detailedTitle, 'Interpreter', 'none');
            xlabel(this.xLabel);
            ylabel(this.yLabel);
        end
        function plotParVars(this, par, vars)
            assert(lstrfind(par, properties('mlswisstrace.PLaif')));
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
    end
    
    methods (Access = private)
    end    

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

