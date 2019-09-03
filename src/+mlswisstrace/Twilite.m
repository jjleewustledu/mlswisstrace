classdef Twilite < mlswisstrace.AbstractTwilite
	%% TWILITE  

	%  $Revision$
 	%  was created 23-Jan-2017 19:39:08
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/MATLAB-Drive/mlswisstrace/src/+mlswisstrace.
 	%% It was developed on Matlab 9.1.0.441655 (R2016b) for MACI64.  Copyright 2017 John Joowon Lee.
    
    methods (Static)
        function this = createFromSessionData(varargin)
            %% @param required sessionData is an mlpipeline.ISessionData.
            %  @param tracer := 'cal', 'fdg', 'oc1', 'oo2', 'ho3'; default := 'cal'.
            %  @param crvFqfn defaults to construction from sessionData.
            
            ip = inputParser;
            addRequired(ip, 'sessionData', @(x) ixa(x, 'mlpipeline.ISessionData'))
            addParemeter(ip, 'tracer', 'fdg', @ischar);
            addParameter(ip, 'crvFqfn', '', @ischar);
            parse(ip, varargin{:})
            ipr = ip.Results;
            
            if isempty(ipr.crvFqfn)
                dt = ipr.sessionData.datetime;
                crvpth = fullfile(getenv('HOME'), 'Documents', 'private', 'Twilite', 'CRV', '');
                crvfp = sprintf('%s_dt%d%02d%02d', crv_prefix(), dt.Year, dt.Month, dt.Day);
                ipr.crvFqfn = fullfile(crvpth, [crvfp '.crv']);
                if ~isfile(ipr.crvFqfn)   
                    crvfp = sprintf('%s_dt%d%02d%02d', 'o15_fdg', dt.Year, dt.Month, dt.Day);
                    ipr.crvFqfn = fullfile(crvpth, [crvfp '.crv']);
                end
                assert(isfile(ipr.crvFqfn))
            end
            crm = mlpet.CCIRRadMeasurements.createByDate(ipr.sessionData.datetime);
            this = mlswisstrace.Twilite( ...
                'fqfilename', ipr.crvFqfn, ...
                'sessionData', ipr.sessionData, ...
                'manualData', crm, ...
                'doseAdminDatetime', crm.datetimeTracerAdmin('tracer', ipr.tracer));
            
            function p = crv_prefix(t)
                re = regexp(lower(t), '[a-z]+', 'match');
                switch re{1}
                    case 'cal'
                        p = 'fdg';
                    case {'fdg' 'oc' 'oo' 'ho'}
                        p = 'o15';
                end
            end
        end
    end
    
    methods         
        function this = updateTimingData(this, aDatetime)
            %% UPDATETIMINGDATA progressively shrinks this.timingData_ by imposing time limits based on
            %  @param aDatetime.
            
            this.timingData_ = this.timingData_.findBolusFrom(aDatetime);
        end
        function this = updateActivities(this)
            %% UPDATEACTIVITIES updates counts_ from timingData_ and specificActivity_ with counts2specificActivity_.
            
            this.counts_ = this.timingData_.activity;
            this.specificActivity_ = this.counts2specificActivity_*this.counts_;
        end 
        
 		function this = Twilite(varargin)
 			%% TWILITE
            %  @param dt.
            %  @param invEfficiency.
            %  @param expectedBaseline.
            %  @param doMeasureBaseline.
            
 			this = this@mlswisstrace.AbstractTwilite(varargin{:});   
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'dt', 1,                 @isnumeric);
            addParameter(ip, 'invEfficiency', nan,    @isnumeric);
            addParameter(ip, 'expectedBaseline', 92,  @isnumeric);
            addParameter(ip, 'doMeasureBaseline', true, @islogical);
            parse(ip, varargin{:});
            ipr = ip.Results;
            
            this = this.readtable;
            ttdt = this.tableTwilite2datetime;
            this.timingData_ = mlpet.MultiBolusData( ...
                'activity', this.tableTwilite2coincidence, ...
                'times', ttdt, ...
                'datetimeMeasured', ttdt(1), ...
                'dt', ipr.dt, ...
                'expectedBaseline', ipr.expectedBaseline, ...
                'doMeasureBaseline', ipr.doMeasureBaseline, ...
                'radionuclide', mlpet.Radionuclides(this.isotope));
            this.counts2specificActivity_ = ipr.invEfficiency;    
            
            this = this.updateTimingData(this.doseAdminDatetime); 
            this = this.updateActivities;
            this.isDecayCorrected_ = false;
            this.isPlasma = false;  
            this = this.updateDecayCorrection;  
        end        
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

