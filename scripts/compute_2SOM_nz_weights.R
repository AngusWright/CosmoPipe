#=========================================
#
# File Name : compute_2SOM_nz_weights.R
# Created By : awright
# Creation Date : 18-07-2025
# Last Modified : Sun Jul 20 19:12:05 2025
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
    short="-w", "--wide", 
    help="path to the wide file",
)
parser<-add_argument(parser,
    "--extname", default='OBJECTS', 
    help="open catalogue using this extension name"
)

#Get the arguments 
args<-parse_args(parser)
print(args)

cat("reading input data\n")
spec_data = helpRfuncs::read.file(args$spec,cols="groupID",ext=args$extname)
wide_data = helpRfuncs::read.file(args$wide,cols="groupID",ext=args$extname)
tfun = as.matrix(helpRfuncs::read.file(args$transfer))

#Compute the wide and spec cell occupation statistics 
wide_ic<-as.numeric(table(factor(wide_data$groupID,levels=1:ncol(tfun))))
spec_ic<-as.numeric(table(factor(spec_data$groupID,levels=1:nrow(tfun))))

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


