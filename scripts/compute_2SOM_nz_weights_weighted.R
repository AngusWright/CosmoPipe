#=========================================
#
# File Name : compute_2SOM_nz_weights.R
# Created By : awright
# Creation Date : 18-07-2025
# Last Modified : Wed Nov  5 16:54:35 2025
#
#=========================================



library(argparser)
library(doParallel)
library(foreach)

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
    help="Number of parallel threads"
)


#Get the arguments 
args<-parse_args(parser)
print(args)

if (args$spec.weight=='') args$spec.weight<-NULL
if (args$wide.weight=='') args$wide.weight<-NULL

cat("reading input data\n")
spec_data = helpRfuncs::read.file(args$spec,cols=c("groupID",args$spec.weight),ext=args$extname)
wide_data = helpRfuncs::read.file(args$wide,cols=c("groupID",args$wide.weight),ext=args$extname)
tfun = as.matrix(helpRfuncs::read.file(args$transfer))

#Compute the wide and spec cell occupation statistics 
if (is.null(args$spec.weight)) { 
  spec_ic<-as.numeric(table(factor(spec_data$groupID,levels=1:nrow(tfun))))
} else { 
  registerDoParallel(cores=args$nthread)
  spec_ic<-foreach(i=1:nrow(tfun),.combine=rbind,.inorder=TRUE)%dopar%{ 
    wt<-sum(spec_data[[args$spec.weight]][which(spec_data$groupID==i)],na.rm=T)
    return=wt
  }
}
if (is.null(args$wide.weight)) { 
  wide_ic<-as.numeric(table(factor(wide_data$groupID,levels=1:ncol(tfun))))
} else { 
  registerDoParallel(cores=args$nthread)
  wide_ic<-foreach(i=1:ncol(tfun),.combine=rbind,.inorder=TRUE)%dopar%{ 
    wt<-sum(wide_data[[args$wide.weight]][which(wide_data$groupID==i)],na.rm=T)
    return=wt
  }
}

if (length(dim(wide_ic))>1) { wide_ic<-as.numeric(wide_ic) } 

print(str(wide_ic))
print(str(tfun))
#Normalise the transfer function so columns (wide-cells) sum to the wide occupation 
tfun<-t(t(tfun)/colSums(tfun,na.rm=T)*wide_ic)
if (any(!is.finite(tfun))) { 
  warning("There are non-finite transfer function cells?! a wide cell must be empty?!") 
  tfun[which(!is.finite(tfun))]<-0
}
#Compute the per-deep-cell somweight 
somweight_mat<-rowSums(tfun)/spec_ic
if (any(!is.finite(somweight_mat))) { 
  warning("There are non-finite somweight matrix cells!") 
  somweight_mat[which(!is.finite(somweight_mat))]<-0
}
#Assign the SOM weights to the individual spectra 
spec_data$SOMweight<-somweight_mat[spec_data$groupID]
#set the non-finite weights to zero, with a warning! 
if (any(!is.finite(spec_data$SOMweight))) { 
  warning("There are non-finite SOM weights! Some deep cells must be empty!")
  spec_data$SOMweight[which(!is.finite(spec_data$SOMweight))]<-0
}

helpRfuncs::write.file(file=args$output,spec_data)


