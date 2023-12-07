classdef (Sealed) TwiliteKit < handle & mlkinetics.InputFuncKit
    %% line1
    %  line2
    %  
    %  Created 09-Jun-2022 14:17:52 by jjlee in repository /Users/jjlee/MATLAB-Drive/mlswisstrace/src/+mlswisstrace.
    %  Developed on Matlab 9.12.0.1956245 (R2022a) Update 2 for MACI64.  Copyright 2022 John J. Lee.
    
    properties (Dependent)
        decayCorrected % false for 15O
    end    

    methods %% GET
        function g = get.decayCorrected(this)
            if isempty(this.device_)
                do_make_device(this);
            end
            g = this.device_.decayCorrected;
        end
    end

    methods
        function ic = do_make_activity(this, varargin)
            if isempty(this.device_)
                do_make_device(this);
            end
            a = this.device_.activity(varargin{:});
            ic = this.do_make_input_func(a);
        end
        function ic = do_make_activity_density(this, varargin)
            if isempty(this.device_)
                do_make_device(this);
            end
            a = this.device_.activityDensity(varargin{:});
            ic = this.do_make_input_func(a);
        end
        function dev = do_make_device(this, varargin)
            this.device_ = this.buildArterialSamplingDevice(varargin{:});
            %fqfp = sprintf("%s_%s", this.bids_kit_.make_bids_med.imagingContext.fqfp, stackstr());
            %saveFigure2(gcf, fqfp, closeFigure=false);
            dev = this.device_;
        end
        function ic = do_make_input_func(this, measurement)
            arguments
                this mlswisstrace.TwiliteKit
                measurement {mustBeNumeric,mustBeNonempty}
            end

            %% allow for revisions to device|data, such as decay-correction
            %if ~isempty(this.input_func_ic_)
            %    ic = this.input_func_ic_;
            %    return
            %end

            if isempty(this.device_)
                do_make_device(this);
            end
            med = this.bids_kit_.make_bids_med();
            idx0 = this.device_.index0;
            idxF = this.device_.indexF;
            ifc = copy(med.imagingFormat);
            ifc.img = measurement;
            ifc.fileprefix = sprintf("%s_%s", ifc.fileprefix, stackstr(3));
            ifc.json_metadata.taus = this.device_.taus(idx0:idxF);
            ifc.json_metadata.times = this.device_.times(idx0:idxF) - this.device_.times(idx0);
            ifc.json_metadata.timesMid = this.device_.timesMid(idx0:idxF) - this.device_.timesMid(idx0);
            ifc.json_metadata.timeUnit = "second";
            this.input_func_ic_ = mlfourd.ImagingContext2(ifc);
            ic = this.input_func_ic_;
        end
    end

    methods (Static)
        function this = instance(varargin)
            this = mlswisstrace.TwiliteKit();
            this.install_input_func(varargin{:})
            % persistent uniqueInstance
            % if isempty(uniqueInstance)
            %     this = mlswisstrace.TwiliteKit();
            %     this.install_input_func(varargin{:})
            %     uniqueInstance = this;
            % else
            %     this = uniqueInstance;
            %     this.install_input_func(varargin{:})
            % end
        end
    end 

    %% PROTECTED

    methods (Access = protected)
        function install_input_func(this, varargin)
            install_input_func@mlkinetics.InputFuncKit(this, varargin{:});
        end
    end

    %% PRIVATE

    methods (Access = private)
        function input_func_dev = buildArterialSamplingDevice(this, opts)
            arguments
                this mlswisstrace.TwiliteKit
                opts.deconvCatheter logical = true
                opts.sameWorldline logical = false
                opts.indexCliff double = []
                opts.fqfileprefix {mustBeTextScalar} = ""
                opts.do_close_fig logical = false;
            end
            med = this.bids_kit_.make_bids_med();
            scanner_dev = this.scanner_kit_.do_make_device();
            if isemptytext(opts.fqfileprefix)
                opts.fqfileprefix = sprintf("%s_%s", med.imagingContext.fqfileprefix, stackstr(3));
            end
            
            input_func_dev = mlswisstrace.TwiliteDevice.createFromSession(med);
            input_func_dev.fqfileprefix = opts.fqfileprefix; % hard to manage with TwiliteDevice() inputParser
            input_func_dev.do_close_fig = opts.do_close_fig; % hard to manage with TwiliteDevice() inputParser
            input_func_dev.deconvCatheter = opts.deconvCatheter;
            input_func_dev = this.scanner_kit_.alignArterialToScanner( ...
                input_func_dev, scanner_dev, 'sameWorldline', opts.sameWorldline);
            input_func_dev.radialArteryKit.saveas( ...
                sprintf("%s_%s_radialArteryKit.mat", med.imagingContext.fqfp, stackstr(3)));

            if scanner_dev.timeWindow > input_func_dev.timeWindow && ...
                    contains(med.isotope, '15O')
                warning('mlsiemens:ValueWarning', ...
                    'scannerDev.timeWindow->%g; arterialDev.timeWindow->%g', ...
                    scanner_dev.timeWindow, input_func_dev.timeWindow)
                %this.inspectTwiliteCliff(arterialDev, scannerDev, ipr.indexCliff);
            end
        end
        function this = TwiliteKit()
        end
    end
    
    %  Created with mlsystem.Newcl, inspired by Frank Gonzalez-Morphy's newfcn.
end
