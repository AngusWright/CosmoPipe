#=========================================
#
# File Name : spatial_split.R
# Created By : awright
# Creation Date : 10-07-2023
# Last Modified : Mon Aug 25 11:41:49 2025
#
#=========================================

#Split a catalogue into N equalN sections

#Read input parameters 
inputs<-commandArgs(TRUE) 

#Interpret the command line options {{{
badval<- -999
ID_only<-FALSE
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
    if (any(grepl('^-',inputs))) { 
      output.cats<-inputs[1:(which(grepl('^-',inputs))[1]-1)]
      inputs<-inputs[-(1:(which(grepl('^-',inputs))[1]-1))]
    } else { 
      output.cats<-inputs
      inputs<-NULL
    } 
    #/*fold*/}}}
  } else if (inputs[1]=='-n') { 
    #Read the number of splits /*fold*/ {{{
    inputs<-inputs[-1]
    nsplit<-as.integer(inputs[1])
    if (!is.finite(nsplit)) { 
      stop(paste("Provided number of splits is not a finite integer:",inputs[1]))
    }
    inputs<-inputs[-1]
    #/*fold*/}}}
  } else if (inputs[1]=='-v') { 
    #Read the spatial column names /*fold*/ {{{
    inputs<-inputs[-1]
    x.name<-inputs[1]
    inputs<-inputs[-1]
    #/*fold*/}}}
  } else if (inputs[1]=='--id_only') { 
    #Return ids only /*fold*/ {{{
    inputs<-inputs[-1]
    ID_only<-TRUE
    #/*fold*/}}}
  } else {
    stop(paste("Unknown option",inputs[1]))
  }
}
#}}}

#Check that length of the output files is correct {{{
if (!ID_only) { 
  if (length(output.cats)!=nsplit) { 
    stop("Output file list must be of length nsplit") 
  } 
}
#}}}

#Read the input catalogue for col names {{{
cols<-helpRfuncs::read.colnames(input.cat)
#}}}

#Check that the x.name varaible is in the catalogue 
if (!x.name %in% cols) {  
  stop(paste(x.name,"variable is not in provided catalogue!")) 
}

#Read the input catalogue {{{
if (ID_only) { 
  cat<-helpRfuncs::read.file(input.cat,cols=x.name)
} else { 
  cat<-helpRfuncs::read.file(input.cat)
} 
#}}}

#Set up the cut object (for faster splitting) {{{
tmp<-data.frame(x=cat[[x.name]])
#}}}

#X range {{{
if (any(tmp$x==badval)) { 
  cat("WARNING: Catalogue has x-values which are bad!\n")
  x.range<-range(tmp$x[which(tmp$x!=badval)],na.rm=T)
} else { 
  x.range<-range(tmp$x,na.rm=T)
} 
#}}}

cat(paste0("x.range: ",'[',x.range[1],',',x.range[2],']\n'))

#Create bins {{{
if (nsplit==1) { 
  #There is only one bin?! {{{
  cat('Only one bin!\n')
  bins<-rep(1,nrow(tmp))
  #}}}
} else {
  #Bin in x & y {{{
  if (any(tmp$x==badval)) { 
    cat('binning in x (with good values only)!\nEntries with bad x values are randomly assigned to a bin!')
    bins<-rep(NA,nrow(tmp)) 
    good<-tmp$x!=badval
    bins[good]<-with(tmp[good,],tapply(1:length(x),list(x=cut(x, breaks=quantile(x,probs=seq(0,1,length=nsplit+1)), include.lowest=T))))
    bins[!good]<-sample(1:nsplit,size=length(which(!good)),replace=T)
  } else { 
    cat('binning in x\n')
    bins<-with(tmp,tapply(1:nrow(tmp),list(x=cut(x, breaks=quantile(x,probs=seq(0,1,length=nsplit+1)), include.lowest=T))))
  } 
  #}}}
}
#}}}

cat('bin occupation:\n')
print(table(bins))

#For each split, output the catalogue {{{
if (ID_only) { 
  out<-cat
  out$splitvar<-bins
  helpRfuncs::write.file(file=output.cats[1],out)
} else { 
  written<-FALSE
  for (i in seq(1,nsplit)) { 
    #Select the relevant sources {{{
    out<-cat[which(bins==i),]
    #}}}
    cat(paste('bin',i,x.name,'stats:\n'))
    print(summary(out[[x.name]]))
  
    if (nrow(out)==0) { 
      cat(paste("WARNING: split",i,"contains no sources?!\n"))
    } else { 
      #Write the file {{{
      helpRfuncs::write.file(file=output.cats[i],out)
      #}}}
      written<-TRUE
    }
  } 
  if (!written) { 
    stop("Nothing was written to disk?!") 
  }
}
#}}}

#Finish

