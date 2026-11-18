#=========================================
#
# File Name : compute_2SOM_nz_weights.R
# Created By : awright
# Creation Date : 18-07-2025
# Last Modified : Tue Nov 17 20:25:18 2026
#
#=========================================



library(argparser)

parser = arg_parser(
    description="Compute the SOM Nz weights from the transfer function, spec, and wide catalogues."
)
parser<-add_argument(parser,
    short="-s", "--spec", 
    help="path to the spec file",
)
parser<-add_argument(parser,
    short="-t", "--transfer", 
    help="path to the transfer function file",
)
parser<-add_argument(parser,
    short="-o", "--output",
    help="path to the output with added label",
)
parser<-add_argument(parser,
    "--wide.output", default="",
    help="optional output catalogue with unsupported wide weights set to zero",
)
parser<-add_argument(parser,
    short="-ww", "--wide.weight", 
    help="wide field sample weight column",default=NULL,
)
parser<-add_argument(parser,
    short="-sw", "--spec.weight", 
    help="spec sample weight column",default=NULL,
)
parser<-add_argument(parser,
    short="-w", "--wide", 
    help="path to the wide file",
)
parser<-add_argument(parser,
    "--extname", default='OBJECTS', 
    help="open catalogue using this extension name"
)
parser<-add_argument(parser,
    "--nthread", default=128,
    help="Retained for CLI compatibility; cell totals now use single-pass grouped sums"
)


#Get the arguments 
# argparser otherwise splits the legacy multi-character short options.
argv<-commandArgs(trailingOnly=TRUE)
argv[argv=="-sw"]<-"--spec.weight"
argv[argv=="-ww"]<-"--wide.weight"
args<-parse_args(parser,argv=argv)
print(args)

for (name in c("spec","wide","transfer","output")) {
  if (is.na(args[[name]]) || !nzchar(args[[name]])) stop(paste(name,"is required"))
}
optional_column<-function(name) {
  if (is.null(name) || is.na(name) || name=="") return(NULL)
  name
}
args$spec.weight<-optional_column(args$spec.weight)
args$wide.weight<-optional_column(args$wide.weight)
if (!is.finite(args$nthread) || args$nthread<1 || args$nthread!=floor(args$nthread)) {
  stop("nthread must be a positive integer")
}
write_wide<-nzchar(args$wide.output)
input_paths<-normalizePath(c(args$spec,args$wide,args$transfer),mustWork=FALSE)
output_paths<-normalizePath(c(args$output,if (write_wide) args$wide.output),mustWork=FALSE)
if (any(output_paths %in% input_paths) || anyDuplicated(output_paths)) {
  stop("output paths must differ from each other and from all input paths")
}

cat("reading input data\n")
resolve_weight<-function(file,name,sample) {
  cols<-helpRfuncs::read.colnames(file,extname=args$extname)
  if (!"groupID" %in% cols) stop(paste("There is no 'groupID' column in the",sample,"catalogue"))
  if (is.null(name) || name %in% cols) return(name)
  matches<-which(tolower(cols)==tolower(name))
  if (length(matches)!=1L) {
    stop(paste("There is no column",name,"in the",sample,
               "catalogue, and no unique case-insensitive match."))
  }
  cols[matches]
}
args$spec.weight<-resolve_weight(args$spec,args$spec.weight,"spec")
args$wide.weight<-resolve_weight(args$wide,args$wide.weight,"wide")
read_catalogue<-function(file,...) {
  if (grepl("\\.(fits|cat)$",file,ignore.case=TRUE)) {
    helpRfuncs::read.file(file,extname=args$extname,...)
  } else {
    helpRfuncs::read.file(file,...)
  }
}
spec_data = read_catalogue(args$spec,cols=c("groupID",args$spec.weight))
if (write_wide) {
  wide_data = read_catalogue(args$wide)
} else {
  wide_data = read_catalogue(args$wide,cols=c("groupID",args$wide.weight))
}
tfun = as.matrix(helpRfuncs::read.file(args$transfer))

if (!is.numeric(tfun) || any(dim(tfun)<1) || any(!is.finite(tfun) | tfun<0)) {
  stop("transfer function must be a non-empty matrix of finite non-negative counts")
}
validate_cells<-function(ids,ncell,sample) {
  if (!is.numeric(ids) || any(!is.finite(ids) | ids<1 | ids>ncell | ids!=floor(ids))) {
    stop(paste(sample,"groupID values must be integer cell indices within the transfer dimensions"))
  }
}
validate_cells(spec_data$groupID,nrow(tfun),"spec")
validate_cells(wide_data$groupID,ncol(tfun),"wide")
cell_totals<-function(data,column,ncell,sample) {
  ids<-data$groupID
  if (is.null(column)) return(tabulate(ids,nbins=ncell))
  weights<-data[[column]]
  if (!is.numeric(weights) || any(is.infinite(weights) | weights<0,na.rm=TRUE)) {
    stop(paste(sample,"weights must be non-negative and finite (or missing)"))
  }
  if (anyNA(weights)) {
    warning(paste("Missing",sample,"weights contribute zero to cell totals"))
    weights[is.na(weights)]<-0
  }
  totals<-numeric(ncell)
  if (length(ids)) {
    grouped<-rowsum(as.numeric(weights),ids,reorder=FALSE)
    totals[as.integer(rownames(grouped))]<-grouped[,1]
  }
  if (any(!is.finite(totals))) stop("cell weight totals overflowed")
  totals
}
spec_ic<-cell_totals(spec_data,args$spec.weight,nrow(tfun),"spec")
wide_ic<-cell_totals(wide_data,args$wide.weight,ncol(tfun),"wide")

# A wide cell is usable only if a positive transfer links it to usable spectra.
supported<-as.vector(crossprod(as.numeric(spec_ic>0),tfun))>0
wide_mask<-supported[wide_data$groupID]
wide_ic[!supported]<-0
transfer_totals<-colSums(tfun)
if (any(!is.finite(transfer_totals))) stop("transfer column totals overflowed")
scale<-numeric(ncol(tfun))
nonempty<-transfer_totals>0 & supported
scale[nonempty]<-wide_ic[nonempty]/transfer_totals[nonempty]
somweight_mat<-numeric(nrow(tfun))
represented<-spec_ic>0
# Apply column normalisation 
deep_totals<-as.vector(tfun %*% scale)
somweight_mat[represented]<-deep_totals[represented]/spec_ic[represented]
if (any(!is.finite(somweight_mat))) stop("SOM weight computation overflowed")
spec_data$SOMweight<-somweight_mat[spec_data$groupID]

if (write_wide) {
  if (is.null(args$wide.weight)) {
    wide_data$SOMweight<-as.numeric(wide_mask)
  } else {
    wide_data[[args$wide.weight]][!wide_mask]<-0
  }
  cat("Zeroing weights for",sum(!wide_mask),"wide sources in",
      sum(!supported),"wide cells without usable spec information\n")
}
write_catalogue<-function(data,file) {
  if (grepl("\\.(fits|cat)$",file,ignore.case=TRUE)) {
    helpRfuncs::write.file(file=file,data,extname=args$extname)
  } else {
    helpRfuncs::write.file(file=file,data)
  }
}
write_catalogue(spec_data,args$output)
if (write_wide) write_catalogue(wide_data,args$wide.output)
