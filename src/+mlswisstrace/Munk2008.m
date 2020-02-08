classdef Munk2008 < handle & mlnest.AbstractApply
	%% Munk2008  

	%  $Revision$
 	%  was created 06-Feb-2020 18:51:30 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlswisstrace/src/+mlswisstrace.
 	%% It was developed on Matlab 9.7.0.1261785 (R2019b) Update 3 for MACI64.  Copyright 2020 John Joowon Lee.
 	
    properties
        ignoredObjFields = {'logL' 'logWt'}
        MAX = 500            % # of nested sampling loops, similar to temperature for s.a.
        MCMC_Counter = 50    % counter for explorting single particle (pre-judged # steps); nonlinearly affects precision
        n = 10               % # of sampling particles \sim (log width of outer prior mass)^{-1}; reduces sampling space
        STEP_Initial = 0.05  % Initial guess suitable step-size in (0,1); 0.01*MCMC_Counter^{-1} < STEP < 10*MCMC_Counter^{-1} improve precision
        
 		box
        DeltaT = 120 % sec
        idx0
        idxF        
        map                  % containers.Map containing model params as structs with fields:  min, max ,init
        Measurement          % external data
        timeInflow
        timeInterpolants     % numeric times for Measurement
 	end

	methods 
        
        function est  = Estimation(this, Obj)
            Obn = Obj2native(this, Obj);
            est = max(this.box)*this.estimatorDispersion_(Obn) + Obn.baseline;
        end        
        function est = estimatorBoxcarDisp(this, Obj)
            C = Obj.C;
            a = Obj.a;
            k = Obj.k;
            t0 = round(Obj.t0);
            ti = this.timeInflow;
            est = zeros(size(this.timeInterpolants));
            
            % Munk Eqn (A5) but not neglecting ext(-k\Delta T_{\text{inf}})
            t_ = 0:1:ti+t0-1;
            est(t_+1) = 0;            
            t_ = ti+t0:1:ti+t0+this.DeltaT-1;
            est(t_+1) = C*(1 - a*exp(-k*t_));            
            t_ = ti+t0+this.DeltaT:1:length(est)-1;
            est(t_+1) = a*C*( exp(-k*(t_-t0-this.DeltaT)) - exp(-k*(t_-t0)) ); 
        end
        function est = estimatorForwardDisp(this, Obj)
        end
		  
 		function this = Munk2008(varargin)
 			%% Munk2008
 			%  @param .

 			this = this@mlnest.AbstractApply(varargin{:});
            
            ip = inputParser;            
            ip.KeepUnmatched = true;
            addParameter(ip, 'measurement', [], @isnumeric)
            addParameter(ip, 'timeInterpolants', [], @isnumeric)
            addParameter(ip, 'paramMap', containers.Map, @(x) isa(x, 'containers.Map'))
            addParameter(ip, 'MAX', this.MAX, @isnumeric)
            addParameter(ip, 'MCMC_Counter', this.MCMC_Counter, @isnumeric)
            addParameter(ip, 'n', this.n, @isnumeric)
            addParameter(ip, 'STEP_Initial', this.STEP_Initial, @isnumeric)
            addParameter(ip, 'sigma0', 0.02, @isnumeric)
            addParameter(ip, 'modelName', 'boxcar', @ischar)
            addParameter(ip, 'DeltaT', this.DeltaT, @isnumeric)
            addParameter(ip, 'calibrationData', [], @(x) isa(x, 'mlpet.IAifData'))
            addParameter(ip, 'calibrationTable', [], @istable)
            parse(ip, varargin{:})
            ipr = ip.Results;

            this.Measurement = ipr.measurement;
            this.timeInterpolants = ipr.timeInterpolants; 
            this.map = ipr.paramMap;
            this.MAX = ipr.MAX;
            this.MCMC_Counter = ipr.MCMC_Counter;
            this.n = ipr.n;
            this.STEP_Initial = ipr.STEP_Initial;
            this.sigma0 = ipr.sigma0;  
            this.modelName_ = ipr.modelName;
            switch this.modelName_
                case 'boxcar'
                    this.DeltaT = ipr.DeltaT;
                    this.estimatorDispersion_ = @(obj_) this.estimatorBoxcarDisp(obj_);
                case 'forward'
                    this.estimatorDispersion_ = @(obj_) this.estimatorForwardDisp(obj_);
                otherwise
                    error('mlswisstrace:ValueError', 'Munk2008.ctor')
            end
            this.calibrationData_ = ipr.calibrationData;
            this.calibrationTable_ = ipr.calibrationTable; 
                                   
            this.map = containers.Map;
            this.map('baseline') = struct('min', 120,   'max', 180,    'init', 150);
            this.map('C')        = struct('min',   0.3, 'max',   0.8,  'init',   0.6);
            this.map('t0')       = struct('min',   8,   'max',  16,    'init',  12);
            this.map('a')        = struct('min',   0.5, 'max',   0.9,  'init',   0.7);
            this.map('k')        = struct('min',   1e-3,'max',   0.01, 'init',   0.003);
            
            [this.timeInterpolants,dt0] = this.observations2times(this.calibrationTable_.observations);
            [this.box,this.idx0,this.idxF,this.timeInflow] = this.boxcar( ...
                'tracerModel', this.tracerModel, ...
                'times', this.timeInterpolants, ...
                'datetime0', dt0, ...
                'inflow', this.calibrationTable_.inflow, ...
                'outflow', this.calibrationTable_.outflow);
            this.Measurement = this.calibrationData_.coincidence(this.idx0:this.idxF);
 		end
 	end 
    
    %% PROTECTED
    
    properties (Access = protected)
        calibrationData_
        calibrationTable_
        estimatorDispersion_
        modelName_
    end
    
    methods (Static, Access = protected)  
        function [vec,T] = ensureRow(vec)
            if (~isrow(vec))
                vec = vec';
                T = true;
                return
            end
            T = false; 
        end      
        function conc    = slide(conc, t, Dt)
            %% SLIDE slides discretized function conc(t) to conc(t - Dt);
            %  Dt > 0 will slide conc(t) towards later times t.
            %  Dt < 0 will slide conc(t) towards earlier times t.
            %  It works for inhomogeneous t according to the ability of pchip to interpolate.
            %  It may not preserve information according to the Nyquist-Shannon theorem.  
            
            import mlswisstrace.Munk2008;
            [conc,trans] = Munk2008.ensureRow(conc);
            t            = Munk2008.ensureRow(t);
            
            tspan = t(end) - t(1);
            tinc  = t(2) - t(1);
            t_    = [(t - tspan - tinc) t];   % prepend times
            conc_ = [zeros(size(conc)) conc]; % prepend zeros
            conc_(isnan(conc_)) = 0;
            conc  = pchip(t_, conc_, t - Dt); % interpolate onto t shifted by Dt; Dt > 0 shifts to right
            
            if (trans)
                conc = conc';
            end
        end
    end
    
    methods (Access = protected)
        function [box,idx0,idxF,sec_a] = boxcar(this, varargin)
            %% 
            %  @return Twilite counts/s
            %  @return idx0
            %  @return idxF
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'tracerModel', [], @(x) isa(x, 'mlpet.TracerModel'))
            addParameter(ip, 'times', [], @isnumeric)
            addParameter(ip, 'datetime0', NaT, @isdatetime)
            addParameter(ip, 'inflow', NaT, @isdatetime)
            addParameter(ip, 'outflow', NaT, @isdatetime)
            parse(ip, varargin{:})
            ipr = ip.Results;
            
            datetimeF = ipr.datetime0 + seconds(ipr.times(end) - ipr.times(1) + 1);
            
            sec_a = floor(seconds(ipr.inflow  - ipr.datetime0));
            sec_b = floor(seconds(ipr.outflow - ipr.inflow));
            sec_c = floor(seconds(datetimeF   - ipr.outflow));
            dt_a  = ipr.datetime0 + seconds(0:1:sec_a-1);
            dt_b  = dt_a(end)     + seconds(1:1:sec_b);
            dt_c  = dt_b(end)     + seconds(1:1:sec_c+1);
            mdl   = ipr.tracerModel;
            box   = [eps*ones(1, sec_a), mdl.twiliteCounts(dt_b(1))*ones(size(dt_b)), eps*ones(1, sec_c)];
            
            [~,idx0] = min(abs(this.calibrationData_.datetime - dt_a(1)));
            [~,idxF] = min(abs(this.calibrationData_.datetime - dt_c(end)));
            idxF = idxF - 1;
        end
        function [t,dt0] = observations2times(this, obs)
            if iscell(obs)
                obs = obs{1};
            end
            assert(isdatetime(obs))
            if 2 == length(obs)
                Nsec = seconds(obs(2) - obs(1));
                t = 0:1:Nsec-1;
                dt0 = obs(1);
                return
            end
            if length(obs) > 2
                t = seconds(obs - obs(1));                
                dt0 = obs(1);
                return
            end
            t = this.calibrationData_.times;
            dt0 = this.calibrationData_.datetime0;
        end
        function mdl = tracerModel(this)
            xlsx = this.calibrationData_.manualData;
            act = xlsx.countsFdg.TRUEDECAY_APERTURECORRGe_68_Kdpm_G(1)*(1000/60);
            mt  = xlsx.countsFdg.TIMEDRAWN_Hh_mm_ss(1);
            mdl = mlpet.TracerModel( ...
                'activity', act, ...
                'activityUnits', 'Bq/mL', ...
                'measurementTime', mt);
            
            %mdl = mlpet.TracerModel( ...
            %    'activity', 3.7084573e+06, ...
            %    'activityUnits', 'Bq/mL', ...
            %    'measurementTime', datetime(2019,9,30,16,58,0, 'TimeZone', 'America/Chicago'));
        end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

