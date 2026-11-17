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

args<-parse_args(parser)
print(args)

for (dimension in list(args$wide_dim,args$deep_dim)) {
  if (any(!is.finite(dimension) | dimension<1 | dimension!=floor(dimension))) {
    stop("SOM dimensions must be finite positive integers")
  }
}
ncluster<-as.numeric(args$ncluster)
if (length(ncluster)!=1L || is.na(ncluster) || ncluster<1 ||
    (is.finite(ncluster) && ncluster!=floor(ncluster))) {
  stop("number of SOM clusters must be a positive integer or Inf")
}

wide_length<-min(prod(args$wide_dim),ncluster)
deep_length<-min(prod(args$deep_dim),ncluster)
nbins<-as.double(deep_length)*as.double(wide_length)
if (!is.finite(nbins) || nbins>.Machine$integer.max) {
  stop("transfer function exceeds the supported number of matrix cells")
}

cat("reading input data\n")
deep_data = helpRfuncs::read.file(args$deep,cols="groupID",ext=args$extname)
wide_data = helpRfuncs::read.file(args$wide,cols="groupID",ext=args$extname)

if (nrow(wide_data)!=nrow(deep_data)) stop("wide and deep indices have different lengths?!")
for (sample in c("wide","deep")) {
  indices<-if (sample=="wide") wide_data$groupID else deep_data$groupID
  limit<-if (sample=="wide") wide_length else deep_length
  if (is.null(indices) || !is.numeric(indices) ||
      any(!is.finite(indices) | indices<1 | indices!=floor(indices))) {
    stop(paste(sample,"indices must be finite positive integers"))
  }
  if (any(indices>limit)) stop(paste(sample,"index is outside provided dimension"))
}

cat("Generating transfer function\n")
# R stores matrices column-first: each wide cell occupies deep_length bins.
bin<-as.double(deep_data$groupID)+as.double(deep_length)*(as.double(wide_data$groupID)-1)
tfun<-matrix(as.numeric(tabulate(bin,nbins=nbins)),nrow=deep_length,ncol=wide_length)

cat("writing output data\n")
helpRfuncs::write.file(tfun,file=args$output)
