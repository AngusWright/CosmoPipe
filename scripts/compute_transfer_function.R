
library(argparser)

parser = arg_parser(
    description="Compute the transfer function between two SOMs given common sources."
)
parser<-add_argument(parser,
    short="-d", "--deep", 
    help="path to the deep file",
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
parser<-add_argument(parser,
    "--wide_dim", default=c(21,21), 
    help="dimensions of the wide SOM"
)
parser<-add_argument(parser,
    "--deep_dim", default=c(75,150), 
    help="dimensions of the deep SOM"
)
parser<-add_argument(parser,
    "--ncluster", default=c(Inf),
    help="number of SOM clusters"
)

#Get the arguments 
args<-parse_args(parser)
print(args)

wide_length<-prod(args$wide_dim)
deep_length<-prod(args$deep_dim)

if (is.finite(as.numeric(args$ncluster))) { 
  if (args$ncluster<wide_length) wide_length<-args$ncluster
  if (args$ncluster<deep_length) deep_length<-args$ncluster
}

cat("reading input data\n")
deep_data = helpRfuncs::read.file(args$deep,cols="groupID",ext=args$extname)
wide_data = helpRfuncs::read.file(args$wide,cols="groupID",ext=args$extname)

#Check for errors {{{
if (any(wide_data$groupID>wide_length)) stop("wide index is outside provided dimension")
if (any(deep_data$groupID>deep_length)) stop("deep index is outside provided dimension")
if (nrow(wide_data)!=nrow(deep_data)) stop("wide and deep indices have different lengths?!") 
#}}}

cat("Generating transfer function\n")
#Define the index count function {{{
ind_count<-function(x,y,xmax,ymax) {
  vals<-paste(x,y,sep=',') 
  all<-expand.grid(1:xmax,1:ymax)
  all<-paste(all[,1],all[,2],sep=',')
  tab<-table(factor(paste(x,y,sep=','),levels=all))
  return=data.frame(x=as.numeric(helpRfuncs::vecsplit(names(tab),by=',',n=1)),
                    y=as.numeric(helpRfuncs::vecsplit(names(tab),by=',',n=2)),
                    n=as.numeric(tab))
}
#}}}

#initialise transfer function {{{
tfun<-matrix(NA,nrow=deep_length,ncol=wide_length)
#}}}

#Deep-to-wide counts {{{
deep_ic<-ind_count(deep_data$groupID,wide_data$groupID,
                   xmax=deep_length, ymax=wide_length)
#}}}

#Wide counts {{{
wide_ic<-table(factor(wide_data$groupID,levels=1:wide_length))
#}}}

#Check for errors {{{
if (any(!is.finite(deep_ic$x) | !is.finite(deep_ic$y))) { 
  stop("non-finite values of x/y in deep_ic")
}
#}}}

#Transfer function matrix {{{
tfun[cbind(deep_ic$x,deep_ic$y)]<-deep_ic$n
#}}}

cat("writing output data\n") 
helpRfuncs::write.file(tfun,file=args$output)

