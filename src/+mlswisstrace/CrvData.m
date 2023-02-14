classdef CrvData < handle & matlab.mixin.Heterogeneous & matlab.mixin.Copyable
	%% CRVDATA is a lightweight container for crv data useful for manual exploration and QA.
    %  See also:  mlswisstrace.TwiliteData

	%  $Revision$
 	%  was created 02-Nov-2021 13:18:20 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlswisstrace/src/+mlswisstrace.
 	%% It was developed on Matlab 9.11.0.1769968 (R2021b) for MACI64.  Copyright 2021 John Joowon Lee.
 	
	properties
        count_density_to_activity_density = 1 % 1/efficiency
        filename
 		XLabel = 'datetime' % 'duration', 'seconds', otherwise 'datetime'
    end

    properties (Dependent)
        coincidence
        channel1
        channel2
        time
    end

	methods 

        %% GET/SET

        function g = get.coincidence(this)
            g = this.crvTimetable.Coincidence;
        end
        function set.coincidence(this, s)
            this.crvTimetable.Coincidence = ascol(s);
        end
        function g = get.channel1(this)
            g = this.crvTimetable.Channel1;
        end
        function set.channel1(this, s)
            this.crvTimetable.Channel1 = ascol(s);
        end
        function g = get.channel2(this)
            g = this.crvTimetable.Channel2;
        end
        function set.channel2(this, s)
            this.crvTimetable.Channel2 = ascol(s);
        end
        function g = get.time(this)
            g = this.crvTimetable.Time;
        end

        %%

        function dt = dateTag(this)
            startTime = this.crvTimetable.Properties.StartTime;
            yy = year(startTime);
            mm = month(startTime);
            dd = day(startTime);
            dt = sprintf('_dt%u%02u%02u', yy, mm, dd);
        end
        function that = flattenBaseline(this, opts)
            %% FLATTENBASELINE removes rising baseline associated with sticky tracer compounds.
            %  Args:
            %  this mlswisstrace.CrvData
            %  opts.baseline_t0 = 1
            %  opts.baseline_tf = [] % empty -> plotAll()
            %  opts.measurement_t0 = []
            %  opts.measurement_tf = [] % empty -> plotAll()
            %  opts.head double = []
            %  opts.tail double = []
            %  opts.activity = this.coincidence;            

            arguments
                this mlswisstrace.CrvData
                opts.baseline_t0 = 1
                opts.baseline_tf = [] % empty -> plotAll()
                opts.measurement_t0 = []
                opts.measurement_tf = [] % empty -> plotAll()
                opts.head double = []
                opts.tail double = []
                opts.activity = this.coincidence;
            end

            % checks, transformations of inputs
            if isempty(opts.baseline_tf) || isempty(opts.measurement_tf)
                plotAll(this)
                return
            end
            if isempty(opts.measurement_t0)
                opts.measurement_t0 = this.time2idx(opts.baseline_tf) + 1;
            end
            if isempty(opts.head)
                opts.head = mean(this, opts.baseline_t0, opts.baseline_tf);
            end
            if isempty(opts.tail)
                opts.tail = mean(this, opts.measurement_tf + 1, length(this.time));
            end
            bidx0 = this.time2idx(opts.baseline_t0);
            bidxf = this.time2idx(opts.baseline_tf);
            midx0 = this.time2idx(opts.measurement_t0);
            midxf = this.time2idx(opts.measurement_tf);
            
            that = copy(this);
            that.coincidence(bidx0:bidxf) = opts.head;
            that.coincidence(midxf+1:end) = opts.head;
            N = midxf - midx0 + 1;
            that.coincidence(midx0:midxf) = ...
                this.coincidence(midx0:midxf) - linspace(opts.head, opts.tail, N)' + opts.head;

            that.writecrv(strcat(myfileprefix(this.filename), '_flattenBaseline.crv'));
        end
        function t = idx2time(this, idx)
            t = this.time(idx);
        end
        function m = mean(this, idx0, idxf, activity)
            %% MEAN of activity over time interval specified by indices or datetimes or durations.
            %  this mlswisstrace.CrvData
            %  idx0 = 1
            %  idxf = length(this.time)
            %  activity = this.coincidence

            arguments
                this mlswisstrace.CrvData
                idx0 = 1
                idxf = length(this.time)
                activity double = this.coincidence
            end
            idx0 = this.time2idx(idx0);
            idxf = this.time2idx(idxf);

            m = mean(activity(idx0:idxf));
        end
        function h = plot(this, varargin)
            h = this.plotCoincidence(varargin{:});
        end
        function h = plotCoincidence(this, varargin)
            tt = this.crvTimetable;
            scale = this.count_density_to_activity_density;
            switch this.XLabel
                case 'duration'
                    h = plot(tt.Time - tt.Properties.StartTime, scale*tt.Coincidence, varargin{:});
                    xlabel('duration')
                case 'seconds'
                    secs = seconds(tt.Time - tt.Properties.StartTime);
                    h = plot(secs, scale*tt.Coincidence, varargin{:});
                    xlabel('time (s)')
                otherwise
                    h = plot(tt.Time, scale*tt.Coincidence, varargin{:});
            end
            if 1 == this.count_density_to_activity_density
                ylabel('coincidence count rate (counts/s)')
            else
                ylabel('activity density (Bq/mL)')
            end
            title(this.filename, 'Interpreter', 'none')
        end
        function h = plotChannels(this, varargin)
            tt = this.crvTimetable;
            switch this.XLabel
                case 'duration'
                    dur = tt.Time - tt.Properties.StartTime;
                    h = plot(dur, tt.Channel1, dur, tt.Channel2, varargin{:});
                case 'seconds'
                    secs = seconds(tt.Time - tt.Properties.StartTime);
                    h = plot(secs, tt.Channel1, secs, tt.Channel2, varargin{:});
                    xlabel('seconds')
                otherwise
                    h = plot(tt.Time, tt.Channel1, tt.Time, tt.Channel2, varargin{:});            
            end
            ylabel('channel count rate (counts/s)')
            title(this.filename, 'Interpreter', 'none')
            legend({'Channel 1', 'Channel 2'})
        end
        function h = plotAll(this, varargin)
            h = this.plotCoincidence(varargin{:});
            hold('on')
            this.plotChannels(varargin{:});
            hold('off')
            ylabel('count rate (counts/s)')
            legend({'Coincidence', 'Channel 1', 'Channel 2'})
        end
        function fn = prefix2filename(this, p)
            assert(ischar(p))
            fn = sprintf('%s%s.crv', p, this.dateTag);
        end
        function this = smoothdata(this, varargin)
            this.crvTimetable = smoothdata(this.crvTimetable, varargin{:});
        end
        function [cd1,cd2] = split(this, t)
            %% splits the internal timetable from [t(1) ... t(delim-1)] [t(delim) ... t(end)].
            %  @param t(delim) is the delimiting datetime, duration or seconds.
            %  @return cd1, cd2, which are CrvData objects.

            cd1 = copy(this);
            cd2 = copy(this);
            switch class(t)
                case 'duration'
                    bool = this.crvTimetable.Time - this.crvTimetable.Properties.StartTime >= t;
                    [~,delim] = max(bool);
                case 'double'
                    delim = t+1;
                otherwise
                    bool = this.crvTimetable.Time >= t;
                    [~,delim] = max(bool);
            end
            cd1.crvTimetable = this.crvTimetable(1:delim-1, :);
            cd2.crvTimetable = this.crvTimetable(delim:end, :);
        end
        function s = std(this, idx0, idxf, activity)
            %% STD of activity over time interval specified by indices or datetimes or durations.
            %  this mlswisstrace.CrvData
            %  idx0 = 1
            %  idxf = length(this.time)
            %  activity = this.coincidence

            arguments
                this mlswisstrace.CrvData
                idx0 = 1
                idxf = length(this.time)
                activity double = this.coincidence
            end
            idx0 = this.time2idx(idx0);
            idxf = this.time2idx(idxf);

            s = std(activity(idx0:idxf));
        end
        function t = table(this)
            t = timetable2table(this.crvTimetable);
        end
        function tt = timetable(this)
            tt = this.crvTimetable;
        end
        function idx = time2idx(this, t)
            if isduration(t)
                idx = seconds(t);
                return
            end
            if isdatetime(t)
                t = ensureTimeZone(t);
                [~,idx] = max(this.time >= t);
                return
            end
            idx = double(t);
        end
        function this = writecrv(this, fn)
            arguments
                this mlswisstrace.CrvData
                fn {mustBeTextScalar} = this.filename
            end
            if ~isempty(fn)
                assert(~isfile(fn), 'mlswisstrace.CrvData.writecrv found an existing file %s', fn)
                [~,~,ext] = fileparts(fn);
                assert(strcmpi(ext, '.crv'), 'mlswisstrace.CrvData does not support extension %s', ext)
                this.filename = fn;
            end

            T = this.crvTimetable.Time;
            y = year(T);
            m = month(T);
            d = day(T);
            H = hour(T);
            M = minute(T);
            S = second(T);
            coin = this.crvTimetable.Coincidence;
            fid = fopen(this.filename, 'w');
            vns = this.crvTimetable.Properties.VariableNames;
            if any(contains(vns, 'Channel'))
                ch1 = this.crvTimetable.Channel1;
                ch2 = this.crvTimetable.Channel2;
                A = [y';m';d';H';M';S';coin';ch1';ch2'];
                fprintf(fid, '%u %u %u %u %u %.3f\t%.0f\t%.0f\t%.0f\n', A);
            else
                A = [y';m';d';H';M';S';coin'];
                fprintf(fid, '%u %u %u %u %u %.3f\t%.0f\n', A);
            end
            fclose(fid);
        end

        function this = CrvData(varargin)
            %  @param required fn is a filename.
 
            ip = inputParser;
            addRequired(ip, 'fn', @istext)
            addParameter(ip, 'XLabel', 'datetime', @ischar)
            addParameter(ip, 'counts2activity', 1, @isnumeric)
            addParameter(ip, 'time', [], @isdatetime)
            addParameter(ip, 'coincidence', [], @isnumeric)
            parse(ip, varargin{:})
            ipr = ip.Results;
            [~,~,ext] = fileparts(ipr.fn);
            assert(strcmpi(ext, '.crv'), 'mlswisstrace.CrvData.ctor does not support extension %s', ext)
            this.filename = ipr.fn;
            this.XLabel = ipr.XLabel;
            this.count_density_to_activity_density = ipr.counts2activity;

            % construct this.crvTimetable
            if ~isempty(ipr.time) || ~isempty(ipr.coincidence)
                this.crvTimetable = timetable(ipr.time, ipr.coincidence);
                this.crvTimetable.Properties.VariableNames = {'Coincidence'};
            else
                this.readcrv(ipr.fn);
            end
            
            % check integrity
            assert(isvector(this.coincidence));
            assert(isvector(this.channel1));
            assert(isvector(this.channel2));
            assert(isdatetime(this.time));
        end
    end

    methods (Static)
        function this = createFromFilename(fn)
            %% synonymous with ctor.
            %  @param required fn is a filename.

            this = mlswisstrace.CrvData(fn);
        end
    end

    %% PRIVATE

    properties (Access = private)
        crvTimetable
    end

    methods (Access = private)
        function readcrv(this, fn)
            %% selects timezone from mlpipeline.ResourcesRegistry.preferredTimeZone

            try
                tbl = readtable(fn, ...
                    'FileType', 'text', 'ReadVariableNames', false, 'ReadRowNames', false);  
                Time = datetime(tbl.Var1, tbl.Var2, tbl.Var3, tbl.Var4, tbl.Var5, tbl.Var6, ...
                    'TimeZone', mlpipeline.ResourcesRegistry.instance().preferredTimeZone);
                Coincidence = tbl.Var7;
                if length(tbl.Properties.VariableNames) >= 9
                    Channel1 = tbl.Var8;
                    Channel2 = tbl.Var9;
                else
                    Channel1 = nan(size(Coincidence));
                    Channel2 = nan(size(Coincidence));
                end           
            catch ME
                handexcept(ME, 'mlswisstrace.CrvData.read could not interpret the contents of %s', fn)
            end           
            this.crvTimetable = timetable(Time, Coincidence, Channel1, Channel2);
        end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
end

