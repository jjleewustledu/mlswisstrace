classdef Catheter_DT20190930 
	%% CATHETER_DT20190930  

	%  $Revision$
 	%  was created 09-Feb-2020 13:51:38 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlswisstrace/src/+mlswisstrace.
 	%% It was developed on Matlab 9.7.0.1296695 (R2019b) Update 4 for MACI64.  Copyright 2020 John Joowon Lee.
 	
	properties
        hct
        Measurement
        t0 = 9.8671 % mean from data of 2019 Sep 30
 		timeInterpolants
 	end

	methods 
        function [q,r] = deconv(this, varargin)
            k = this.kernel;
            M = smoothdata(this.Measurement, 'sgolay', 12);
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'Fourier', true, @islogical)
            addParameter(ip, 'N', 4096, @isnumeric)
            parse(ip, varargin{:})
            ipr = ip.Results;
            
            if ipr.Fourier
                q = ifft(fft(M, ipr.N) ./ fft(k, ipr.N));
                r = [];
                return
            end            
            [q,r] = deconv(M, k);
        end
        function k = kernel(this)
            %% including regressions on catheter data of 2019 Sep 30
            
            a =  0.0072507*this.hct - 0.13201;
            b =  0.0059645*this.hct + 0.69005;
            p = -0.0014628*this.hct + 0.58306;
            t =  this.timeInterpolants;
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
            
            k = k .* (1 + w*this.timeInterpolants);            
            sumk = sum(k);
            if sumk > eps
                k = k/sumk;
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
            q = this.deconv(varargin{:});
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
		  
 		function this = Catheter_DT20190930(varargin)
 			%% CATHETER_DT20190930
 			%  @param .

 			
 		end
    end     
    
    %% PROTECTED
    
    properties (Access = protected)
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

