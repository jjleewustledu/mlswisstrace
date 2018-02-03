classdef AbstractTwilite < mlpet.AbstractAifData
	%% ABSTRACTTWILITE  

	%  $Revision$
 	%  was created 20-Jul-2017 00:21:47 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlpet/src/+mlpet.
 	%% It was developed on Matlab 9.2.0.538062 (R2017a) for MACI64.  Copyright 2017 John Joowon Lee.
 	
	properties (Dependent)
        channel1
        channel2
        coincidence % counts/s
        counts2specificActivity
        tableTwilite
    end

	methods 
        
        %% GET 
        
        function c    = get.channel1(this)
            c = this.tableTwilite_.channel1( ...
                this.datetimeSelection(this.datetimeOfTableTwilite));
        end
        function c    = get.channel2(this)
            c = this.tableTwilite_.channel2( ...
                this.datetimeSelection(this.datetimeOfTableTwilite));
        end
        function c    = get.coincidence(this)
            c = this.tableTwilite_.coincidence( ...
                this.datetimeSelection(this.datetimeOfTableTwilite));
        end
        function g    = get.counts2specificActivity(this)
            g = this.counts2specificActivity_;
        end
        function this = set.counts2specificActivity(this, s)
            assert(isnumeric(s));
            this.counts2specificActivity_ = s;
            this = this.updateActivities;
        end
        function g    = get.tableTwilite(this)
            g = this.tableTwilite_;
        end
                
        %%         
        
        function bols = boluses(this)
            bols = this.timeSeries_.boluses;
        end
        function this = crossCalibrate(this, varargin)
        end       
        function dt_  = datetime(this, varargin)
            dt_ = this.datetimeOfTableTwilite;
            dt_ = dt_(this.datetimeSelection(dt_));
            if (~isempty(varargin))
                dt_ = dt_(varargin{:});
            end
        end
        function        plot(this, varargin)
            figure;
            plot(datetime(this), this.coincidence, varargin{:});
            xlabel('datetime(this)');
            ylabel('this.coincidence');
            title(['Twilite:  ' this.fqfilename], 'Interpreter', 'none');
        end
        function save(~)
            error('mlswisstrace:notImplemented', 'Twilite.save');
        end
        function v    = visibleVolume(this)
            v = this.arterialCatheterVisibleVolume*ones(size(this.times)); % empirically measured on Twilite
        end
 	end 
    
    %% PROTECTED
    
    properties (Access = protected)
        counts2specificActivity_ = nan
        datetimeF_
        tableTwilite_
        timeSeries_
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
        function dt_  = datetimeOfTableTwilite(this)
            tt = this.tableTwilite_;
            dt_ = datetime( ...
                tt.year, tt.month, tt.day, tt.hour, tt.min, tt.sec, ...
                'TimeZone', mldata.TimingData.PREFERRED_TIMEZONE);
        end
        function tf = datetimeSelection(this, dt_)
            if (isempty(this.datetimeF_))
                tf = dt_ >= this.datetime0;
                return
            end
            tf = dt_ >= this.datetime0 & dt_ <= this.datetimeF_;
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
        function s    = tableTwilite2times(this)
            d = this.datetime;
            s = seconds(d - d(1));
            s = ensureRowVector(s);
        end
        function c    = tableTwilite2counts(this)
            c = ensureRowVector(this.tableTwilite_.coincidence);
        end
        function this = updateTimingData(this)
            td = this.timingData_;
            td.times = this.tableTwilite2times;
            this.timingData_ = td;
        end
        function this = updateActivities(this)
            bol = this.timeSeries_.findBolus(this.doseAdminDatetime);
            this.datetimeF_ = bol.datetimeF;
            this.counts_ = bol;
%            this.specificActivity_ = this.counts2specificActivity_*this.counts_;
        end
        
 		function this = AbstractTwilite(varargin)
 			%% ABSTRACTTWILITE

 			this = this@mlpet.AbstractAifData(varargin{:});
            this = this.readtable;
            this = this.updateTimingData;
            this.timeSeries_ = mlpet.TimeSeries(this.coincidence, this.datetime, 'dt', this.dt);
            
            this = this.updateActivities;
 		end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

