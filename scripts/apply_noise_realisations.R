#=========================================
#
# File Name : apply_noise_realisations.R
# Created By : awright
# Creation Date : 17-07-2025
# Last Modified : Sat Jul 19 12:06:17 2025
#
#=========================================


library(argparser)
library(extrafont)

#Create the argument parser 
p <- arg_parser("Construct gaussian noise ralisations for input flux columns and stdev")
# Add a positional argument
p <- add_argument(p, "--input", help="input catalogues")
# Add a positional argument
p <- add_argument(p, "--infilt", help="input filter columns",narg="+")
# Add a positional argument
p <- add_argument(p, "--outfilt", help="output filter columns",narg="+")
# Add a positional argument
p <- add_argument(p, "--nrealisation", help="Number of realisations to construct",default=1)
# Add a positional argument
p <- add_argument(p, "--stdev", help="standard deviations",narg="+")
# Add a positional argument
p <- add_argument(p, "--outbase", help="root path/name for the output catalogue")
# Add a positional argument
p <- add_argument(p, "--outext", help="extension for the output catalogue") 
# Add a flag
p <- add_argument(p, "--quiet", help="run quietly",flag=TRUE)
## Add a flag
#p <- add_argument(p, "--append", help="append to file", flag=TRUE)

#Read the arguments 
args<-parse_args(p)

#Read the input catalogue 
input_colnames<-helpRfuncs::read.colnames(args$input)

#Get the input column names 
infilt<-NULL
for (col in helpRfuncs::vecsplit(args$infilt,by=',')) { 
  tmp<-which(grepl(col,input_colnames))[1]
  if (is.na(tmp)) stop(paste0("No matching column found for input filter",col))
  infilt<-c(infilt,input_colnames[tmp])
}
#define output filter names 
outfilt<-helpRfuncs::vecsplit(args$outfilt,by=',')

#define the stdev values 
stdev<-as.numeric(helpRfuncs::vecsplit(args$stdev,by=','))

#Read the input catalogue
input<-helpRfuncs::read.file(args$input,cols=infilt,verbose=!args$quiet)
inp_flux<-input[,..infilt]

print(infilt)

if (!args$quiet) cat(paste("Generating realisations\n"))
realisations<-input
nloop<-args$nrealisation*length(infilt)
pb<-txtProgressBar(style=2,min=0,max=nloop)
count<-0
for (i in 1:args$nrealisation) { 
  #Generate the noise realisations 
  for (band in 1:length(infilt)) { 
    timer<-proc.time()
    count<-count+1
    #Gaussian noise to flux 
    realisations[[outfilt[band]]]<-input[[infilt[band]]]+rnorm(nrow(input),mean=0,sd=stdev[band])
    setTxtProgressBar(pb,count)
    cat(paste0(" (",round(proc.time()[3]-timer[3],digits=2),"sec for loop ",count,"/",nloop,")"))
    print(c(infilt[band],outfilt[band]))
  }
  print(str(realisations))
  #Output the realisation
  helpRfuncs::write.file(file=paste0(args$outbase,"_r",i,".",args$outext),realisations)
}
