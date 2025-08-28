
library(argparser)

parser = arg_parser(
    description="Assign SOM cells to sources in a catalogue given an input SOM."
)
parser<-add_argument(parser,
    short="-i", "--input", 
    help="path to the target file",
)
parser<-add_argument(parser,
    short="-o", "--output",
    help="path to the output with added label",
)
parser<-add_argument(parser,
    short="-s", "--som", 
    help="path to the pre-trained SOM",
)
parser<-add_argument(parser,
    "--features",short="-f", nargs="+",
    help="column names of features to match, must be present in input and training data",
)
parser<-add_argument(parser,
    "--extname", default='OBJECTS', 
    help="open catalogue using this extension name"
)
parser<-add_argument(parser,
    "--data.threshold", default=c(-Inf,Inf), 
    help="Limits for valid data values"
)
parser<-add_argument(parser,
    "--data.missing", default=-99, 
    help="missing data value"
)
parser<-add_argument(parser,
    "--som.cores", default=-1, 
    help="number of cores to use"
)

parser<-add_argument(parser,
    "--n.cluster.bins", default=Inf, 
    help="number of discrete SOM groupings to use"
)

#Get the arguments 
args<-parse_args(parser)
print(args)
#Split features by space and comma 
args$features=helpRfuncs::vecsplit(args$features,",")
args$features=helpRfuncs::vecsplit(args$features," ")
keys<-unique((helpRfuncs::vecsplit(gsub('[-+*\\/\\)\\(]'," ",args$features),' ')))


cat("reading input data\n")
test_data = helpRfuncs::read.file(args$input,cols=keys,ext=args$extname)
som = helpRfuncs::read.file(args$som)

cat("running SOM cell assignment\n")
#Get the data positions from the trained SOM /*fold*/ {{{
som<-kohonen::kohparse(som=som,data=test_data,
                       train.expr=args$features,
                       data.missing=args$data.missing,
                       data.threshold=args$data.threshold,
                       n.cores=args$som.cores,
                       max.na.frac=1,quiet=TRUE)
if (is.finite(as.numeric(args$n.cluster.bins))) { 
  som<-kohonen::generate.kohgroups(som=som,data=test_data,
                                   train.expr=args$features,
                                   data.missing=args$data.missing,
                                   data.threshold=args$data.threshold,
                                   n.cores=args$som.cores,
                                   n.cluster.bins=args$n.cluster.bins,
                                   max.na.frac=1,quiet=TRUE)
} else { 
  som$clust.classif<-som$unit.classif
} 

cat("writing output data\n")
helpRfuncs::write.file(data.frame(SeqNr=test_data$SeqNr,FIELD_POS=test_data$FIELD_POS,
                                  cellID=som$unit.classif,groupID=som$clust.classif),
                       file=args$output)

