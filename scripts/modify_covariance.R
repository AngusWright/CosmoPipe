#=========================================
#
# File Name : compute_onebin_cov.R
# Created By : awright
# Creation Date : 18-05-2026
# Last Modified : Tue May 19 21:57:53 2026
#
#=========================================

#Get the input files 
inputs<-commandArgs(TRUE) 

cov_modifier<-NULL

#Interpret the command line options {{{
while (length(inputs)!=0) {
  while (length(inputs)!=0 && inputs[1]=='') { inputs<-inputs[-1] }  
  #Check the options {{{ 
  if (!grepl('^-',inputs[1])) {
    print(inputs[1:4])
    stop(paste("Incorrect options provided!"))
  }
  #/*fend*/}}}
  if (inputs[1]=='--datavec') { 
    #Read the input data vector /*fold*/ {{{
    inputs<-inputs[-1]
    datavec_file<-inputs[1]
    inputs<-inputs[-1]
    #/*fold*/}}}
  } else if (inputs[1]=='--covariance') { 
    #Read the input covaraiance /*fold*/ {{{
    inputs<-inputs[-1]
    covariance_file<-inputs[1]
    inputs<-inputs[-1]
    #/*fold*/}}}
  } else if (inputs[1]=='--datavec_out') { 
    #Read the input data vector /*fold*/ {{{
    inputs<-inputs[-1]
    datavec_file_out<-inputs[1]
    inputs<-inputs[-1]
    #/*fold*/}}}
  } else if (inputs[1]=='--covariance_out') { 
    #Read the input covaraiance /*fold*/ {{{
    inputs<-inputs[-1]
    covariance_file_out<-inputs[1]
    inputs<-inputs[-1]
    #/*fold*/}}}
  } else if (inputs[1]=='--ntomo') { 
    #Read the input covaraiance /*fold*/ {{{
    inputs<-inputs[-1]
    ntomo<-as.numeric(inputs[1])
    inputs<-inputs[-1]
    #/*fold*/}}}
  } else if (inputs[1]=='--nmode') { 
    #Read the input covaraiance /*fold*/ {{{
    inputs<-inputs[-1]
    nmode<-as.numeric(inputs[1])
    inputs<-inputs[-1]
    #/*fold*/}}}
  } else if (inputs[1]=='--covmod') { 
    #Read the input covaraiance /*fold*/ {{{
    inputs<-inputs[-1]
    cov_modifier<-inputs[1]
    inputs<-inputs[-1]
    #/*fold*/}}}
  } else {
    stop(paste("Unknown option",inputs[1]))
  }
}
#}}}
#Read data vector 
dvec<-helpRfuncs::read.file(datavec_file,type='asc')[[1]]

#Read Cov 
cov<-as.matrix(helpRfuncs::read.file(covariance_file,type='asc'))

#Combine into 1 bin 
if (length(dvec)>nmode*2) { 
  #Number of tomo bins 
  ntomo = ntomo
  #Number of data points 
  n_data = length(dvec)
  #Number of data points per mode type 
  n_data_EB = length(dvec)/2
  #Number of tomo bin combinations 
  n_combinations = (ntomo*(ntomo+1)/2)
  #Number of COSEBI modes
  n_data_per_bin = (n_data_EB / n_combinations)
  #E vs B 
  type = c(rep("E",n_data_per_bin*n_combinations),rep("B",n_data_per_bin*n_combinations))
  #Array of cov bin elements 
  angbin<-rep(1:n_data_per_bin,n_combinations*2)
  #Inverse of cov 
  inv_cov = solve(cov)
  #Initialise the EB-mode vector 
  combined = rep(0,n_data_per_bin*2)
  inv_cov_combined<- array(0,dim=c(n_data_per_bin*2,n_data_per_bin*2))
  #Notify 
  print(list(ntomo=ntomo,n_data=n_data,n_data_EB=n_data_EB,
             n_combinations=n_combinations,n_data_per_bin=n_data_per_bin,
             len_type=length(type),len_ang=length(angbin),dim_cov=dim(cov),
             len_comb=length(combined),inv_cov_combined=dim(inv_cov_combined)))
  for (k in seq(n_data_per_bin)){
    #Average E modes 
    idx = which(angbin==k & type=='E')
    combined[k] = weighted.mean(dvec[idx], w=1/diag(cov[idx,idx]))
    #Average B modes 
    idx = which(angbin==k & type=='B')
    combined[k+n_data_per_bin] = weighted.mean(dvec[idx], w=1/diag(cov[idx,idx]))
  }
  for (EB1 in c(0,1)) { 
    for (EB2 in c(0,1)) { 
      for (k in seq(n_combinations)-1){
        for (j in seq(k,n_combinations-1)){
          inv_cov_combined[EB1*n_data_per_bin+1:n_data_per_bin,EB2*n_data_per_bin+1:n_data_per_bin] = inv_cov_combined[EB1*n_data_per_bin+1:n_data_per_bin,EB2*n_data_per_bin+1:n_data_per_bin] +
            inv_cov[EB1*n_data_EB+((k*n_data_per_bin+1):((k+1)*n_data_per_bin)),EB2*n_data_EB+((j*n_data_per_bin+1):((j+1)*n_data_per_bin))]
        }
      } 
    }
  }
  cov_combined = solve(inv_cov_combined)
  cov<-cov_combined
  dvec<-combined
}

if (!is.null(cov_modifier)) { 
  cat("modifying the covariance\n")
  covmod<-as.matrix(helpRfuncs::read.file(cov_modifier))
  print(cbind(dim(cov),dim(covmod)))
  cov<-`%*%`(covmod,`%*%`(cov,t(covmod)))
}

write.table(file=datavec_file_out,dvec,row.names=FALSE,col.names=FALSE,quote=FALSE)
write.table(file=covariance_file_out,cov,row.names=FALSE,col.names=FALSE,quote=FALSE)

