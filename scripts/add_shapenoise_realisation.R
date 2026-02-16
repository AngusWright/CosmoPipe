#=========================================
#
# File Name : correct_2D_cterm.R
# Created By : awright
# Creation Date : 10-07-2023
# Last Modified : Wed Feb 11 19:01:28 2026
#
#=========================================

#Read input parameters 
inputs<-commandArgs(TRUE) 

de=0.01
nbins<-2/de
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
    #Read the output catalogue(s) /*fold*/ {{{
    inputs<-inputs[-1]
    output<-inputs[1]
    inputs<-inputs[-1]
    #/*fold*/}}}
  } else if (inputs[1]=='-e') { 
    #Read the spatial column names /*fold*/ {{{
    inputs<-inputs[-1]
    e1.name<-inputs[1]
    e2.name<-inputs[2]
    inputs<-inputs[-1:-2]
    #/*fold*/}}}
  } else if (inputs[1]=='-n') { 
    #Read the noise-basis column names /*fold*/ {{{
    inputs<-inputs[-1]
    e1.basis.name<-inputs[1]
    e2.basis.name<-inputs[2]
    inputs<-inputs[-1:-2]
    #/*fold*/}}}
  } else if (inputs[1]=='--id') { 
    #Read the id column names /*fold*/ {{{
    inputs<-inputs[-1]
    id.name<-inputs[1]
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

#Check that the e1.basis.name varaible is in the catalogue 
if (!e1.basis.name %in% cols) {  
  stop(paste(e1.basis.name,"variable is not in provided catalogue!")) 
}
#Check that the e2.basis.name varaible is in the catalogue 
if (!e2.basis.name %in% cols) {  
  stop(paste(e2.basis.name,"variable is not in provided catalogue!")) 
}
#Check that the e1.name varaible is in the catalogue 
if (!e1.name %in% cols) {  
  stop(paste(e1.name,"variable is not in provided catalogue!")) 
}
#Check that the e2.name varaible is in the catalogue 
if (!e2.name %in% cols) {  
  stop(paste(e2.name,"variable is not in provided catalogue!")) 
}
#Check that the id.name varaible is in the catalogue 
if (!id.name %in% cols) {  
  stop(paste(id.name,"variable is not in provided catalogue!")) 
}

cat<-helpRfuncs::read.file(input.cat,cols=c(e1.basis.name,e2.basis.name,e1.name,e2.name,id.name))

#Get the unique ids, using factors
ids<-factor(cat[[id.name]])

#Set up the cut object (for faster splitting) {{{
tmp<-data.frame(x=cat[[e1.basis.name]],y=cat[[e2.basis.name]])
#}}}

#Compute noise realisation terms {{{
cat('computing bins\n')
x.bin<-seq(-1,1,length=nbins+1)
y.bin<-seq(-1,1,length=nbins+1)
cat('computing counts\n')
count<-with(tmp,tapply(x,list(x=cut(x, breaks=x.bin, include.lowest=T),
                              y=cut(y, breaks=y.bin, include.lowest=T)),length))
count[which(is.na(count))]<-0
cat('computing e1\n')
e1mean<-with(tmp,tapply(x,list(x=cut(x, breaks=x.bin, include.lowest=T),
                               y=cut(y, breaks=y.bin, include.lowest=T)),mean))
cat('computing e2\n')
e2mean<-with(tmp,tapply(y,list(x=cut(x, breaks=x.bin, include.lowest=T),
                               y=cut(y, breaks=y.bin, include.lowest=T)),mean))
cat('sampling e12\n')
#Sample e12 from the 2D distribution, following the data PDF, and duplicating a single realisation per ID
#There is 1 value per unique id 
e12_index<-sample(length(count),size=length(levels(ids)),prob=count,replace=T)
e1samp<-e1mean[e12_index]+runif(nrow(tmp),min=-de/2,max=de/2)
e2samp<-e2mean[e12_index]+runif(nrow(tmp),min=-de/2,max=de/2)
#}}}

#Add noise terms {{{
cat[[e1.name]]<-cat[[e1.name]]+e1samp[as.numeric(ids)]
cat[[e2.name]]<-cat[[e2.name]]+e2samp[as.numeric(ids)]
cat<-cat[,c(e1.name,e2.name),with=F]
#}}}

#Write the file {{{
helpRfuncs::write.file(file=output,cat)
#}}}
#Finish

