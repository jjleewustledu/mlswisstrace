classdef Twilite < mlswisstrace.AbstractTwilite
	%% TWILITE  

	%  $Revision$
 	%  was created 23-Jan-2017 19:39:08
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/MATLAB-Drive/mlswisstrace/src/+mlswisstrace.
 	%% It was developed on Matlab 9.1.0.441655 (R2016b) for MACI64.  Copyright 2017 John Joowon Lee.
    
    methods (Static)
        function this = createFromDatetime(varargin)
            import mlswisstrace.Twilite
            
            ip = inputParser;
            addRequired(ip, 'datetime', @isdatetime)
            addParameter(ip, 'crvFqfn', '', @ischar)
            parse(ip, varargin{:})
            ipr = ip.Results;            
            crm = mlpet.CCIRRadMeasurements.createFromDate(ipr.datetime);
            tracer = crm.datetime2tracer(ipr.datetime);
            isotope = crm.datetime2isotope(ipr.datetime);
            
            if isempty(ipr.crvFqfn)
                dt = ipr.datetime;
                crvpth = fullfile(getenv('HOME'), 'Documents', 'private', 'Twilite', 'CRV', '');
                crvfp = sprintf('%s_dt%d%02d%02d', ...
                    Twilite.crv_prefix(tracer), dt.Year, dt.Month, dt.Day);
                ipr.crvFqfn = fullfile(crvpth, [crvfp '.crv']);
                crvfp = sprintf('%s_dt%d%02d%02d', Twilite.crv_prefix(tracer), dt.Year, dt.Month, dt.Day);
                ipr.crvFqfn = fullfile(crvpth, [crvfp '.crv']);
                assert(isfile(ipr.crvFqfn))
            end
            this = mlswisstrace.Twilite( ...
                'fqfilename', ipr.crvFqfn, ...
                'isotope', isotope, ...
                'manualData', crm, ...
                'doseAdminDatetime', ipr.datetime);
        end
        function this = createFromSessionData(varargin)
            %% @param required sessionData is an mlpipeline.ISessionData.
            %  @param tracer := 'cal', 'fdg', 'oc1', 'oo2', 'ho3'; default := 'cal'.
            %  @param crvFqfn defaults to construction from sessionData.
            
            import mlswisstrace.Twilite
            
            ip = inputParser;
            addRequired(ip, 'sessionData', @(x) ixa(x, 'mlpipeline.ISessionData'))
            addParemeter(ip, 'tracer', 'fdg', @ischar);
            addParameter(ip, 'crvFqfn', '', @ischar);
            parse(ip, varargin{:})
            ipr = ip.Results;
            
            if isempty(ipr.crvFqfn)
                dt = ipr.sessionData.datetime;
                crvpth = fullfile(getenv('HOME'), 'Documents', 'private', 'Twilite', 'CRV', '');
                crvfp = sprintf('%s_dt%d%02d%02d', Twilite.crv_prefix(ipr.tracer), dt.Year, dt.Month, dt.Day);
                ipr.crvFqfn = fullfile(crvpth, [crvfp '.crv']);
                if ~isfile(ipr.crvFqfn)   
                    crvfp = sprintf('%s_dt%d%02d%02d', 'o15_fdg', dt.Year, dt.Month, dt.Day);
                    ipr.crvFqfn = fullfile(crvpth, [crvfp '.crv']);
                end
                assert(isfile(ipr.crvFqfn))
            end
            crm = mlpet.CCIRRadMeasurements.createFromDate(ipr.sessionData.datetime);
            this = mlswisstrace.Twilite( ...
                'fqfilename', ipr.crvFqfn, ...
                'sessionData', ipr.sessionData, ...
                'manualData', crm, ...
                'doseAdminDatetime', crm.datetimeTracerAdmin('tracer', ipr.tracer));
        end
        function p = crv_prefix(t)
            re = regexp(lower(t), '[a-z]+', 'match');
            switch re{1}
                case 'cal'
                    p = 'fdg';
                case {'fdg' 'co' 'oc' 'oo' 'ho' 'c[15o]' 'o[15o]' 'h2[15o]' '[18f]dg' ...
                      '15o' '18f'}
                    p = 'o15';
                otherwise
                    p = '';
            end
        end
    end
    
    methods         
        function this = updateTimingData(this, aDatetime)
            %% UPDATETIMINGDATA progressively shrinks this.timingData_ by imposing time limits based on
            %  @param aDatetime.
            
            this.timingData_ = this.timingData_.findBolusFrom(aDatetime);
        end
        
 		function this = Twilite(varargin)
 			%% TWILITE
            %  @param dt.
            %  @param invEfficiency.
            %  @param expectedBaseline.
            %  @param measuredBaseline.
            
 			this = this@mlswisstrace.AbstractTwilite(varargin{:});    
        end        
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

