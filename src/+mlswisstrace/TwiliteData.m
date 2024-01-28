classdef TwiliteData < handle & mlpet.AbstractTracerData
	%% TWILITEDATA  

	%  $Revision$
 	%  was created 17-Oct-2018 15:56:25 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlswisstrace/src/+mlswisstrace.
 	%% It was developed on Matlab 9.4.0.813654 (R2018a) for MACI64.  Copyright 2018 John Joowon Lee.
 	
    properties (Dependent)
        baselineActivity
        baselineActivityDensity
        baselineCountRate % countRate
        baselineSup
        pumpRate 
        radMeasurements
        tableTwilite % all stored data
        visibleVolume 
    end

	methods %% GET
        function g = get.baselineActivity(this)
            g = this.activityOverCountRate_*this.baselineCountRate;
        end
        function g = get.baselineActivityDensity(this)
            g = this.baselineActivity/this.visibleVolume;
        end
        function g = get.baselineCountRate(this)
            g = this.baselineCountRate_;
        end
        function g = get.baselineSup(~)
            g = 200;
        end
        function g = get.pumpRate(this)
            %% default := 5 mL/min
            
            g = this.pumpRate_;
        end
        function g = get.radMeasurements(this)
            g = this.radMeasurements_;
        end
        function g = get.tableTwilite(this)
            g = this.tableTwilite_;
        end
        function g = get.visibleVolume(this)
            %% of catheter, default := 0.27 mL, default := 0.14 mL for datetime < 20170412
            
            this.visibleVolume_ = this.radMeasurements.twilite.VISIBLEVolume_ML;
            if isdatetime(this.datetimeForDecayCorrection) && ...
                ~isnat(this.datetimeForDecayCorrection) && ...
                    this.datetimeForDecayCorrection < datetime(2017,4,12, 'TimeZone', mlpipeline.ResourcesRegistry.instance().preferredTimeZone)
                this.visibleVolume_ = 0.14; % mL for Medex REF 536035, 152.4 cm, clamp APV = 1.1. mL
            end
            g = this.visibleVolume_;
        end
    end

    methods
        function a = activity(this, varargin)
            %% Bq
            %  decayCorrected logical = false.
 			%  datetimeForDecayCorrection datetime = NaT, updates internal
            %  index0 double {@isnumeric} = this.index0
            %  indexF double {@isnumeric} = this.indexF
            
            a = this.activityOverCountRate_*this.countRate(varargin{:});
            a = a/this.branchingRatio;
        end
        function a = activityDensity(this, varargin)
            %% Bq/mL
            %  decayCorrected logical = false.
 			%  datetimeForDecayCorrection datetime = NaT, updates internal
            %  index0 double {@isnumeric} = this.index0
            %  indexF double {@isnumeric} = this.indexF
            
            a = this.activity(varargin{:})/this.visibleVolume;
        end
        function appendActivityDensity(this, dt, activityDensity)
            arguments
                this mlswisstrace.TwiliteData
                dt datetime
                activityDensity double
            end
            assert(length(dt) == length(activityDensity))
            coin = activityDensity*this.visibleVolume/this.activityOverCountRate_ + ...
                mean(this.baselineCountRate);
            N = length(dt);
            T = this.tableTwilite_;
            T(T.datetime >= dt(1),:) = [];
            U = table(ascol(dt), ascol(coin), zeros(N,1), zeros(N,1), ...
                VariableNames={'datetime' 'coincidences' 'channel1' 'channel2'});
            this.tableTwilite_ = [T; U];

            % fundamental data structures are times, time0, timeF, datetimeMeasured
            this.timingData_.times = this.timingData_.timing2num( ...
                this.tableTwilite_.datetime - this.tableTwilite_.datetime(1));
            this.timingData_.timeF = this.timingData_.times(end);
        end
        function c = countRate(this, varargin)
            %% cps
            %  decayCorrected logical = false.
 			%  datetimeForDecayCorrection datetime = NaT, updates internal
            %  index0 double {@isnumeric} = this.index0
            %  indexF double {@isnumeric} = this.indexF
            
            c = this.measurement(varargin{:});
        end
        function this = decayCorrect(this)
            %% removes baselineCountRate from internal representation then decay-corrects
            
            if this.decayCorrected_
                return
            end
            if ~isnice(this.baselineCountRate)
                this.findBaseline(this.datetimeMeasured);
            end
            c = this.tableTwilite.coincidences - mean(this.baselineCountRate);
            c(c < 0) = 0;
            c = asrow(c) .* 2.^( (this.times - this.timeForDecayCorrection)/this.halflife);
            this.tableTwilite_.coincidences = ascol(c);
            this.decayCorrected_ = true;
        end
        function this = decayUncorrect(this)
            if ~this.decayCorrected_
                return
            end
            c = this.tableTwilite.coincidences;
            c = asrow(c) .* 2.^(-(this.times - this.timeForDecayCorrection)/this.halflife);
            this.tableTwilite_.coincidences = ascol(c);
            this.decayCorrected_ = false;
        end
        function this = findBaseline(this, doseAdminDatetime1st)
            %% FINDBASELINE infers baselineCountRate from datetimeMeasured to doseAdminDatetime1st,
            %  but if doseAdminDatetime1st <= datetimeMeasured || countRate('index0', 1, 'indexF', 10) excessively high, 
            %  infers baselineCountRate from last 60 sec of available Twilite countRate.
            
            assert(isdatetime(doseAdminDatetime1st) && ~isnat(doseAdminDatetime1st))
            if this.datetimeMeasured < doseAdminDatetime1st && mean(this.countRate('index0', 1, 'indexF',10)) < this.baselineSup
                doseAdminIndex1st = round(seconds(doseAdminDatetime1st - this.datetimeMeasured));
                doseAdminIndex1st = max(doseAdminIndex1st, 1);
                this.baselineCountRate_ = this.countRate('index0', 1, 'indexF',doseAdminIndex1st);
            else
                % infer baselineCountRate from last 60 sec of twiliteTable                
                idxF = this.timingData_.indexF;
                this.baselineCountRate_ = this.countRate('index0', idxF-59, 'indexF', idxF);
            end
            
            if mean(this.baselineCountRate_) > 300
                cps = this.radMeasurements.twilite.TwiliteBaseline_CoincidentCps;
                if isnumeric(cps)
                    this.baselineCountRate_ = cps;
                else
                    error('mlswisstrace:ValueError', ...
                        'TwiliteData.findBaseline.baselineCountRate_->%g', ...
                        this.baselineCountRate_);
                end
            end
        end
        function this = findBolus(this, doseAdminDatetime)
            %% FINDBOLUS finds start and termination of bolus; this.index0 := start; this.indexF := termination.
            %  Manages contexts whereby bolus starts before datastream or bolus terminates after datastream.
            %
            %  |bbbb        |  bbbb      |    bbbb    |bbbbbbbb    |.  .. .
            %  ---------    ---------    ---------    ---------    ---------  
            
            assert(isdatetime(doseAdminDatetime) && ~isnat(doseAdminDatetime))
            doseAdminIndex = round(seconds(doseAdminDatetime - this.datetimeMeasured));
            doseAdminIndex = max(doseAdminIndex, 1);
            terminationIndex = min(doseAdminIndex + 600, length(this.times));
            thresh = mean(this.baselineCountRate) + 6*std(this.baselineCountRate);
            
            % find index just prior to bolus inflow
            idx0 = 1;
            while idx0 == 1 && doseAdminIndex > 1                
                % manage bolus that started prior to start of data
                doseAdminIndex = doseAdminIndex - 1;
                [~,idx0] = max(this.countRate('index0', doseAdminIndex, 'indexF',terminationIndex) > thresh);                
            end
            this.index0 = doseAdminIndex + idx0 - 1;
            
            % find index of bolus peak
            [~,idxPeak] = max(this.countRate('index0', this.index0, 'indexF', terminationIndex));
            
            % find index just after bolus terminates
            [~,idxF] = max(this.countRate('index0', this.index0+idxPeak, 'indexF', this.indexF) < mean(this.baselineCountRate));
            this.indexF = this.index0 + idxPeak + idxF - 1;
            if idxF == 1 && this.indexF < this.indices(end)                
                % manage bolus that persists to end of data
                this.indexF = this.indices(end);
            end
            
            assert(this.indexF > this.index0, 'mlswisstrace:ValueError', 'TwiliteData.findBolus()')
        end
        function this = read(this, varargin)
            %% updates datetimeMeasured and timingData_.times
            %  @param required fqfnCrv is file.
            
            ip = inputParser;
            addRequired(ip, 'fqfnCrv', @isfile)
            parse(ip, varargin{:}); 
            ipr = ip.Results;
                      
            assert(isfile(ipr.fqfnCrv), ...
                'mlswisstrace.TwiliteData.read could not open %s', ipr.fqfnCrv);
            assert(~isfolder(ipr.fqfnCrv), ...
                'mlswisstrace.TwiliteData.read received a path without expected file: %s', ipr.fqfnCrv);
            tbl = readtable(ipr.fqfnCrv, ...
                'FileType', 'text', 'ReadVariableNames', false, 'ReadRowNames', false);            
            dt = datetime(tbl.Var1, tbl.Var2, tbl.Var3, tbl.Var4, tbl.Var5, tbl.Var6, ...
                'TimeZone', mlpipeline.ResourcesRegistry.instance().preferredTimeZone);
            offset = this.radMeasurements.clocks{'PMOD workstation', 'TimeOffsetWrtNTS____s'};
            if offset ~= 0
                dt = dt - seconds(offset);
            end
            coin = tbl.Var7;
            if length(tbl.Properties.VariableNames) >= 9
                ch1 = tbl.Var8;
                ch2 = tbl.Var9;
            else
                ch1 = nan(size(coin));
                ch2 = nan(size(coin));
            end            
            this.tableTwilite_ = table(dt, coin, ch1, ch2, ...
                'VariableNames', {'datetime' 'coincidences' 'channel1' 'channel2'});
            this.timingData_.datetimeMeasured = dt(1);
            this.timingData_.times = this.timingData_.timing2num(dt - dt(1));
        end
        function this = shiftWorldlines(this, Dt, varargin)
            %% shifts worldline of internal data self-consistently
            %  @param required Dt is scalar:  timeShift > 0 shifts into future; timeShift < 0 shifts into past.
            %  @param shiftDatetimeMeasured is logical.
            
            ip = inputParser;
            addRequired(ip, 'Dt', @isscalar)
            addParameter(ip, 'shiftDatetimeMeasured', true, @islogical)
            parse(ip, Dt, varargin{:})
            assert(isscalar(this.halflife))
            assert(isrow(this.datetimeMeasured))
            
            Dt = asrow(Dt);
            c = asrow(this.tableTwilite.coincidences);
            this.tableTwilite_.coincidences = ascol(c .* 2.^(-Dt/this.halflife));
            
            if ip.Results.shiftDatetimeMeasured
                this.datetimeMeasured = this.datetimeMeasured + seconds(Dt);
            end
        end
		
 		function this = TwiliteData(varargin)
 			%% TWILITEDATA
            %  @param isotope in mlpet.Radionuclides.SUPPORTED_ISOTOPES.  MANDATORY.
            %  @param tracer.
            %  @param datetimeMeasured is the measured datetime for times(1).  MANDATORY.
 			%  @param datetimeForDecayCorrection.
            %  @param dt is numeric and must satisfy Nyquist requirements of the client.
 			%  @param taus  are frame durations.
 			%  @param time0 >= this.times(1).
 			%  @param timeF <= this.times(end).
 			%  @param times are frame starts.
            %
            %  @param pumpRate, default := 5 mL/min.
            %  @param visibleVolume, default := 0.27 mL, default := 0.14 mL for datetime < 20170412.
            %  @param activityOverCountRate, an initial scaling, nominally ~ 46.1475, determined from historical data.
            
            this = this@mlpet.AbstractTracerData(varargin{:});
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'pumpRate', 5, @isnumeric)
            addParameter(ip, 'visibleVolume', NaN, @isnumeric)
            addParameter(ip, 'activityOverCountRate', 46.1475, @isnumeric)
            addParameter(ip, 'radMeasurements', [], @(x) isa(x, 'mlpet.RadMeasurements'))
            addParameter(ip, 'fqfnCrv', '', @istext)
            parse(ip, varargin{:})
            ipr = ip.Results;
            
            this.decayCorrected_ = false;
            
            this.pumpRate_ = ipr.pumpRate;
            this.visibleVolume_ = ipr.visibleVolume;
            this.activityOverCountRate_ = ipr.activityOverCountRate;
            if ~isempty(ipr.radMeasurements)
                this.radMeasurements_ = ipr.radMeasurements;
            end
            this.fqfnCrv_ = ipr.fqfnCrv;
 		end
    end 
    
    methods (Static)
        function this = createFromSession(sesd, varargin)
            this = [];
            assert(isa(sesd, 'mlpipeline.ISessionData') || isa(sesd, 'mlpipeline.ImagingMediator'))
            
            try
                rm = mlpet.CCIRRadMeasurements.createFromSession(sesd);
                this = mlswisstrace.TwiliteData( ...
                    'isotope', sesd.isotope, ...
                    'tracer', sesd.tracer, ...
                    'datetimeMeasured', sesd.datetime, ...
                    'radMeasurements', rm, ...
                    varargin{:});
                if isfile(this.fqfnCrv_)
                    this.read(this.fqfnCrv_);
                    sesd.json_metadata.(stackstr()).fqfnCrvs = this.fqfnCrv_;
                elseif contains(lower(sesd.imagingContext.fileprefix), 'phantom') || ...
                        contains(lower(sesd.imagingContext.fileprefix), 'fdg')
                    fn = sprintf('*fdg_dt%s.crv', datestr(sesd.datetime, 'yyyymmdd'));
                    fqfnCrvs = globT(fullfile(getenv('CCIR_RAD_MEASUREMENTS_DIR'), 'Twilite', 'CRV', fn));
                    this.read(fqfnCrvs{1});
                    sesd.json_metadata.(stackstr()).fqfnCrvs = fqfnCrvs{1};
                else
                    fn = sprintf('*o15_dt%s.crv', datestr(sesd.datetime, 'yyyymmdd'));
                    fqfnCrvs = globT(fullfile(getenv('CCIR_RAD_MEASUREMENTS_DIR'), 'Twilite', 'CRV', fn));
                    this.read(fqfnCrvs{1});
                    sesd.json_metadata.(stackstr()).fqfnCrvs = fqfnCrvs{1};
                end
                this.findBaseline(this.datetimeMeasured);
                this.datetimeForDecayCorrection = sesd.datetime;
                this.timingData_.datetime0 = sesd.datetime;
                this.findBolus(sesd.datetime);
            catch ME
                handwarning(ME)
            end
        end
    end
    
    %% PROTECTED
    
    properties (Access = protected)
        activityOverCountRate_
        baselineCountRate_ % as countRate
        fqfnCrv_
        pumpRate_
        radMeasurements_
        tableTwilite_
        visibleVolume_
    end

    methods (Access = protected)
        function m = measurement(this, varargin)
            %% cps

            ip = inputParser;
            ip.KeepUnmatched = true;
            ip.PartialMatching= false;
            addParameter(ip, 'datetimeForDecayCorrection', NaT, @(x) isdatetime(x))
            addParameter(ip, 'doDecayCorrection', false, @islogical)
            addParameter(ip, 'index0', this.index0, @isnumeric)
            addParameter(ip, 'indexF', this.indexF, @isnumeric)
            parse(ip, varargin{:})
            ipr = ip.Results;
            
            if ~isnat(ipr.datetimeForDecayCorrection)
                this.datetimeForDecayCorrection = ipr.datetimeForDecayCorrection;
            end 
            if ipr.doDecayCorrection
                this.decayCorrect();
            end
            m = asrow(this.tableTwilite_.coincidences);
            m = m(ipr.index0:ipr.indexF);
            m = asrow(m);
            m = m/this.branchingRatio;
        end
    end
    
    %% DEPRECATED
    
    methods (Hidden)
        function this = imputeSteadyStateActivityDensity(this, varargin)
            %% @param required t1 is the time at which to start imputation.
            %  @param optional t2 is the time at which to start imputation; default := timeF.
            %                  If t2 > timeF, timeF is moved forward.
            %  @param window is the time interval (sec) immediately prior to t1 that will be averaged for imputation.
            
            ip = inputParser;
            addRequired(ip, 't1', @isscalar)
            addOptional(ip, 't2', this.timeF, @isscalar)
            addParameter(ip, 'window', 20, @isscalar)
            parse(ip, varargin{:})
            ipr = ip.Results;
            ipr.t1 = floor(ipr.t1);
            ipr.t2 = floor(ipr.t2);
            if ipr.t2 > this.timeF
                this.timeF = ipr.t2;
            end
            
            windowTimes = ipr.t1-ipr.window:ipr.t1;
            targetTimes = ipr.t1:ipr.t2;
            if this.decayCorrected
                coin = this.tableTwilite_.coincidences;
                imputation = mean(coin(windowTimes+1));
                coin(targetTimes+1) = imputation;
                this.tableTwilite_.coincidences = coin;
            else                
                coin = this.tableTwilite_.coincidences;
                imputation = coin(windowTimes+1) .* 2.^((windowTimes' - ipr.t1)/this.halflife);
                imputation = mean(imputation);                
                coin(targetTimes+1) = imputation .* 2.^(-(targetTimes' - ipr.t1)/this.halflife);
                this.tableTwilite_.coincidences = coin;
            end
        end
        function this = removeBaselineCountRate(this)            
            if ~all(isnice(this.baselineCountRate))
                this.findBaseline(this.datetimeMeasured);
            end 
            this.tableTwilite_.coincidences = this.tableTwilite_.coincidences - mean(this.baselineCountRate);
        end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end
