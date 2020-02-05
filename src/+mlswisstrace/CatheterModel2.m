classdef CatheterModel2 < handle & mlnest.GammaDistributions
	%% CATHETERMODEL2  

	%  $Revision$
 	%  was created 27-Jan-2020 19:08:52 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlswisstrace/src/+mlswisstrace.
 	%% It was developed on Matlab 9.7.0.1261785 (R2019b) Update 3 for MACI64.  Copyright 2020 John Joowon Lee.
 	
	properties
 		box
        idx0
        idxF
 	end

	methods (Static)
    end
    
    methods        
        function main = calibrate(this)
            main = mlnest.NestedSamplingMain(this);
        end
        function est  = Estimation(this, Obj)
            Obn = this.Obj2native(Obj);
            est = this.fixed_scale*conv(this.estimatorGamma_(Obn), this.box) + this.fixed_baseline;
            est = est(1:length(this.timeInterpolants));
            est(est < 0) = 0;            
        end
        function plot(~, t, q0, q)
            figure
            plot(t, q0, '-+', ...
                 t, q, ':o')
            legend('measured', 'estimated')
            xlabel('times / s')
            ylabel('activity / cps')
        end
        
 		function this = CatheterModel2(varargin)
 			%% CATHETERMODEL2
 			%  @param modelName \in \{ 'GeneralizedGammaDistribution' 'GeneralizedGammaDistributionP' ...
            %                                     'GammaDistribution'            'GammaDistributionP' \}
            %  @param calibrationData is mlpet.IAifData suitable for catheter.
            %  @param calibrationTable is a table.

            this = this@mlnest.GammaDistributions(varargin{:});
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'calibrationData', [], @(x) isa(x, 'mlpet.IAifData'))
            addParameter(ip, 'calibrationTable', [], @istable)
            parse(ip, varargin{:})
            ipr = ip.Results;
            
            this.calibrationData_ = ipr.calibrationData;
            this.calibrationTable_ = ipr.calibrationTable;                        
            this.map = containers.Map;
            this.map('baseline') = struct('min', 120,    'max', 160);
            this.map('scale')    = struct('min',   0.3,  'max',   3);
            this.map('a')        = struct('min',   0.1,  'max',  10);
            this.map('b')        = struct('min',   0.01, 'max',  20);
            this.map('p')        = struct('min',   0.2,  'max',   2);
            this.map('t0')       = struct('min', -20,    'max',  20);
            this.map('w')        = struct('min',  -1,    'max',   1);            
            [this.timeInterpolants,dt0] = this.observations2times(this.calibrationTable_.observations);
            [this.box,this.idx0,this.idxF] = this.boxcar( ...
                'tracerModel', this.tracerModel, ...
                'times', this.timeInterpolants, ...
                'datetime0', dt0, ...
                'inflow', this.calibrationTable_.inflow, ...
                'outflow', this.calibrationTable_.outflow);
            this.Measurement = this.calibrationData_.coincidence(this.idx0:this.idxF);
            this.sigma0 = 100;
 		end
    end
    
    % PRIVATE
    
    properties (Access = private)
        calibrationData_
        calibrationTable_
    end
    
    methods (Access = private)
        function [box,idx0,idxF] = boxcar(this, varargin)
            %% 
            %  @return Twilite counts/s
            %  @return idx0
            %  @return idxF
            
            ip = inputParser;
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
            box   = [eps*ones(1, sec_a), mdl.twiliteCounts(dt_b), eps*ones(1, sec_c)];
            
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

