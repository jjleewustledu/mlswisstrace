classdef TwiliteCatheterCalibration < mlswisstrace.AbstractTwilite
	%% TWILITECATHETERCALIBRATION  

	%  $Revision$
 	%  was created 19-Jul-2017 23:38:06 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlswisstrace/src/+mlswisstrace.
 	%% It was developed on Matlab 9.2.0.538062 (R2017a) for MACI64.  Copyright 2017 John Joowon Lee.
 	    
    properties (Dependent)
        manualData
    end
    
    methods (Static)
        function this = create(varargin)
            this = mlswisstrace.TwiliteCatheterCalibration.createFromDate(varargin{:});
        end
        function this = createFromDate(varargin)
            %% @param optional dt is datetime.
            
            ip = inputParser;
            addOptional(ip, 'dt', datetime(2019, 9, 30), @isdatetime);
            addParameter(ip, 'isotope', 'FDG', @ischar);
            parse(ip, varargin{:})
            ipr = ip.Results;

            crvpth = fullfile(getenv('HOME'), 'Documents', 'private', 'Twilite', 'catheter_calibration_20190930', '');
            crvfp = sprintf('fdg_dt%d%02d%02d', ipr.dt.Year, ipr.dt.Month, ipr.dt.Day);
            crvfqfn = fullfile(crvpth, [crvfp '.crv']);
            assert(isfile(crvfqfn))
            crm = mlpet.CCIRRadMeasurements.createByDate(ipr.dt);
            this = mlswisstrace.TwiliteCatheterCalibration( ...
                'fqfilename', crvfqfn, ...
                'manualData', crm, ...
                'isotope', ipr.isotope, ...
                'doseAdminDatetime', crm.datetimeTracerAdmin('tracer', 'FDG', 'earliest', true));
        end
        function calibrateCatheter()
            import mlswisstrace.*
            tcc = TwiliteCatheterCalibration.create();
            %tcc.plotCounts()
            cath = CatheterModel('modelName', 'GeneralizedGammaDistributionP');
            tracer = mlpet.TracerModel( ...
                'activity', 3.7084573e+06, ...
                'activityUnits', 'Bq/mL', ...
                'measurementTime', datetime(2019,9,30,16,58,0, 'TimeZone', 'America/Chicago'));
            dt_inflow = datetime(2019,9,30,17,47,0, 'TimeZone', 'America/Chicago');
            fprintf('datetime for inflow:  %s\n', dt_inflow)
            solution = tcc.solveCatheterModel( ...
                'catheterModel', cath, ...
                'tracerModel', tracer, ...
                'inflow', dt_inflow, ...
                'outflow', dt_inflow + minutes(2), ...                
                'observations', [dt_inflow - minutes(2), dt_inflow + minutes(4)], ...
                'sigma0', 100, ...
                'params0', [140 0.565  0.6  3    0.4   8  0.1], ...
                'ub',      [160 0.7   10   20    2    20  1], ...
                'lb',      [120 0.3    0.1  0.01 0.2 -20 -1]); %#ok<NASGU> % baseline scale a b p t0 w
            
            % hct 46, 17:43:00: 
            % params1: [1.359228211657675e+02 0.568945937983901 0.564827853460346 2.753875472156682 0.443731801251460 8.454864431156679 0.090542366966903]
            
            % hct 44, 17:47:00:
            % [1.597876618543511e+02 0.567304030020488 1.003099906029766 14.444602739405450 0.383310461789767 9.342417615851431 -0.546465637434091]
            
            % hct 42, 17:51:00:
            % [1.599517119940202e+02 0.563422127376824 0.742210558135824 5.012678362268308 0.422934164847280 9.820656454490653 0.274103404589749]
            
            
            
            % hct 35, 19:08:00:
            % [1.364706246240927e+02 0.467097260440060 0.198144733783242 5.553061962307165 0.333402511449442 8.812673317801806 -0.006749132288795]
            
            % hct 35, 19:12:00 (poor top fit):
            % [1.567486055211253e+02 0.451181727491143 0.701398775794041 5.594375513033616 0.425196794669524 11.283850812887088 0.169574989029091]
            
            % hct 35, 19:16:00:
            % [1.536251896721565e+02 0.468346261203730 0.754431484714106 10.577142928013544 0.388191111906516 9.313789747595846 0.087469586510421]
            
            
            
            
            % hct 28, 20:00:00: 
            % [1.218185031974124e+02 0.401639829474978 0.451796717937226 17.844941808862238 0.353179541781296 10.692324197276390 0.827228290775468]
            
            % hct 28, 20:04:00:
            % [1.433626718105177e+02 0.399599847164117 0.909531008435392 16.903490891315094 0.377862825504243 10.017693461593584 0.375582027745938]
            
            % hct 28, 20:08:00:
            % [1.506921289014020e+02 0.374083389148723 0.111725099251394 11.999345841684667 0.298876564138579 10.642670144681496 -0.009426204191386]
            
            % hct 28, 20:12:00:
            % [1.377685679619533e+02 0.317771772598445 0.964235750421814 14.576196501285162 0.390038015625766 9.637290662759257 0.731046581669815]
            
            % hct 28, 20:16:00:
            % [1.485145295122673e+02 0.304943958940609 0.119977531631776 17.209646290055478 0.288255962452888 10.875160651862737 -0.009857372142908]
            
            save('mlswisstrace.TwiliteCatheterCalibration.calibrateCatheter.mat')
        end
        function calibrateCatheter2()
            import mlswisstrace.*
            
            tcc = TwiliteCatheterCalibration.create();
            tbl = tcc.tabulateCalibrationMeasurements();
            disp(tcc)
            %tcc.plotCounts()
            
            results = cell(1, size(tbl,1));
            for it = 1:size(tbl,1)
                disp(tbl(it,:))
                cath = CatheterModel2( ...
                    'calibrationData', tcc, ...
                    'calibrationTable', tbl(it,:), ...
                    'sigma0', 100, ...
                    'modelName', 'GeneralizedGammaDistributionP');
                main = cath.calibrate();
                results{it} = main.apply.results;
            end
        end
    end
    
	methods 
        
        %% GET
        
        function g = get.manualData(this)
            g = this.manualData_;
        end
        
        %%
        
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
            
            [~,idx0] = min(abs(this.datetime - dt_a(1)));
            [~,idxF] = min(abs(this.datetime - dt_c(end)));
            idxF = idxF - 1;
        end
        function [t,dt0] = datetimes2times(this, dt)
            assert(isdatetime(dt))
            if 2 == length(dt)
                Nsec = seconds(dt(2) - dt(1));
                t = 0:1:Nsec-1;
                dt0 = dt(1);
                return
            end
            if length(dt) > 2
                t = seconds(dt - dt(1));                
                dt0 = dt(1);
                return
            end
            t = this.times;
            dt0 = this.datetime0;
        end
        function m    = mean_nobaseline(this)
            m = mean(this.timingData_.activity);
        end
        function m    = median_nobaseline(this)
            m = median(this.timingData_.activity);
        end
        function        plot(this, t, qs0, qs1)
            figure
            plot(t, qs0, '-+', ...
                 t, qs1, ':o')
            legend('data', 'est.')
            xlabel('times / s')
            ylabel('activity / cps')
        end
        function mdl  = solveCatheterModel(this, varargin)
            ip = inputParser;
            addParameter(ip, 'catheterModel', [], @(x) isa(x, 'mlswisstrace.CatheterModel'))
            addParameter(ip, 'tracerModel', [], @(x) isa(x, 'mlpet.TracerModel'))
            addParameter(ip, 'inflow', NaT, @isdatetime)
            addParameter(ip, 'outflow', NaT, @isdatetime)
            addParameter(ip, 'observations', NaT, @isdatetime)
            addParameter(ip, 'sigma0', 200, @isnumeric); % cps
            addParameter(ip, 'params0', [], @isnumeric)
            addParameter(ip, 'ub', [], @isnumeric)
            addParameter(ip, 'lb', [], @isnumeric)
            parse(ip, varargin{:})   
            ipr = ip.Results;
            
            [t,dt0] = this.datetimes2times(ipr.observations); % t = [0 1 2 ...], dt0 := datetime(t(1))
            [box,idx0,idxF] = this.boxcar( ...
                'tracerModel', ipr.tracerModel, ...
                'times', t, ...
                'datetime0', dt0, ...
                'inflow', ipr.inflow, ...
                'outflow', ipr.outflow);
            
            %box = 0.5650 * box;
            
            q = this.coincidence(idx0:idxF);            
            params = ipr.params0 * (0.5 + rand());
            options_fmincon = optimoptions('fmincon', ...
                'FunctionTolerance', 1e-9, ...
                'OptimalityTolerance', 1e-9);
            options = optimoptions('simulannealbnd', ...                
                'AnnealingFcn', 'annealingboltz', ...
                'FunctionTolerance', eps, ...
                'HybridFcn', {@fmincon, options_fmincon}, ...
                'InitialTemperature', 20, ...
                'ReannealInterval', 200, ...
                'TemperatureFcn', 'temperatureexp');            
                %'Display', 'diagnose', ...
                %'PlotFcns', {@saplotbestx,@saplotbestf,@saplotx,@saplotf,@saplotstopping,@saplottemperature} ...
 			[params1,sse,exitflag,output] = simulannealbnd( ...
                @(pars_) ipr.catheterModel.simulanneal_objective(pars_, box, t, q, ipr.sigma0), ...
                params, ipr.lb, ipr.ub, options);
            
            mdl = struct('params', params, 'params1', params1, 'sse', sse, 'exitflag', exitflag, 'output', output);
            disp(mdl)
            this.plot(t, q, ipr.catheterModel.synthesis(params1, box, t))
        end        
        function s    = std_nobaseline(this)
            s = std(this.timingData_.activity);
        end
        function tbl  = tabulateCalibrationMeasurements(this)
            hh =  [16    17 17 17   19 19 19   19 20 20 20 20]';
            mm =  [58    42 46 50    7 11 15   59  3  7 11 15]';
            observations0 = datetime(2019,9,30,hh,mm,0, 'TimeZone', 'America/Chicago');
            hh1 = [16    17 17 17   19 19 19   20 20 20 20 20]';
            mm1 = [59    43 47 51    8 12 16    0  4  8 12 16]';
            ss1 = [ 8     0  0  0    0  0  0    0  0  0  0  0]';
            inflow = datetime(2019,9,30,hh1,mm1,ss1, 'TimeZone', 'America/Chicago');
            hh2 = [17    17 17 17   19 19 19   20 20 20 20 20]';
            mm2 = [ 3    45 49 53   10 14 18    2  6 10 14 18]';
            outflow = datetime(2019,9,30,hh2,mm2,0, 'TimeZone', 'America/Chicago');
            observationsF = outflow + minutes(2);
            observations  = [observations0 observationsF];
            tbl = table(observations, inflow, outflow, ...
                'VariableNames', {'observations', 'inflow', 'outflow'});
        end
        function this = updateTimingData(this, aDatetime)
            %% UPDATETIMINGDATA progressively shrinks this.timingData_ by imposing time limits based on
            %  @param aDatetime.
            
            % this.timingData_ = 
            this.timingData_.findCalibrationFrom(aDatetime);
        end
        
 		function this = TwiliteCatheterCalibration(varargin)
 			%% TWILITECATHETERCALIBRATION
            %  @param dt.
            %  @param invEfficiency.
            %  @param expectedBaseline.
            %  @param doMeasureBaseline.
       
 			this = this@mlswisstrace.AbstractTwilite(varargin{:});
            this.isDecayCorrected = false;
 		end
    end 
    
    %% PROTECTED
    
    properties (Access = protected)
        baselineRange_ % time index
        samplingRange_ % time index
    end
    
    %% HIDDEN @deprecated
    
    methods (Hidden)
        function [m,s] = calibrationBaseline(this)
            %% CALIBRATIONBASELINE returns specific activity
            %  @returns m, mean
            %  @returns s, std
            
            cnts = this.counts.*this.taus;
            cnts = cnts(this.baselineRange_);
            sa   = cnts/this.arterialCatheterVisibleVolume;
            m    = mean(sa);
            s    = std(sa);
        end
        function [m,s] = calibrationMeasurement(this)
            %% CALIBRATIONMEASUREMENT returns specific activity without baseline
            %  @returns m, mean
            %  @returns s, std
            
            [m,s] = this.calibrationSample;
             m    = m - this.calibrationBackground;
        end
        function [m,s] = calibrationSample(this)
            %% CALIBRATIONSAMPLE returns specific activity
            %  @returns m, mean
            %  @returns s, std
            
            tzero  = this.times(this.samplingRange_(1));
            dccnts = this.decayCorrection_.correctedCounts(this.counts, tzero).*this.taus;
            dccnts = dccnts(this.samplingRange_);
            sa     = dccnts/this.arterialCatheterVisibleVolume;
            m      = mean(sa);
            s      = std(sa);
        end
        function this  = findCalibrationIndices(this)
            minCnts = min(this.counts);
            cappedCnts = [minCnts*ones(1,5) this.counts minCnts*ones(1,5)];
            [~,tup]   = max(diff(smooth(cappedCnts))); % smoothing range = 5
            tup = tup - 5;
            [~,tdown] = min(diff(smooth(cappedCnts)));
            tdown = tdown - 5;
            smplRng   = tup:tdown;
            N = length(this.counts);
            Npre = smplRng(1);
            Npost = N - smplRng(end);
            if (Npre > Npost)
                baseRng = 1:smplRng(1)-1;
            else
                baseRng = smplRng(end)+1:N;
            end
            this.samplingRange_ = smplRng;
            this.baselineRange_ = baseRng;
        end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

