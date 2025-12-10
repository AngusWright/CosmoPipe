#=========================================
#
# File Name : add_prior_weights.R
# Created By : awright
# Creation Date : 18-10-2023
# Last Modified : Tue Nov 11 22:49:51 2025
#
#=========================================

cat("Starting!\nReading options\n")

#Loop through the command arguments /*fold*/ {{{
bw=0.01
mag.label<-original.weight<-""
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
  } else if (inputs[1]=='--weightname') {
    #Define the pre-existing weight column /*fold*/ {{{
    inputs<-inputs[-1]
    original.weight<-inputs[1]
    inputs<-inputs[-1]
    #/*fend*/}}}
  } else if (inputs[1]=='--filter') {
    #Define the redshift column /*fold*/ {{{
    inputs<-inputs[-1]
    filter<-inputs[1]
    inputs<-inputs[-1]
    #/*fend*/}}}
  } else if (inputs[1]=='--zname') {
    #Define the redshift column /*fold*/ {{{
    inputs<-inputs[-1]
    z.label<-inputs[1]
    inputs<-inputs[-1]
    #/*fend*/}}}
  } else if (inputs[1]=='--magcut') {
    #Define the magnitude range to cut the data on /*fold*/ {{{
    inputs<-inputs[-1]
    magcut_lo<-as.numeric(inputs[1])
    inputs<-inputs[-1]
    if (!grepl("-",inputs[1])) { 
      magcut_hi<-as.numeric(inputs[1])
      inputs<-inputs[-1]
    } else { 
      magcut_hi<-magcut_lo
      magcut_lo<-0 
    } 
    #/*fend*/}}}
  } else if (inputs[1]=='--maglim') {
    #Define the analytic magnitude limits /*fold*/ {{{
    inputs<-inputs[-1]
    maglim_lo<-as.numeric(inputs[1])
    inputs<-inputs[-1]
    if (!grepl("-",inputs[1])) { 
      maglim_hi<-as.numeric(inputs[1])
      inputs<-inputs[-1]
    } else { 
      maglim_hi<-maglim_lo
      maglim_lo<-0 
    } 
    #/*fend*/}}}
  } else if (inputs[1]=='--magname') {
    #Define the analytic magnitude limits /*fold*/ {{{
    inputs<-inputs[-1]
    mag.label<-inputs[1]
    inputs<-inputs[-1]
    #/*fend*/}}}
  } else {
    stop(paste("Unknown option",inputs[1]))
  }
}
#}}}

cat("Reading data\n")

#Read the input catalogue 
cat<-helpRfuncs::read.file(input.catalogue)

cat("Selecting data\n")
#If the magnitude label is provided 
if (mag.label!="") { 
  #If magcut isn't defined, use the maglim values {{{ 
  if (!exists("magcut_lo")) { 
    magcut_lo<-maglim_lo
    magcut_hi<-maglim_hi
    warning("No --magcut was supplied, but --magname was: sample will be cut to --maglim range!")
  }
  #}}}
  #Apply the magnitude limits to the data catalogue
  cat.ind<-which(cat[[mag.label]]>=magcut_lo & cat[[mag.label]]<=magcut_hi)
} else { 
  #Otherwise use all sources 
  cat.ind<-1:nrow(cat)
}
cat(paste("there are",length(cat.ind),"valid data sources\n"))

if (length(cat.ind)==0) stop("there are no data sources in the magnitude window requested?!")

if (!z.label%in%colnames(cat)) stop("the redshift column is not in the catalogue?!") 

cat("Computing data Nz\n")

if (original.weight!="" & original.weight %in% colnames(cat)) { 
  #Compute the data Nz using weights 
  nz_data<-density(cat[[z.label]][cat.ind],weight=cat[[original.weight]][cat.ind],bw=bw/sqrt(12),kern='rect',from=0,to=max(cat[[z.label]]),n=1e4)
} else { 
  #Compute the data Nz using weights 
  nz_data<-density(cat[[z.label]][cat.ind],bw=bw/sqrt(12),kern='rect',from=0,to=max(cat[[z.label]]),n=1e4)
}

cat("Computing analytic Nz\n")

#Compute the analytic Nz 
nz_lo<-helpRfuncs::analytic_nz(filter=filter,maglim=maglim_lo)
nz_hi<-helpRfuncs::analytic_nz(filter=filter,maglim=maglim_hi) 
nz_eff<-nz_hi(nz_data$x)-nz_lo(nz_data$x)
#Normalise to unit area 
nz_eff<-nz_eff/sum(nz_eff,na.rm=T)

cat("Computing prior weight ratios\n")

#Compute the prior weights function 
ratio<-nz_eff/nz_data$y
#Catch numerical noise in denominator 
test<-nz_eff/zapsmall(nz_data$y)
#Catch limiting cases 
ratio[nz_eff==0]<-0
ratio[!is.finite(ratio)|!is.finite(test)]<-NA

cat("Computing prior weight function\n")
#Define the weight function 
weight_func<-approxfun(nz_data$x,ratio)

cat("Assigning prior weight to data sources\n")

#Assign the weight to each source within the magnitude limits 
cat$PriorWeight<-NA 
cat$PriorWeight[cat.ind]<-weight_func(cat[[z.label]][cat.ind])
#Catch non-finite values 
cat$PriorWeight[which(!is.finite(cat$PriorWeight))]<-0
#Normalise the weights 
cat$PriorWeight<-cat$PriorWeight/sum(cat$PriorWeight)

cat("Writing results to disk\n") 

#Output the weights 
helpRfuncs::write.file(file=input.catalogue,cat)

cat("Finished!\n")

