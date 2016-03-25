using ArgParse
using HDF5
using EMIRT
using PyPlot

function parse_commandline()
    s = ArgParseSettings()

    @add_arg_table s begin
        "--tag"
        help = "curve type name"
        required = true
        arg_type = ASCIIString

        "--flbl"
        help = "label file name"
        required = true
        arg_type = ASCIIString

        "--faffs"
        help = "affinity file names, could be multiple files to compare"
        required = true
        arg_type = ASCIIString

        "--step"
        help = "error curve step"
        arg_type = Float64
        default = 0.1

        "--fcurve"
        help = "file to save the error curve"
        arg_type = ASCIIString
        default = "/tmp/error_curve.h5"

        "--seg_method"
        help = "segmentation method: connected_component; watershed"
        arg_type = ASCIIString
        default = "connected_component"

        "--is_patch"
        help = "use patch based segmentation error"
        arg_type = Bool
        default = false

        "--dim"
        help = "segmentation and evaluation dimention. 2/3"
        arg_type = Int64
        default = 2

        "--is_plot"
        help = "whether plot the curve or not"
        arg_type = Bool
        default = false
    end
    return parse_args(s)
end

function main()
    # read command line parameters
    faffs = ""
    flbl = ""
    tag = ""
    step = 0.1
    seg_method = ""
    dim = 2
    fcurve = ""
    is_plot = false
    is_patch = false
    for pa in parse_commandline()
        if pa[1] == "tag"
            tag = pa[2]
        elseif pa[1] == "flbl"
            flbl = pa[2]
        elseif pa[1] == "faffs"
            faffs = pa[2]
        elseif pa[1] == "step"
            step = pa[2]
        elseif pa[1] == "seg_method"
            seg_method = pa[2]
        elseif pa[1] == "dim"
            dim = pa[2]
        elseif pa[1] == "fcurve"
            fcurve = pa[2]
        elseif pa[1] == "is_plot"
            is_plot = pa[2]
        elseif pa[1] == "is_patch"
            is_patch = pa[2]
        end
    end

    @assert dim==2 || dim==3
    # read data
    # read affinity data
    affs = EMIRT.imread(faffs);
    # exchange X and Z channel
    # exchangeaffxz!(affs)

    # read label ground truth
    lbl = EMIRT.imread(flbl)
    lbl = Array{UInt32,3}(lbl)

    # rand error and rand f score curve, both are foreground restricted
    print("compute error curves of affinity map ......")
    thds, segs, rf, rfm, rfs, re, rem, res = affs_error_curve(affs, lbl, dim, step, seg_method, is_patch)
    print("done :)")

    # save the curve
    h5write(fcurve, "/$tag/segs", segs)
    h5write(fcurve, "/$tag/thds", thds)
    h5write(fcurve, "/$tag/rf",   rf )
    h5write(fcurve, "/$tag/rfm",  rfm )
    h5write(fcurve, "/$tag/rfs",  rfs )
    h5write(fcurve, "/$tag/re",   re )
    h5write(fcurve, "/$tag/rem",  rem )
    h5write(fcurve, "/$tag/res",  res )

    # plot
    if is_plot
        subplot(121)
        plot(thds, re)
        subplot(122)
        plot(thds, rf)
        show()
    end
end

main()
