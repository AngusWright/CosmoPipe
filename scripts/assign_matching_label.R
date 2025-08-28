
library(argparser)

parser = arg_parser(
    description="Assign label from training catalogue to target catalogue using nearest-neighbour match in feature space."
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
    short="-t", "--train", 
    help="path to the training data containing the desired label",
)
parser<-add_argument(parser,
    "--features",short="-f", nargs="+",
    help="column names of features to match, must be present in input and training data",
)
parser<-add_argument(parser,
    "--label",short="-l", 
    help="column name of the label to match",
)
parser<-add_argument(parser,
    "--duplicates", flag=TRUE,
    help="allow duplicated matches"
)
parser<-add_argument(parser,
    "--nodup_nmatch", default=100, 
    help="Number of nearest neighbours to use if not allowing duplicates"
)
parser<-add_argument(parser,
    "--sparse", default=1, 
    help="sparse-sample the training data by taking every n-th data point"
)
parser<-add_argument(parser,
    "--extname", default='OBJECTS', 
    help="open catalogue using this extension name"
)

#Get the arguments 
args<-parse_args(parser)
#Split features by space and comma 
args$features=helpRfuncs::vecsplit(args$features,",")
args$features=helpRfuncs::vecsplit(args$features," ")


cat("reading input data\n")
train_data = helpRfuncs::read.file(args$train, cols=c(args$features, args$label))
if (args$sparse>1) { 
  train_data = train_data[sample(nrow(train_data),size=nrow(train_data)/args$sparse),]
}
test_data = helpRfuncs::read.file(args$input,cols=c(args$features))

cat("running matching\n")

#Whiten the data consistently (using test data as a base) 
test_white=kohonen::kohwhiten(test_data,train.expr=args$features,data.missing=NA,data.threshold=c(-Inf,Inf))
train_white=kohonen::kohwhiten(train_data,train.expr=args$features,data.missing=NA,data.threshold=c(-Inf,Inf),
                               whiten.param=test_white$whiten.param)

idx = RANN::nn2(query=test_white$data.white, 
                data=train_white$data.white, k=ifelse(args$duplicates,args$nodup_nmatch,1))

cat(paste0("There are ",length(which(idx$nn.idx[,1]!=0))," matches (out of ",nrow(test_data),")"))
if (!args$duplicates) { 
  #Use the best match, keeping only the best-est match for duplicates 
  prediction=rep(NA,nrow(test_data))
  for (run_id in 1:ncol(idx$nn.idx)) { 
    #For everything not yet predicted: 
    pred_id = which(is.na(prediction))
    if (length(pred_id)==0) break
    #Best matches 
    idx_start = idx$nn.idx[pred_id,run_id]
    if (any(duplicated(idx_start))) { 
      #order by separation 
      sep_order = order(idx$nn.dists[pred_id,run_id])
      #Identify duplicated ids, keeping best match for each duplicated source 
      dups = sep_order[which(duplicated(idx_start[sep_order]))]
      #Keep the non-duplicated entries 
      prediction[pred_id][-dups] = train_data[[args$label]][idx_start][-dups]
    } else { 
      prediction[pred_id] = train_data[[args$label]][idx_start]
    }
    idx$nn.dists[which(idx$nn.idx%in%prediction)]<-Inf
    idx$nn.idx[which(idx$nn.idx%in%prediction)]<-NA
  }
} else { 
  #Use the best match, regardless of duplication 
  prediction = train_data[[args$label]][idx$nn.idx[,1]]
}

cat("writing output data\n")
test_data[[args$label]] = prediction
helpRfuncs::write.file(test_data,file=args$output)

