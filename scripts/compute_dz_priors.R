#=========================================
#
# File Name : computs_dz_priors.R
# Created By : awright
# Creation Date : 29-03-2023
# Last Modified : Tue Nov 25 10:13:18 2025
#
#=========================================

#Get the input files 
inputs<-commandArgs(TRUE) 

calib.weight.label<-NULL

#Interpret the command line options {{{
while (length(inputs)!=0) {
  while (length(inputs)!=0 && inputs[1]=='') { inputs<-inputs[-1] }  
  #Check the options {{{ 
  if (!grepl('^-',inputs[1])) {
    print(inputs[1:4])
    stop(paste("Incorrect options provided!"))
  }
  #/*fend*/}}}
  if (inputs[1]=='-c') { 
    #Read the input calibration catalogue(s) /*fold*/ {{{
    inputs<-inputs[-1]
    if (any(grepl('^-',inputs))) { 
      input.calib<-inputs[1:(which(grepl('^-',inputs))[1]-1)]
      inputs<-inputs[-(1:(which(grepl('^-',inputs))[1]-1))]
    } else { 
      input.calib<-inputs
      inputs<-NULL
    } 
    #/*fold*/}}}
  } else if (inputs[1]=='-r') { 
    #Read the input catalogue(s) /*fold*/ {{{
    inputs<-inputs[-1]
    if (any(grepl('^-',inputs))) { 
      input.refr<-inputs[1:(which(grepl('^-',inputs))[1]-1)]
      inputs<-inputs[-(1:(which(grepl('^-',inputs))[1]-1))]
    } else { 
      input.refr<-inputs
      inputs<-NULL
    } 
    #/*fold*/}}}
  } else if (inputs[1]=='--patchstrings') { 
    #Read the input catalogue(s) /*fold*/ {{{
    inputs<-inputs[-1]
    if (any(grepl('^-',inputs))) { 
      patchstrings<-inputs[1:(which(grepl('^-',inputs))[1]-1)]
      inputs<-inputs[-(1:(which(grepl('^-',inputs))[1]-1))]
    } else { 
      patchstrings<-inputs
      inputs<-NULL
    } 
    #/*fold*/}}}
  } else if (inputs[1]=='--binstrings') { 
    #Read the input catalogue(s) /*fold*/ {{{
    inputs<-inputs[-1]
    if (any(grepl('^-',inputs))) { 
      binstrings<-inputs[1:(which(grepl('^-',inputs))[1]-1)]
      inputs<-inputs[-(1:(which(grepl('^-',inputs))[1]-1))]
    } else { 
      binstrings<-inputs
      inputs<-NULL
    } 
    #/*fold*/}}}
  } else if (inputs[1]=='--biasoutbase') { 
    #Define the output biases filename /*fold*/ {{{
    inputs<-inputs[-1]
    bias_obase<-inputs[1]
    inputs<-inputs[-1]
    #/*fold*/}}}
  } else if (inputs[1]=='--biasout') { 
    #Define the output biases filename /*fold*/ {{{
    inputs<-inputs[-1]
    bias_oname<-inputs[1]
    inputs<-inputs[-1]
    #/*fold*/}}}
  } else if (inputs[1]=='--syserr') { 
    #Define the Systematic contribution to the covariance /*fold*/ {{{
    inputs<-inputs[-1]
    sys_error<-as.numeric(inputs[1])
    if (is.na(sys_error)) stop("Systematic error contribution cannot be NA")
    if (!is.finite(sys_error)) stop("Systematic error contribution cannot be non-finite")
    if (sys_error<0) stop("Systematic error contribution cannot be negative")
    inputs<-inputs[-1]
    #/*fold*/}}}
  } else if (inputs[1]=='-g') { 
    #Define the goldclass/weight label /*fold*/ {{{
    inputs<-inputs[-1]
    gold.label<-inputs[1]
    inputs<-inputs[-1]
    #/*fold*/}}}
  } else if (inputs[1]=='-cw') { 
    #Define the weight label /*fold*/ {{{
    inputs<-inputs[-1]
    calib.weight.label<-inputs[1]
    inputs<-inputs[-1]
    #/*fold*/}}}
  } else if (inputs[1]=='-w') { 
    #Define the weight label /*fold*/ {{{
    inputs<-inputs[-1]
    weight.label<-inputs[1]
    inputs<-inputs[-1]
    #/*fold*/}}}
  } else if (inputs[1]=='-z') { 
    #Define the redshift label /*fold*/ {{{
    inputs<-inputs[-1]
    redshift.label<-inputs[1]
    inputs<-inputs[-1]
    #/*fold*/}}}
  } else if (inputs[1]=='--covoutbase') { 
    #Define the output covariance filename /*fold*/ {{{
    inputs<-inputs[-1]
    cov_obase<-inputs[1]
    inputs<-inputs[-1]
    #/*fold*/}}}
  } else if (inputs[1]=='--covout') { 
    #Define the output covariance filename /*fold*/ {{{
    inputs<-inputs[-1]
    cov_oname<-inputs[1]
    inputs<-inputs[-1]
    #/*fold*/}}}
  } else {
    stop(paste("Unknown option",inputs[1]))
  }
}
#}}}

#Number of realisations 
nreal<- 0
for (patch in patchstrings) { 
  for (bin in binstrings) { 
    nreal<-max(nreal,length(which(grepl(paste0("_",patch,"_"),input.calib) & grepl(bin,input.calib))))
  }
}
#nreal<-length(input.calib)/length(binstrings)
#Make sure it's an integer! 
if ( nreal==0 ) { 
  stop("There are a no files which match the bin strings and patch strings?!") 
}
#Initialise the realisation results matrix 
for (patch in patchstrings) { 
  if (length(which(grepl(paste0("_",patch,"_"),input.calib,fixed=T)))==0) next 
  def<-matrix(NA,ncol=length(binstrings),nrow=nreal)
  colnames(def)<-binstrings
  wtot<-wtot_gold<-ntot<-ntot_gold<-dneff<-
    muzcalib_base<-muzcalib_raw<-muzcalib<-muzrefr<-sigma<-bias<-muzrefr_nogold<-
      bias_base<-bias_raw<-bias_nogold<-def
  
  #Delta n_eff calculation 
  dneff_calc<-function(w,S) return=(sum(w*S)^2/sum(w^2*S)) / (sum(w)^2/sum(w^2))
  
  #Setup progress bar 
  pb<-txtProgressBar(style=3,min=0,max=length(bias))
  count<-0
  #For each tomographic bin 
  for (bin in 1:length(binstrings)) { 
    #Get the list of calibration and reference catalogues 
    calib_cats<-input.calib[grepl(paste0("_",patch,"_"),input.calib,fixed=T)&grepl(binstrings[bin],input.calib,fixed=T)]
    if (length(which(grepl(paste0("_",patch,"_"),input.refr,fixed=T)&grepl(binstrings[bin],input.refr,fixed=T)))==0) { 
      warning("No reference catalogue binstring matches; assuming catalogues are in order!!")
      print(length(which(grepl(paste0("_",patch,"_"),input.refr,fixed=T)&grepl(binstrings[bin],input.refr,fixed=T))))
      print(length(input.refr))
      print(bin)
      print(paste0("_",patch,"_"))
      print(binstrings[bin])
      refr_cats<-input.refr[grepl(paste0("_",patch,"_"),input.calib,fixed=T)&grepl(binstrings[bin],input.calib,fixed=T)]
    } else {
      refr_cats<-input.refr[grepl(paste0("_",patch,"_"),input.refr,fixed=T)&grepl(binstrings[bin],input.refr,fixed=T)]
    }
    if (length(calib_cats)!=length(refr_cats)) { 
      print(input.calib)
      print(input.refr)
      print(c(length(input.calib),length(input.refr)))
      print(paste0("_",patch,"_"))
      print(binstrings[bin])
      print(calib_cats)
      print(refr_cats)
      print(c(length(calib_cats),length(refr_cats)))
      stop("Mismatch in the reference and calibration catalogue lists?!") 
    } 
    if (length(calib_cats)>0) { 
      for (i in 1:length(calib_cats)) { 
        setTxtProgressBar(pb,count)
        count<-count+1
        #Read the calibration file 
        calib<-helpRfuncs::read.file(calib_cats[i],data.table=FALSE,cols=c(redshift.label,gold.label,calib.weight.label))
        if (any(calib[[redshift.label]]<0)) { 
          cat("WARNING: calibration sources have negative redshift in file",calib_cats[i],"!\n")
          calib[[redshift.label]][which(calib[[redshift.label]]<0)]<-0
        }
        #Read the reference file 
        refr<-helpRfuncs::read.file(refr_cats[i],data.table=FALSE,cols=c(redshift.label,gold.label,weight.label))
        if (any(refr[[redshift.label]]<0)) { 
          cat("WARNING: reference sources have negative redshift in file",refr_cats[i],"!\n")
          refr[[redshift.label]][which(refr[[redshift.label]]<0)]<-0
        }
        #Compute the bias: z_est - z_true 
        wtot[i,bin]<-sum(w=refr[[weight.label]])
        wtot_gold[i,bin]<-sum(w=refr[[weight.label]]*refr[[gold.label]])
        ntot[i,bin]<-nrow(refr)
        ntot_gold[i,bin]<-sum(refr[[gold.label]])
        muzrefr[i,bin]<-weighted.mean(refr[[redshift.label]],(refr[[weight.label]]*refr[[gold.label]]))
        muzrefr_nogold[i,bin]<-weighted.mean(refr[[redshift.label]],refr[[weight.label]])
        dneff[i,bin]<-dneff_calc(w=refr[[weight.label]],S=refr[[gold.label]])
        muzcalib_raw[i,bin]<-weighted.mean(calib[[redshift.label]])
        bias_raw[i,bin]<-weighted.mean(calib[[redshift.label]]) -
                     weighted.mean(refr[[redshift.label]],(refr[[weight.label]]))
        if (!is.null(calib.weight.label)) { 
          muzcalib_base[i,bin]<-weighted.mean(calib[[redshift.label]],calib[[calib.weight.label]])
          muzcalib[i,bin]<-weighted.mean(calib[[redshift.label]],calib[[gold.label]]*calib[[calib.weight.label]])
          bias_base[i,bin]<-weighted.mean(calib[[redshift.label]],calib[[calib.weight.label]]) -
                       weighted.mean(refr[[redshift.label]],(refr[[weight.label]]))
          bias_nogold[i,bin]<-weighted.mean(calib[[redshift.label]],calib[[gold.label]]*calib[[calib.weight.label]]) -
                       weighted.mean(refr[[redshift.label]],(refr[[weight.label]]))
          bias[i,bin]<-weighted.mean(calib[[redshift.label]],calib[[gold.label]]*calib[[calib.weight.label]]) -
                       weighted.mean(refr[[redshift.label]],(refr[[weight.label]]*refr[[gold.label]]))
          sigma[i,bin]<-helpRfuncs::weighted.sd(calib[[redshift.label]],calib[[gold.label]]*calib[[calib.weight.label]]) -
                        helpRfuncs::weighted.sd(refr[[redshift.label]],(refr[[weight.label]]*refr[[gold.label]]))
        } else { 
          muzcalib[i,bin]<-weighted.mean(calib[[redshift.label]],calib[[gold.label]])
          bias_nogold[i,bin]<-weighted.mean(calib[[redshift.label]],calib[[gold.label]]) -
                       weighted.mean(refr[[redshift.label]],(refr[[weight.label]]))
          bias[i,bin]<-weighted.mean(calib[[redshift.label]],calib[[gold.label]]) -
                       weighted.mean(refr[[redshift.label]],(refr[[weight.label]]*refr[[gold.label]]))
          sigma[i,bin]<-helpRfuncs::weighted.sd(calib[[redshift.label]],calib[[gold.label]]) -
                        helpRfuncs::weighted.sd(refr[[redshift.label]],(refr[[weight.label]]*refr[[gold.label]]))
        }
      }
    }
  }
  close(pb)
  
  options(width=200)
  stat_df<-data.frame(realisation=1:nrow(wtot))
  for (stat in c("wtot","wtot_gold","ntot","ntot_gold","dneff","muzcalib_raw",'muzcalib_base',"muzcalib","muzrefr","muzrefr_nogold","bias_raw",'bias_base',"bias_nogold","bias","sigma")) { 
    cat(paste(stat,"\n"))
    try(print(rbind(means=colMeans(get(stat),na.rm=T),
                stdev=matrixStats::colSds(get(stat),na.rm=T))))
    for (i in 1:ncol(get(stat))) stat_df[[paste0(stat,"_",i)]]<-get(stat)[,i]
  }
  helpRfuncs::write.file(paste0(bias_obase,"_",patch,"/allstats.txt"),stat_df)
  
  #Compute the mean biases per bin 
  final_biases<-colMeans(bias)
  final_cov<-orig_cov<-cov(bias)
  final_sigbiases<-colMeans(cbind(bias,sigma))
  final_sigcov<-orig_sigcov<-cov(cbind(bias,sigma))
  #Compute the Nz bias covariance  
  if (exists("sys_error")) { 
    if (sys_error!=0) { 
      #if needed, include systematic component 
      diag(final_cov)<-diag(final_cov)+sys_error^2
      orig_cor<-cov2cor(orig_cov)
      for (i in 1:ncol(orig_cov)) {
        for (j in 1:nrow(orig_cov)) {
          if (i != j) {
            final_cov[i,j]<-(sqrt(diag(final_cov)[i]))*(sqrt(diag(final_cov)[j]))*orig_cor[i,j]
          }
        }
      }
      diag(final_sigcov)<-diag(final_sigcov)+sys_error^2
      orig_sigcor<-cov2cor(orig_sigcov)
      for (i in 1:ncol(orig_sigcov)) {
        for (j in 1:nrow(orig_sigcov)) {
          if (i != j) {
            final_sigcov[i,j]<-(diag(final_sigcov)[i]+sys_error)*(diag(final_sigcov)[j]+sys_error)*orig_sigcor[i,j]
          }
        }
      }
    } 
  }
  #Output the bias file 
  helpRfuncs::write.file(paste0(bias_obase,"_",patch,"/",bias_oname),final_biases,col.names=FALSE)
  #Output the cov file 
  helpRfuncs::write.file(paste0(cov_obase,"_",patch,"/",cov_oname),final_cov,col.names=FALSE)
  #Output the bias file 
  helpRfuncs::write.file(paste0(bias_obase,"_",patch,"/wSig_",bias_oname),final_sigbiases,col.names=FALSE)
  #Output the cov file 
  helpRfuncs::write.file(paste0(cov_obase,"_",patch,"/wSig_",cov_oname),final_sigcov,col.names=FALSE)
}

