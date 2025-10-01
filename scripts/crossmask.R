#=========================================
#
# File Name : spatial_split.R
# Created By : awright
# Creation Date : 10-07-2023
# Last Modified : Mon Sep 29 14:15:17 2025
#
#=========================================

#Create a mask variable from multiple catalogues 


#Read input parameters 
inputs<-commandArgs(TRUE) 

#Interpret the command line options {{{
badval<- -999
mask_only<-FALSE
mask_and<-FALSE
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
    if (any(grepl('^-',inputs[-1]))) {
      key.ids<-1:(which(grepl('^-',inputs[-1]))[1])
    } else {
      key.ids<-1:length(inputs)
    }
    input.cats<-inputs[key.ids[c(-1)]]
    inputs<-inputs[-(key.ids)]
    #/*fold*/}}}
  } else if (inputs[1]=='-b') { 
    #Read the base catalogue /*fold*/ {{{
    inputs<-inputs[-1]
    base.cat<-inputs[1]
    inputs<-inputs[-1]
    #/*fold*/}}}
  } else if (inputs[1]=='-o') { 
    #Read the output catalogue(s) /*fold*/ {{{
    inputs<-inputs[-1]
    output.cat<-inputs[1]
    inputs<-inputs[-1]
    #/*fold*/}}}
  } else if (inputs[1]=='-c') { 
    #Read the mask condition /*fold*/ {{{
    inputs<-inputs[-1]
    condition<-inputs[1]
    inputs<-inputs[-1]
    #/*fold*/}}}
  } else if (inputs[1]=='--mask_only') { 
    #Return mask only /*fold*/ {{{
    inputs<-inputs[-1]
    mask_only<-TRUE
    #/*fold*/}}}
  } else if (inputs[1]=='--mask_AND') { 
    #Return mask only /*fold*/ {{{
    inputs<-inputs[-1]
    mask_and<-TRUE
    #/*fold*/}}}
  } else {
    stop(paste("Unknown option",inputs[1]))
  }
}
#}}}

#Read the input catalogue {{{
if (!mask_only) { 
  cat("Reading base catalogue") 
  base<-helpRfuncs::read.file(base.cat)
} 
#}}}

#Define the necessary columns {{{ 
keys<-gsub('<'," ",condition)
keys<-gsub('>'," ",keys)
keys<-gsub('='," ",keys)
keys<-unique((helpRfuncs::vecsplit(gsub('[-+*\\/\\)\\(]'," ",keys),' ')))
keys<-keys[which(is.na(as.numeric(keys)))]
keys<-keys[keys!=""]
#}}}

#Initialise the mask: TRUE if AND, FALSE is OR {{{
fullmask <- mask_and
#}}}

for (input.cat in input.cats) { 
  cat(paste("on catalogue:",input.cat,'\n'))
  cat<-helpRfuncs::read.file(input.cat,cols=keys,ldacsafe=FALSE)
  cat(paste("length:",nrow(cat),'\n'))

  #Evaluate the mask criteria {{{
  val<-with(cat,eval(parse(text=condition)))
  if (class(val)[1]=='try-error') { 
    stop(paste("ERROR: the y-axis variable is not in the catalogue, and is not a valid expression?!",ylabel))
  }
  cat(paste("val length:",length(val),'\n'))
  #}}}

  #Add this to the full mask {{{
  if (length(fullmask) > 1) { 
    if (length(fullmask) != length(val)) { stop("catalogue does not have equal length to the mask vector!!") } 
  }
  if (!mask_and) { 
    fullmask = fullmask | val
  } else { 
    fullmask = fullmask & val
  }
  cat(paste("masks stat:",length(which(fullmask)),"/",length(fullmask),'\n'))
  #}}}
}

#For each split, output the catalogue {{{
if (mask_only) { 
  out<-cat
  out$crossmask<-ifelse(fullmask,0,1)
  helpRfuncs::write.file(file=output.cat,out)
} else { 
  #Write the file {{{
  base$crossmask<-ifelse(fullmask,0,1)
  helpRfuncs::write.file(file=output.cat,base)
}
#}}}

#Finish

