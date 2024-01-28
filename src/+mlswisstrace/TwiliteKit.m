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
            if ~isempty(this.device_)
                dev = this.device_;
                return
            end

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

            if ~isempty(this.input_func_ic_)
                ic = this.input_func_ic_;
                return
            end

            med = this.bids_kit_.make_bids_med();
            idx0 = this.device_.index0;
            idxF = this.device_.indexF;
            ifc = copy(med.imagingFormat);
            ifc.img = measurement;
            ifc.fqfp = this.device_.new_fqfp();
            ifc.fileprefix = mlpipeline.Bids.adjust_fileprefix( ...
                ifc.fileprefix, post_proc=this.model_kind);
            ifc.filesuffix = ".nii.gz";
            ifc.json_metadata.Manufacturer = "Swisstrace";
            ifc.json_metadata.ManufacturersModelName = "Twilite II";
            ifc.json_metadata.ImageComments = stackstr();
            ifc.json_metadata.taus = this.device_.taus(idx0:idxF);
            ifc.json_metadata.times = this.device_.times(idx0:idxF) - this.device_.times(idx0);
            ifc.json_metadata.timesMid = this.device_.timesMid(idx0:idxF) - this.device_.timesMid(idx0);
            ifc.json_metadata.timeUnit = "second";
            ifc.json_metadata.datetime0 = this.device_.datetime0;
            ifc.json_metadata.baselineActivityDensity = this.device_.baselineActivityDensity;
            ifc.json_metadata.(stackstr()).invEfficiency = this.device_.invEfficiency;
            ic = mlfourd.ImagingContext2(ifc);
            %ic.addJsonMetadata(opts);
            this.input_func_ic_ = ic;
        end
    end

    methods (Static)
        function this = instance(varargin)
            this = mlswisstrace.TwiliteKit();
            this.install_input_func(varargin{:})
            this.do_make_device();

            % persistent uniqueInstance
            % if isempty(uniqueInstance)
            %     this = mlswisstrace.TwiliteKit();
            %     this.install_input_func(varargin{:})
            %     this.do_make_device();
            %     uniqueInstance = this;
            % else
            %     this = uniqueInstance;
            %     this.install_input_func(varargin{:})
            %     this.do_make_device();
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
            % sameWorldline prevent shifting worldline of input func. to reference time series
            
            arguments
                this mlswisstrace.TwiliteKit
                opts.sameWorldline logical = false 
                opts.indexCliff double = []
                opts.fqfileprefix {mustBeTextScalar} = ""
                opts.do_close_fig logical = false
                opts.referenceDev = this.referenceDev_
                opts.hct = this.hct_
                opts.model_kind = this.model_kind_
            end
            med = this.bids_kit_.make_bids_med();
            if isemptytext(opts.fqfileprefix)
                pth = med.imagingContext.filepath;
                fp = mlpipeline.Bids.adjust_fileprefix(med.imagingContext.fileprefix, ...                
                    new_proc=stackstr(use_dashes=true), new_mode="dev");
                opts.fqfileprefix = fullfile(pth, fp);
            end
            
            input_func_dev = mlswisstrace.TwiliteDevice.createFromSession(med);
            input_func_dev.fqfileprefix = opts.fqfileprefix; % hard to manage with TwiliteDevice() inputParser
            input_func_dev.do_close_fig = opts.do_close_fig; % hard to manage with TwiliteDevice() inputParser
            input_func_dev.deconvCatheter = ~contains(opts.model_kind, "nomodel");
            input_func_dev.hct = opts.hct;
            input_func_dev.model_kind = opts.model_kind;
            if input_func_dev.deconvCatheter
                input_func_dev = input_func_dev.alignArterialToReference( ...
                    arterialDev=input_func_dev, ...
                    referenceDev=opts.referenceDev, ...
                    sameWorldline=opts.sameWorldline);
            else
                input_func_dev = input_func_dev.setArterialTimingToReference( ...
                    arterialDev=input_func_dev, ...
                    referenceDev=opts.referenceDev);
            end
            %input_func_dev.save();

            if ~isempty(opts.referenceDev) && ...
                    opts.referenceDev.timeWindow > input_func_dev.timeWindow && ...
                    contains(med.isotope, '15O')
                warning('mlsiemens:ValueWarning', ...
                    'scannerDev.timeWindow->%g; arterialDev.timeWindow->%g', ...
                    opts.referenceDev.timeWindow, input_func_dev.timeWindow)
                %this.inspectTwiliteCliff(arterialDev, scannerDev, ipr.indexCliff);
            end
        end
        function this = TwiliteKit()
        end
    end
    
    %  Created with mlsystem.Newcl, inspired by Frank Gonzalez-Morphy's newfcn.
end
