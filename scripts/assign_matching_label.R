
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

colnames<-helpRfuncs::read.colnames(args$train)
lower.colnames<-tolower(colnames)
train.cols<-NULL
for (f in c(args$features,args$label)) { 
  train.cols<-c(train.cols,colnames[which(lower.colnames==tolower(f))])
}
if (length(train.cols)!=length(args$features)+1) stop("missing training columns")
colnames<-helpRfuncs::read.colnames(args$input)
lower.colnames<-tolower(colnames)
test.cols<-NULL
for (f in args$features) { 
  test.cols<-c(test.cols,colnames[which(lower.colnames==tolower(f))])
}
if (length(test.cols)!=length(args$features)) stop("missing training columns")

cat("reading input data\n")
train_data = helpRfuncs::read.file(args$train, cols=train.cols,verbose=T)
if (args$sparse>1) { 
  train_data = train_data[sample(nrow(train_data),size=nrow(train_data)/args$sparse),]
}
test_data = helpRfuncs::read.file(args$input,cols=c(test.cols),verbose=T)
for (i in 1:length(args$features)) { 
  train_data[[args$features[i]]]<-train_data[[train.cols[i]]]
  test_data[[args$features[i]]]<-test_data[[test.cols[i]]]
}
train_data[[args$label]]<-train_data[[train.cols[i+1]]]


cat("running matching\n")

#Whiten the data consistently (using test data as a base) 
test_white=kohonen::kohwhiten(test_data,train.expr=args$features,data.missing=NA,data.threshold=c(-Inf,Inf))
train_white=kohonen::kohwhiten(train_data,train.expr=args$features,data.missing=NA,data.threshold=c(-Inf,Inf),
                               whiten.param=test_white$whiten.param)

#Check for missing values in the test and training data 
means<-rowMeans(test_white$data.white)
if (any(is.na(means))) { 
  stop("There are NA/NaN entries in the test data! These are not allowed in the match.\n")
}
means<-rowMeans(train_white$data.white)
if (any(is.na(means))) { 
  #There are NA/NaNs in the train data
  stop("There are NA/NaN entries in the train data! These are not allowed in the match.\n")
}

idx = RANN::nn2(query=test_white$data.white, 
                data=train_white$data.white, k=ifelse(!args$duplicates,args$nodup_nmatch,1))

cat(paste0("There are ",length(which(idx$nn.idx[,1]!=0))," matches (out of ",nrow(test_data),")"))
if (!args$duplicates) { 
  #Use the best match, keeping only the best-est match for duplicates 
  prediction=rep(NA,nrow(test_data))
  pred_id=seq_len(nrow(test_data))
  used=rep(FALSE,nrow(train_data))
  # Preserve legacy invalidation by predicted label, not matched training row.
  # Assignment also preserves the original coercion of factor/logical labels.
  label_index=rep(NA,nrow(train_data))
  label_index[]=train_data[[args$label]]
  label_index=match(label_index,seq_len(nrow(train_data)),nomatch=0L)
  for (run_id in 1:ncol(idx$nn.idx)) { 
    if (length(pred_id)==0) break
    # Invalidate only the current candidates, without rewriting the N x k matrices.
    idx_start = idx$nn.idx[pred_id,run_id]
    unavailable=used[idx_start]
    idx_start[unavailable]=NA_integer_
    keep=rep(TRUE,length(pred_id))
    if (anyDuplicated(idx_start)) {
      #order by separation 
      separation=idx$nn.dists[pred_id,run_id]
      separation[unavailable]=Inf
      sep_order = order(separation)
      #Identify duplicated ids, keeping best match for each duplicated source 
      dups = sep_order[which(duplicated(idx_start[sep_order]))]
      keep[dups]=FALSE
    }
    matched=idx_start[keep]
    prediction[pred_id[keep]]=train_data[[args$label]][matched]
    used[label_index[matched[!is.na(matched)]]]=TRUE
    pred_id=pred_id[is.na(prediction[pred_id])]
  }
} else { 
  #Use the best match, regardless of duplication 
  prediction = train_data[[args$label]][idx$nn.idx[,1]]
}

cat("Training:\n")
if (length(which(!duplicated(train_data[[args$label]])))>10) { 
  print(summary(train_data[[args$label]]))
} else { 
  print(table(train_data[[args$label]])) 
}

cat("Prediction:\n")
if (length(which(!duplicated(prediction)))>10) { 
  print(summary(prediction))
} else { 
  print(table(prediction)) 
}

cat("writing output data\n")
test_data[[args$label]] = prediction
helpRfuncs::write.file(test_data,file=args$output)
