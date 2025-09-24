#=========================================
#
# File Name : combine_gt_patches.R
# Created By : dvornik
# Creation Date : 17-07-2024
# Last Modified : Wed Jul 17 11:31:17 2024
#
#=========================================

#Get the input files 
inputs<-commandArgs(TRUE) 

#Interpret the command line options 
while (length(inputs)!=0) {
  while (length(inputs)!=0 && inputs[1]=='') { inputs<-inputs[-1] }  
  if (!grepl('^-',inputs[1])) {
    print(inputs)
    stop(paste("Incorrect options provided!"))
  }
  #/*fend*/}}}
  if (inputs[1]=='-i') { 
    #Read the input catalogue(s) /*fold*/ {{{
    inputs<-inputs[-1]
    if (any(grepl('^-',inputs))) { 
      input.cats<-inputs[1:(which(grepl('^-',inputs))[1]-1)]
      inputs<-inputs[-(1:(which(grepl('^-',inputs))[1]-1))]
    } else { 
      input.cats<-inputs
      inputs<-NULL
    } 
    #/*fold*/}}}
  } else if (inputs[1]=='-o') { 
    # Define the output file name {{{
    inputs<-inputs[-1]
    outputfile<-inputs[1]
    inputs<-inputs[-1]
    #/*fend*/}}}
  } else {
    stop(paste("Unknown option",inputs[1]))
  }
}

colnames<-c('r_nom','meanr','meanlogr','gamT','gamX','sigma','weight', 'nocor_gamT', 'nocor_gamX','rangamT','rangamX','ransigma','npairs_weighted')

for (i in 1:length(input.cats)) { 
  #Read the file 
  tmp<-helpRfuncs::read.file(input.cats[i],data.table=FALSE)
  #Add new values
  tmp$var <- tmp$sigma^2
  tmp$ranvar <- tmp$ransigma^2
  tmp$npairs_sq <- tmp$npairs_weighted^2
  
  #if we have the first file, use this as a template 
  if (i==1) { 
    inter_cols<-c('r_nom','meanr','meanlogr','gamT','gamX','sigma','weight', 'nocor_gamT', 'nocor_gamX','rangamT','rangamX','ransigma','var', 'ranvar', 'npairs_sq','npairs_weighted')
    #Set up the catalogue, but fill everything with zeros
    out<-tmp[,inter_cols]*0
  } 
  print(summary(out))
  #Otherwise, combine the values
  #Weighted sum of values (weight = npairs_weighted)
  out$r_nom      = (out$r_nom    + tmp$r_nom    * tmp$npairs_weighted)
  out$meanr      = (out$meanr    + tmp$meanr    * tmp$npairs_weighted)
  out$meanlogr   = (out$meanlogr + tmp$meanlogr * tmp$npairs_weighted)
  out$gamT       = (out$gamT     + tmp$gamT     * tmp$npairs_weighted)
  out$gamX       = (out$gamX     + tmp$gamX     * tmp$npairs_weighted)
  out$nocor_gamT = (out$nocor_gamT + tmp$nocor_gamT * tmp$npairs_weighted)
  out$nocor_gamX = (out$nocor_gamX + tmp$nocor_gamX * tmp$npairs_weighted)
  out$rangamT    = (out$rangamT  + tmp$rangamT  * tmp$npairs_weighted)
  out$rangamX    = (out$rangamX  + tmp$rangamX  * tmp$npairs_weighted)
  out$sigma      = (out$var    + tmp$var)
  out$ransigma   = (out$ranvar + tmp$ranvar)
  out$weight     = out$weight + tmp$weight
  out$npairs_weighted = out$npairs_weighted + tmp$npairs_weighted
}
print(summary(out))
#Construct the output columns 
out$r_nom     = out$r_nom/out$npairs_weighted
out$meanr     = out$meanr/out$npairs_weighted
out$meanlogr  = out$meanlogr/out$npairs_weighted
out$gamT       = out$gamT/out$npairs_weighted
out$gamX       = out$gamX/out$npairs_weighted
out$nocor_gamT = out$nocor_gamT/out$npairs_weighted
out$nocor_gamX = out$nocor_gamX/out$npairs_weighted
out$rangamT    = out$rangamT/out$npairs_weighted
out$rangamX    = out$rangamX/out$npairs_weighted
out$sigma = sqrt(out$var)
out$ransigma = sqrt(out$ranvar)
out$npairs = sqrt(out$npairs_sq)
#Remove the intermediate columns and sort into the original order 
out<-data.table::as.data.table(out)
out<-out[,.SD,.SDcols=colnames]
print(summary(out))

#Output the file 
helpRfuncs::write.file(outputfile,out)
