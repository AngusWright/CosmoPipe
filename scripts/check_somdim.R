#=========================================
#
# File Name : spatial_split.R
# Created By : awright
# Creation Date : 10-07-2023
# Last Modified : Tue Jul 29 17:47:23 2025
#
#=========================================

#Split a catalogue into N equalN sections

#Read input parameters 
inputs<-commandArgs(TRUE) 

#Interpret the command line options {{{
while (length(inputs)!=0) {
  #Check for valid specification {{{
  while (length(inputs)!=0 && inputs[1]=='') { inputs<-inputs[-1] }  
  if (!grepl('^-',inputs[1])) {
    print(inputs)
    stop(paste("Incorrect options provided!"))
  }
  #/*fend*/}}}
  if (inputs[1]=='-i') { 
    #Read the input catalogue /*fold*/ {{{
    inputs<-inputs[-1]
    input.cat<-inputs[1]
    inputs<-inputs[-1]
    #/*fold*/}}}
  } else if (inputs[1]=='-o') { 
    #Read the output catalogue /*fold*/ {{{
    inputs<-inputs[-1]
    output.cat<-inputs[1]
    inputs<-inputs[-1]
    #/*fold*/}}}
  } else if (inputs[1]=='-d') { 
    #Read the SOM dimensions /*fold*/ {{{
    inputs<-inputs[-1]
    som.dim<-c(as.integer(inputs[1]),as.integer(inputs[2]))
    if (any(is.na(som.dim))) { stop("Invalid SOM dimension passed to script!") } 
    inputs<-inputs[-1]
    inputs<-inputs[-1]
    #/*fold*/}}}
  } else {
    stop(paste("Unknown option",inputs[1]))
  }
}
#}}}

#Read the input catalogue for col names {{{
cols<-helpRfuncs::read.colnames(input.cat)
#}}}

#Read the input catalogue {{{
cat<-helpRfuncs::read.file(input.cat,cols=cols[1])
#}}}

#Require at least 2.5 sources per cell 
if (nrow(cat) < prod(som.dim)*2.5) {
  som.dim<-rep(round(sqrt(nrow(cat)/2.5)),2)
}

#Write the limits to file 
helpRfuncs::write.file(file=output.cat[1],rbind(som.dim))
#}}}

#Finish

