classdef Catheter_DT20190930 < handle
	%% CATHETER_DT20190930  

	%  $Revision$
 	%  was created 09-Feb-2020 13:51:38 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlswisstrace/src/+mlswisstrace.
 	%% It was developed on Matlab 9.7.0.1296695 (R2019b) Update 4 for MACI64.  Copyright 2020 John Joowon Lee.
 	
	properties (Constant)
        dt = 1
        t0 = 9.8671 % mean from data of 2019 Sep 30
    end
    
    properties
        do_close_fig
        fqfileprefix
        hct
        Measurement
        model_kind
        sgolayWindow1 = 12
        sgolayWindow2 = 4        
        tracer
    end
    
    properties (Dependent)
        fqfp
        halflife
        radialArteryKit
 		timeInterpolants        
    end

	methods 
        
        %% GET, SET
        
        function g = get.fqfp(this)
            g = this.fqfileprefix;
        end
        function     set.fqfp(this, s)
            assert(istext(s))
            this.fqfileprefix = s;
        end
        function g = get.halflife(this)
            switch upper(this.tracer)
                case {'FDG' '18F' 'RO948' 'MK6240' 'GTP1' 'ASEM' 'AZAN'}
                    g = 1.82951 * 3600; % +/- 0.00034 h * sec/h
                case {'HO' 'CO' 'OC' 'OO' '15O'}
                    g = 122.2416;
                otherwise
                    error('mlswisstrace:ValueError', ...
                        'Catheter_DT20190930.halflife.tracer = %s', this.tracer)
            end            
        end
        function g = get.radialArteryKit(this)
            g = this.radialArteryLeeCache_;
        end
        function g = get.timeInterpolants(this)
            if isempty(this.timeInterpolants_)
                g = 0:this.dt:length(this.Measurement)-1;
                return
            end
            g = this.timeInterpolants_;
        end
        function set.timeInterpolants(this, s)
            this.timeInterpolants_ = s;
        end
        
        %%
        
        function this = call(this, varargin)
            %  Params:
            %      crv (file)
            %      crv_out (file = strcat(myfileprefix(crv), '_deconv.crv'))
            %      dt0 (datetime):  start of input function.
            %      dtf (datetime):  end of inputfunction.
            %      inveff (scalar):  counts/s to Bq/mL.
            %      units (text = 'Bq/mL'):  assumes counts/s in; returns 'Bq/mL' or 'uCi/mL'.
            %      Measurement (numeric):  counts/s.
            %      t0 (scalar {mustBeGreaterThan(t0,0)}):  transforms worldline into past.
            %      hct (scalar):  as percentage.
            %      tracer (text)

            ip = inputParser;
            addRequired(ip, 'crv', @isfile);
            addParameter(ip, 'hct', 45, @isscalar);
            addParameter(ip, 'tracer', '', @isttext);
            parse(ip, varargin{:});
            ipr = ip.Results;



            
            idx0 = 1030;
            idx_toss = 77;

            crv = mlswisstrace.CrvData(ipr.crv);
            disp(crv)

            M_ = crv.timetable().Coincidence(idx0:end-idx_toss)*inveff;
            cath = mlswisstrace.Catheter_DT20190930( ...
                'Measurement', M_, ...
                't0', 14.9, ...
                'hct', ipr.hct, ...
                'tracer', '18F'); % t0 reflects rigid extension + Luer valve + cath in Twilite cradle
            M = zeros(size(crv.timetable().Coincidence));
            M(idx0:end-idx_toss) = cath.deconvBayes();
            crv_deconv = crv;
            crv_deconv.filename = strcat(myfileprefix(ipr.crv), '_deconv.crv');
            crv_deconv.coincidence = M;
            crv_deconv.writecrv();
            disp(crv_deconv)





        end
        function [q,r] = deconv(this, varargin)
            k = this.kernel;
            M = smoothdata(this.Measurement, 'sgolay', this.sgolayWindow1);
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'Fourier', true, @islogical)
            addParameter(ip, 'N', 8192, @isnumeric)
            parse(ip, varargin{:})
            ipr = ip.Results;
            
            if ipr.Fourier
                q = ifft(fft(M, ipr.N) ./ fft(k, ipr.N));
                q = q(1:min(length(this.timeInterpolants), ipr.N));
                q = smoothdata(q, 'sgolay', this.sgolayWindow2);
                q(q < 0) = 0;
                r = [];
                return
            end            
            [q,r] = deconv(M, k);
            q = q(1:length(this.timeInterpolants));
            q(q < 0) = 0;

            %% REFACTOR?
            q = this.scalingWorldline*q;  
        end
        function q = deconvBayes(this, varargin)
            k = this.kernel(varargin{:}); % length(k) >= length(this.Measurement)

            % proposed
            ic = mlfourd.ImagingContext2(asrow(this.Measurement));
            ic.fqfilename = strcat(this.fqfileprefix, ".nii.gz");
            ic.addJsonMetadata(struct("timesMid", this.timeInterpolants));

            ral = mlaif.RadialArteryLee2024Model.create( ...
                artery=ic, ...
                kernel=k, ...
                model_kind=this.model_kind, ...
                tracer=this.tracer, ...
                scalingWorldline=this.scalingWorldline);
            ral.build_solution();

            % previously working
            % M = asrow(this.Measurement);
            % ral = mlswisstrace.RadialArteryLee2021( ...
            %     'tracer', this.tracer, ...
            %     'kernel', k, ...
            %     'model_kind', this.model_kind, ...
            %     'Measurement', M, ...
            %     varargin{:});
            % ral = ral.solve();
            % if ral.loss() > 0.1, clientname(true, 2)
            %     warning('mlswisstrace:ValueWarning', stackstr())
            %end

            this.radialArteryLeeCache_ = ral;
            %this.plot_deconv(varargin{:});

            %% REFACTOR?
            q = ral.deconvolved();      
        end
        function k = kernel(this, varargin)
            %% including regressions on catheter data of 2019 Sep 30
            %  @param Nt is the number of uniform time samples.
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            ip.PartialMatching = false;
            addParameter(ip, 'Nt', [], @isnumeric)
            parse(ip, varargin{:})
            ipr = ip.Results;
            if isempty(ipr.Nt)                
                t = this.timeInterpolants;
            else
                t = 0:ipr.Nt-1;
            end
            
            a =  0.0072507*this.hct - 0.13201;
            b =  0.0059645*this.hct + 0.69005;
            p = -0.0014628*this.hct + 0.58306;
            w =  0.00040413*this.hct + 1.2229;
            
            if (t(1) >= this.t0) % saves extra flops from slide()
                t_   = t - this.t0;
                k = t_.^a .* exp(-(b*t_).^p);
                k = abs(k);
            else
                t_   = t - t(1);
                k = t_.^a .* exp(-(b*t_).^p);
                k = mlswisstrace.Catheter_DT20190930.slide(abs(k), t, this.t0 - t(1));
            end
            
            k = k .* (1 + w*t); % better to apply slide, simplifying w
            sumk = sum(k);
            if sumk > eps
                k = k/sumk;
            end
        end
        function plot_deconv(this, varargin)
            h = this.radialArteryLeeCache_.plot(varargin{:});
            if ~isempty(this.fqfp) && ~isemptytext(this.fqfp)
                saveFigure2(h, this.fqfileprefix, closeFigure=this.do_close_fig)
            end
        end
        function h = plotall(this, varargin)
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'aifKnown', [], @isnumeric)
            parse(ip, varargin{:})
            ipr = ip.Results;
            
            figure
            t = this.timeInterpolants;
            M = this.Measurement;
            k = this.kernel;
            k = k*max(M)/max(k);
            q = this.deconvBayes();
            if ~isempty(ipr.aifKnown)
                h = plot(t, M, ':o', t, k, '-.', t, q(1:length(t)), ':o', t, ipr.aifKnown, '-');
                legend({'Measurements' 'kernel' 'deconv' 'aif known'});
            else
                h = plot(t, M, ':o', t, k, '-.', t, q(1:length(t)), ':o');
                legend({'Measurements' 'kernel' 'deconv'});
            end
            xlabel('t/s');
            ylabel('activity/ (Bq/mL)');
        end
        function f = scalingWorldline(this)
            f = 2^(this.t0/this.halflife); % catheter deconv doesn't know how to shift world-lines     
        end

 		function this = Catheter_DT20190930(varargin)
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'Measurement', [], @isnumeric)
            addParameter(ip, 'hct', 45, @isnumeric)
            addParameter(ip, 'tracer', [], @(x) ~isempty(x) && istext(x))
            addParameter(ip, 'model_kind', '3bolus', @istext)
            addParameter(ip, 'fqfileprefix', '', @istext)
            addParameter(ip, 'do_close_fig', false, @islogical)
            parse(ip, varargin{:})
            ipr = ip.Results;
            
            this.Measurement = ipr.Measurement;
            if iscell(ipr.hct)
                ipr.hct = ipr.hct{1};
            end
            if ischar(ipr.hct)
                ipr.hct = str2double(ipr.hct);
            end
            this.hct = ipr.hct;
            assert(this.hct > 1)
            this.tracer = convertStringsToChars(ipr.tracer);
            this.model_kind = convertStringsToChars(ipr.model_kind);
            this.fqfileprefix = ipr.fqfileprefix;
 		end
    end
    
    %% PROTECTED
    
    properties (Access = protected) 
        deconvCache_
        radialArteryLeeCache_
        timeInterpolants_
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
        function conc = slide(conc, t, Dt)
            %% SLIDE slides discretized function conc(t) to conc(t - Dt);
            %  Dt > 0 will slide conc(t) towards later times t.
            %  Dt < 0 will slide conc(t) towards earlier times t.
            %  It works for inhomogeneous t according to the ability of pchip to interpolate.
            %  It may not preserve information according to the Nyquist-Shannon theorem.  
            
            import mlswisstrace.Catheter_DT20190930;
            [conc,trans] = Catheter_DT20190930.ensureRow(conc);
            t            = Catheter_DT20190930.ensureRow(t);
            
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
        function idx = takeoff(vec, varargin)
            ip = inputParser;
            addParameter(ip, 'thresh', 2*vec(1), @isnumeric)
            parse(ip, varargin{:})
            
            for vi = 1:length(vec)
                if vec(vi) > ip.Results.thresh
                    idx = vi - 1;
                    return
                end
            end
            idx = length(vec);
        end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

