classdef AbstractTwilite < mlpet.AbstractAifData
	%% ABSTRACTTWILITE  

	%  $Revision$
 	%  was created 20-Jul-2017 00:21:47 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlpet/src/+mlpet.
 	%% It was developed on Matlab 9.2.0.538062 (R2017a) for MACI64.  Copyright 2017 John Joowon Lee.
 		
    properties        
        pumpRate = 5 % mL/min    
        
        fqCrv = fullfile(getenv('CCIR_RAD_MEASUREMENTS_DIR'), 'HYGLY28_VISIT_2_23sep2016_D1.crv');
        fqCrvCal = fullfile(getenv('CCIR_RAD_MEASUREMENTS_DIR'), 'HYGLY28_VISIT_2_23sep2016_twilite_cal_D1.crv');
    end
    
	properties (Dependent)
        channel1 % delimited by datetime0/F
        channel2 % delimited by datetime0/F
        coincidence % counts/s, delimited by datetime0/F
        counts2specificActivity % scalar, TBD by a TwiliteBuilder
        invEfficiency % outer-most efficiency for s.a. determined by cross-calibration, synonymous with counts2SpecificActivity
        tableTwilite % all stored data
    end

	methods
        
        %% GET 
        
        function c    = get.channel1(this)
            c = ensureRowVector(this.tableTwilite_.channel1);
            c = c(this.isValidTableRow);
        end
        function c    = get.channel2(this)
            c = ensureRowVector(this.tableTwilite_.channel2);
            c = c(this.isValidTableRow);
        end
        function c    = get.coincidence(this)
            c = ensureRowVector(this.tableTwilite_.coincidence);
            c = c(this.isValidTableRow);
        end
        function g    = get.counts2specificActivity(this)
            g = this.counts2specificActivity_;
        end
        function this = set.counts2specificActivity(this, s)
            assert(isnumeric(s));
            this.counts2specificActivity_ = s;
            this = this.updateActivities;
        end
        function g    = get.invEfficiency(this)
            g = this.counts2specificActivity;
        end
        function this = set.invEfficiency(this, s)
            this.counts2specificActivity = s;
        end
        function g    = get.tableTwilite(this)
            g = this.tableTwilite_;
        end
                
        %% 
             
        function this = buildCalibrated(this)
            bldr = mlswisstrace.TwiliteBuilder( ...
                'fqfilename', this.fqCrv, ...
                'fqfilenameCalibrator', this.fqCrvCal, ...
                'sessionData', this.sessionData, ...
                'manualData', this.manualData_, ...
                'datetime0', this.doseAdminDatetime);            
            bldr = bldr.buildCalibrated;
            this = bldr.product;
        end
        function dt_  = datetime(this)
            %% DATETIME excludes inappropriate data using this.isValidTableRow.
            
            dt_ = this.tableTwilite2datetime;            
            dt_ = dt_(this.isValidTableRow);
        end
        function        plot(this, varargin)
            figure;
            plot(this.datetime, this.channel1, ...
                 this.datetime, this.channel2, ...
                 this.datetime, this.coincidence, varargin{:});
            xlabel('this.datetime');
            ylabel('channel1, channel2, coincidence');
            title(sprintf('AbstractTwilite.plot:\n%s', this.fqfilename), 'Interpreter', 'none');
        end
        function        plotCounts(this, varargin)  
            figure;
            plot(this.datetime, this.counts, varargin{:});
            xlabel(sprintf('datetime from %s', this.datetime0));
            ylabel('counts');
            title(sprintf('AbstractTwilite.plotCounts:  time0->%g, timeF->%g', this.time0, this.timeF), ...
                'Interpreter', 'none');
        end
        function        plotSpecificActivity(this, varargin)
            figure;
            plot(this.datetime, this.specificActivity, varargin{:});
            xlabel(sprintf('datetime from %s', this.datetime0));
            ylabel('specificActivity');
            title(sprintf( ...
                'AbstractTwilite.plotSpecificActivity:  time0->%g, timeF->%g, Eff^{-1}->%g', ...
                this.time0, this.timeF, this.invEfficiency), ...
                'Interpreter', 'none');
        end
        function        save(~)
            error('mlswisstrace:notImplemented', 'Twilite.save');
        end
        function v    = visibleVolume(this)
            v = this.arterialCatheterVisibleVolume*ones(size(this.times)); % empirically measured on Twilite
        end
 	end     
    
    %% PROTECTED
    
    properties (Access = protected)
        counts2specificActivity_ = nan
        tableTwilite_
        timingData_
    end
    
    methods (Access = protected)
        function vv   = arterialCatheterVisibleVolume(this)
            %% approx. visible volume of 1mm outer-diam. catheter fed into Twilite
            
            entry = this.manualData_.twilite.TWILITE(1);
            entry = entry{1};
            assert(ischar(entry));
            if (lstrfind(entry, 'Medex REF 536035')) % 152.4 cm  Ext. W/M/FLL Clamp APV = 1.1 mL; cut at 40 cm
                vv = 0.14; % mL
                return
            end
            if (lstrfind(entry, 'Braun ref V5424')) % 48 cm len, 0.642 mL priming vol
                vv = 0.27; % mL
                return
            end
            error('mpet:unsupportedParamValue', 'AbstractTwilite:arterialCatheterVisibleVolume');
        end
        function tf   = isValidTableRow(this)
            tt2dt = this.tableTwilite2datetime;
            if (isempty(this.timingData_) || isempty(this.timingData_.datetimeF))
                tf = this.datetime0 >= tt2dt;
                return
            end
            tf = this.timingData_.datetime0 - seconds(1) <= tt2dt & ...
                 tt2dt <= this.timingData_.datetimeF;
        end
        function this = readtable(this, varargin)
            ip = inputParser;
            addOptional(ip, 'fqfnCrv', this.fqfilename, @(x) lexist(x, 'file'));
            parse(ip, varargin{:});            
            
            warning('off', 'MATLAB:table:ModifiedVarnames');   
            warning('off', 'MATLAB:table:ModifiedAndSavedVarnames');  
            
            tbl = readtable(ip.Results.fqfnCrv, ...
                'FileType', 'text', 'ReadVariableNames', false, 'ReadRowNames', false);
            tbl.Properties.VariableNames{'Var1'} = 'year';
            tbl.Properties.VariableNames{'Var2'} = 'month';
            tbl.Properties.VariableNames{'Var3'} = 'day';
            tbl.Properties.VariableNames{'Var4'} = 'hour';
            tbl.Properties.VariableNames{'Var5'} = 'min';
            tbl.Properties.VariableNames{'Var6'} = 'sec';
            tbl.Properties.VariableNames{'Var7'} = 'coincidence';
            tbl.Properties.VariableNames{'Var8'} = 'channel1';
            tbl.Properties.VariableNames{'Var9'} = 'channel2';
            this.tableTwilite_ = tbl;
            
            warning('on', 'MATLAB:table:ModifiedVarnames');
            warning('on', 'MATLAB:table:ModifiedAndSavedVarnames');
            
            this.isPlasma = false;                   
        end
        function dt_  = tableTwilite2datetime(this)
            tt = this.tableTwilite_;
            dt_ = datetime( ...
                tt.year, tt.month, tt.day, tt.hour, tt.min, tt.sec, ...
                'TimeZone', mldata.TimingData.PREFERRED_TIMEZONE);
            dt_ = ensureRowVector(dt_);
        end
        function s    = tableTwilite2times(this)
            dt_ = this.tableTwilite2datetime;
            s = seconds(dt_ - dt_(1));
        end
        function c    = tableTwilite2coincidence(this)
            c = ensureRowVector(this.tableTwilite_.coincidence);
        end
        function c    = tableTwilite2counts(this)
            c = ensureRowVector(this.tableTwilite_.coincidence);
        end
        function c    = tableTwilite2specificActivity(this)
            c = this.counts2specificActivity * this.tableTwilite2counts;
        end
        function this = updateActivities(this)
            %% UPDATEACTIVITIES progressively shrinks this.timingData_ by imposing time limits from
            %  this.doseAdminDatetime.
            
            this = this.updateTimingData;
            this.decayCorrection_ = mlpet.DecayCorrection.factoryFor(this);
            this.counts_ = this.timingData_.activity;
            this.specificActivity_ = this.counts2specificActivity_*this.counts_;
        end
        function this = updateTimingData(this)
            this.timingData_ = this.timingData_.findBolusFrom(this.doseAdminDatetime);
        end
        
 		function this = AbstractTwilite(varargin)
 			%% ABSTRACTTWILITE
            %  @param named doseAdminDatetime refers to the true time for the selected tracer.

 			this = this@mlpet.AbstractAifData(varargin{:});
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'dt', 1,             @isnumeric);
            addParameter(ip, 'doseAdminDatetime', @isdatetime);
            addParameter(ip, 'aifTimeShift', 0,   @isnumeric); % @deprecated
            parse(ip, varargin{:});            
            this = this.readtable;
            this.timingData_ = mlpet.MultiBolusData( ...
                'activity', this.tableTwilite2coincidence, ...
                'times', this.tableTwilite2datetime, ...
                'dt', ip.Results.dt);
            this.timingData_.datetime0 = ip.Results.doseAdminDatetime; % must be separated from mlpetMultiBolusData ctor
            %this = this.shiftTimes(ip.Results.aifTimeShift); % clobbers this.timingData_.activity
            
            this = this.updateActivities;
            this.isDecayCorrected = false;
            this.isPlasma = false;
 		end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

