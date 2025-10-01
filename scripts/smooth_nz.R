#=========================================
#
# File Name : smooth_nz.R
# Created By : awright
# Creation Date : 07-09-2025
# Last Modified : Sun Sep  7 20:44:05 2025
#
#=========================================

#Loop through the command arguments /*fold*/ {{{
inputs<-commandArgs(TRUE)
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
    input.catalogue<-inputs[1]
    inputs<-inputs[-1]
    #/*fold*/}}}
  } else if (inputs[1]=='--stdev') {
    #Define the smoothing standard deviation /*fold*/ {{{
    inputs<-inputs[-1]
    stdev<-as.numeric(inputs[1])
    inputs<-inputs[-1]
    #/*fend*/}}}
  } else {
    stop(paste("Unknown option",inputs[1]))
  }
}
#}}}

#Read the input catalogue 
nz<-helpRfuncs::read.file(input.catalogue)

#Get the number of pixels to smooth 
sd.pix<-stdev/diff(nz[[1]][1:2])
#Make sure the smoothing number is odd 
sd.pix<-ceiling(sd.pix/2)*2+1

#Pad the Nz with zeros 
density_pad<-c(rep(0,2*sd.pix),nz[[2]],rep(0,2*sd.pix))

#Perform hanning smoothing 
nz[[2]]<-helpRfuncs::hanning.smooth(density_pad,degree=sd.pix)[2*sd.pix+1:length(nz[[2]])]

#Output the weights 
helpRfuncs::write.file(file=input.catalogue,nz)

