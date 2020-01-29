classdef CatheterModel 
	%% CATHETERMODEL  

	%  $Revision$
 	%  was created 27-Jan-2020 19:08:52 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlswisstrace/src/+mlswisstrace.
 	%% It was developed on Matlab 9.7.0.1261785 (R2019b) Update 3 for MACI64.  Copyright 2020 John Joowon Lee.
 	
	properties
 		
 	end

	methods (Static)
        function k = gammaDistribution(a, b, t0, t)
            if (t(1) >= t0)
                t_   = t - t0;
                k = t_.^a .* exp(-b*t_);
                k = abs(k);
            else 
                t_   = t - t(1);
                k = t_.^a .* exp(-b*t_);
                k = mlswisstrace.CatheterModel.slide(abs(k), t, t0 - t(1));
            end
            k = k*b^(a+1)/gamma(a+1);
        end
        function k = gammaDistributionP(a, b, t0, w, t)
            k = mlswisstrace.CatheterModel.gammaDistribution(a,b,t0,t) .* (1 + w*t);
            k = k/sum(k);
        end
        function k = generalizedGammaDistribution(a, b, p, t0, t)
            if (t(1) >= t0) % saves extra flops from slide()
                t_   = t - t0;
                k = t_.^a .* exp(-(b*t_).^p);
            else
                t_   = t - t(1);
                k = t_.^a .* exp(-(b*t_).^p);
                k = mlswisstrace.CatheterModel.slide(abs(k), t, t0 - t(1));
            end
            k = abs(k*p*b^(a+1)/gamma((a+1)/p));
        end
        function k = generalizedGammaDistributionP(a, b, p, t0, w, t)
            k = mlswisstrace.CatheterModel.generalizedGammaDistribution(a,b,p,t0,t) .* (1 + w*t);
            k = k/sum(k);
        end
        function k = tanhDistributionP(a, t0, v, w, t)
            t_ = t - t0;
            k  = 0.5*(tanh(a*t_) + 1);
            k  = k .* (1 + v*t + sign(w)*w^2*t.^2);
            k  = k/sum(k);
            k(k < 0) = 0;
        end
    end
    
    methods      
        function k = kernel(this, params, t)
            import mlswisstrace.CatheterModel
            
            switch this.modelName_
                case 'GammaDistribution'
                    k = CatheterModel.gammaDistribution( ...
                        params(3), params(4), params(5), t);
                case 'GammaDistributionP'
                    k = CatheterModel.gammaDistributionP( ...
                        params(3), params(4), params(5), params(6), t);
                case 'GeneralizedGammaDistribution'
                    k = CatheterModel.generalizedGammaDistribution( ...
                        params(3), params(4), params(5), params(6), t);
                case 'GeneralizedGammaDistributionP'
                    k = CatheterModel.generalizedGammaDistributionP( ...
                        params(3), params(4), params(5), params(6), params(7), t);
                case 'TanhDistributionP'
                    k = CatheterModel.tanhDistributionP( ...
                        params(3), params(4), params(5), params(6), t);
                otherwise
                    error('mlswisstrace:NotImplementedError', 'CatheterModel.kernel.modelName_->%s', this.modelName_)
            end            
        end
        function loss = simulanneal_objective(this, params, box, t, q, sigma0)   
            qs = this.synthesis(params, box, t);
            loss = 0.5 * sum((1 - qs ./ q).^2) / sigma0^2 + sum(log(q)); % sigma ~ sigma0 * qs0
        end
        function qs = synthesis(this, params, box, t)            
            qs = params(2)*conv(this.kernel(params, t), box) + params(1);
            qs = qs(1:length(t));
            qs(qs < 0) = 0;
        end
        
 		function this = CatheterModel(varargin)
 			%% CATHETERMODEL
 			%  @param modelName \in \{ 'GeneralizedGammaDistribution' 'GeneralizedGammaDistributionP' ...
            %                                     'GammaDistribution'            'GammaDistributionP' \}
            %  @param hct is percent

            ip = inputParser;
            addParameter(ip, 'modelName', 'GeneralizedGammaDistribution', @ischar)
            addParameter(ip, 'hct', 45)
            parse(ip, varargin{:})
            ipr = ip.Results;
            
            this.modelName_ = ipr.modelName;
 		end
    end 
    
    % PRIVATE
    
    properties (Access = private)
        modelName_
    end
    
    methods (Static, Access = private)  
        function [vec,T] = ensureRow(vec)
            if (~isrow(vec))
                vec = vec';
                T = true;
                return
            end
            T = false; 
        end      
        function conc    = slide(conc, t, Dt)
            %% SLIDE slides discretized function conc(t) to conc(t - Dt);
            %  Dt > 0 will slide conc(t) towards later times t.
            %  Dt < 0 will slide conc(t) towards earlier times t.
            %  It works for inhomogeneous t according to the ability of pchip to interpolate.
            %  It may not preserve information according to the Nyquist-Shannon theorem.  
            
            import mlswisstrace.CatheterModel;
            [conc,trans] = CatheterModel.ensureRow(conc);
            t            = CatheterModel.ensureRow(t);
            
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
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

