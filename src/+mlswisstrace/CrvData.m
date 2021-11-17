classdef CrvData < handle & matlab.mixin.Heterogeneous & matlab.mixin.Copyable
	%% CRVDATA is a lightweight container for crv data useful for manual exploration and QA.
    %  See also:  mlswisstrace.TwiliteData

	%  $Revision$
 	%  was created 02-Nov-2021 13:18:20 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlswisstrace/src/+mlswisstrace.
 	%% It was developed on Matlab 9.11.0.1769968 (R2021b) for MACI64.  Copyright 2021 John Joowon Lee.
 	
	properties
        count_density_to_activity_density = 1
        filename
 		XLabel = 'datetime' % 'duration', 'seconds', otherwise 'datetime'
    end

    methods (Static)
        function this = createFromFilename(fn)
            %% synonymous with ctor.
            %  @param required fn is a filename.

            this = mlswisstrace.CrvData(fn);
        end
    end

	methods 
        function this = CrvData(varargin)
            %  @param required fn is a filename.
 
            ip = inputParser;
            addRequired(ip, 'fn', @isfile)
            addParameter(ip, 'XLabel', 'datetime', @ischar)
            addParameter(ip, 'counts2activity', 1, @isnumeric)
            parse(ip, varargin{:})
            ipr = ip.Results;

            [~,~,ext] = fileparts(ipr.fn);
            assert(strcmpi(ext, '.crv'), 'mlswisstrace.CrvData.ctor does not support extension %s', ext)
            this.filename = ipr.fn;
            this.readcrv(ipr.fn);
            this.XLabel = ipr.XLabel;
            this.count_density_to_activity_density = ipr.counts2activity;
        end

        function dt = dateTag(this)
            startTime = this.crvTimetable.Properties.StartTime;
            yy = year(startTime);
            mm = month(startTime);
            dd = day(startTime);
            dt = sprintf('_dt%u%02u%02u', yy, mm, dd);
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
        function t = table(this)
            t = timetable2table(this.crvTimetable);
        end
        function tt = timetable(this)
            tt = this.crvTimetable;
        end
        function this = writecrv(this, fn)
            assert(~isfile(fn), 'mlswisstrace.CrvData.writecrv found an existing file %s', fn)
            [~,~,ext] = fileparts(fn);
            assert(strcmpi(ext, '.crv'), 'mlswisstrace.CrvData does not support extension %s', ext)
            this.filename = fn;

            T = this.crvTimetable.Time;
            y = year(T);
            m = month(T);
            d = day(T);
            H = hour(T);
            M = minute(T);
            S = second(T);
            coin = this.crvTimetable.Coincidence;
            ch1 = this.crvTimetable.Channel1;
            ch2 = this.crvTimetable.Channel2;
            fid = fopen(this.filename, 'w');
            if ~isempty(ch1) && ~isempty(ch2)
                A = [y';m';d';H';M';S';coin';ch1';ch2'];
                fprintf(fid, '%u %u %u %u %u %.3f\t%.0f\t%.0f\t%.0f\n', A);
            else
                A = [y';m';d';H';M';S';coin'];
                fprintf(fid, '%u %u %u %u %u %.3f\t%.0f\n', A);
            end
            fclose(fid);
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

