#=========================================
#
# File Name : compute_nz.R
# Created By : awright
# Creation Date : 22-03-2023
# Last Modified : Sat Sep 13 10:59:32 2025
#
#=========================================

#Loop through the command arguments /*fold*/ {{{
inputs<-commandArgs(TRUE)
original.weight<-NULL
while (length(inputs)!=0) {
  #Check the options syntax /*fold*/ {{{
  while (length(inputs)!=0 && inputs[1]=='') { inputs<-inputs[-1] }
  if (!grepl('^-',inputs[1])) {
    print(inputs)
    stop(paste("Incorrect options provided!",
               "Check the lengths for each option!\n",
               "Only -i and -k parameters can have more than 1 item"))
  }
  #/*fend*/}}}
  if (inputs[1]=='-i') {
    #Read the input reference catalogue(s) /*fold*/ {{{
    inputs<-inputs[-1]
    input.file<-inputs[1]
    inputs<-inputs[-1]
    #/*fold*/}}}
  } else if (inputs[1]=='-o') {
    #Read the output filename /*fold*/ {{{
    inputs<-inputs[-1]
    output<-inputs[1]
    inputs<-inputs[-1]
    #/*fold*/}}}
  } else if (inputs[1]=='--somweightname') {
    #Define the pre-existing weight column /*fold*/ {{{
    inputs<-inputs[-1]
    som.weight<-inputs[1]
    if (som.weight=='') som.weight<-NULL
    inputs<-inputs[-1]
    #/*fend*/}}}
  } else if (inputs[1]=='--origweightname') {
    #Define the pre-existing weight column /*fold*/ {{{
    inputs<-inputs[-1]
    original.weight<-inputs[1]
    inputs<-inputs[-1]
    #Remove spaces and change to NULL if empty 
    original.weight<-gsub(" ", "", original.weight)
    if (original.weight=="") { original.weight<-NULL } 
    #/*fend*/}}}
  } else if (inputs[1]=='--zname') {
    #Define the redshift column /*fold*/ {{{
    inputs<-inputs[-1]
    z.label<-inputs[1]
    inputs<-inputs[-1]
    #/*fend*/}}}
  } else if (inputs[1]=='--zstep') {
    #Define the step size in z space /*fold*/ {{{
    inputs<-inputs[-1]
    binstep<-as.numeric(inputs[1])
    inputs<-inputs[-1]
    #/*fend*/}}}
  } else {
    stop(paste("Unknown option",inputs[1]))
  }
}
#}}}

#Read the input catalogue 
cat<-helpRfuncs::read.file(input.file,cols=c(z.label,original.weight,som.weight))

#Construct the Nz {{{
if (!is.null(original.weight) & !is.null(som.weight)) { 
  nzdist<-plotrix::weighted.hist(cat[[z.label]],w=cat[[som.weight]]*cat[[original.weight]]/sum(cat[[som.weight]]*cat[[original.weight]]),
                                breaks=seq(0,6.001,by=binstep),plot=F)
} else if (!is.null(original.weight) & is.null(som.weight)) { 
  nzdist<-plotrix::weighted.hist(cat[[z.label]],w=cat[[original.weight]]/sum(cat[[original.weight]]),
                                breaks=seq(0,6.001,by=binstep),plot=F)
} else if (is.null(original.weight) & !is.null(som.weight)) { 
  nzdist<-plotrix::weighted.hist(cat[[z.label]],w=cat[[som.weight]]/sum(cat[[som.weight]]),
                                breaks=seq(0,6.001,by=binstep),plot=F)
} else { 
  nzdist<-plotrix::weighted.hist(cat[[z.label]],
                                breaks=seq(0,6.001,by=binstep),plot=F)
}
#/*fend*/}}}

#Output the Nz #/*fold*/{{{
helpRfuncs::write.file(file=output,data.frame(binstart=nzdist$breaks[1:length(nzdist$mids)],
                                    density=nzdist$density),quote=F,row.names=F,col.names=F)
#/*fend*/}}}

