#=========================================
#
# File Name : ldaccalc.R 
# Created By : awright
# Creation Date : 09-04-2026
# Last Modified : Sun Apr 26 19:50:56 2026
#
#=========================================


library(argparser)
library(extrafont)

#Create the argument parser 
p <- arg_parser("Construct a new column from an input expression")
# Add a positional argument
p <- add_argument(p, "--input", help="input catalogue")
# Add a positional argument
p <- add_argument(p, "--output", help="output catalogue")
# Add a positional argument
p <- add_argument(p, "--name", help="calculation column name") 
# Add a positional argument
p <- add_argument(p, "--cond", help="calculation condition") 
# Add a flag
p <- add_argument(p, "--quiet", help="run quietly",flag=TRUE)
## Add a flag
#p <- add_argument(p, "--append", help="append to file", flag=TRUE)

#Read the arguments 
args<-parse_args(p)

#Read the input catalogue 
input_colnames<-helpRfuncs::read.colnames(args$input)

#Get required column names {{{
#seperated.labels<-unique(helpRfuncs::vecsplit(helpRfuncs::vecsplit(gsub('[-+*\\/\\)\\(]'," ",gsub(';$','',args$cond)),' '),','))
seperated.labels<-unique(helpRfuncs::vecsplit(helpRfuncs::vecsplit(gsub('[-><=+*/)(]'," ",gsub(';$','',args$cond)),' '),','))
seperated.labels<-seperated.labels[which(seperated.labels!="")]
if (any(sapply(seperated.labels,function(C) class(try(silent=T,eval(parse(text=C)))))=='function')) { 
  func.ind<-which(sapply(seperated.labels,function(C) class(try(silent=T,eval(parse(text=C)))))=='function')
  seperated.labels<-seperated.labels[-func.ind]
}
seperated.labels<-seperated.labels[which(seperated.labels%in%input_colnames)]
cat("Reading columns:\n")
print(seperated.labels)

#Read the input catalogue
input<-helpRfuncs::read.file(args$input,cols=seperated.labels,verbose=TRUE)
#input<-helpRfuncs::read.file(args$input,verbose=TRUE)

#Compute the new column 
input[[args$name]]<-with(input,eval(parse(text=args$cond)))

print(str(input))

#output file 
helpRfuncs::write.file(file=args$output,input)
