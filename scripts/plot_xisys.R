#=========================================
#
# File Name : plot_TPD.R
# Created By : awright
# Creation Date : 18-04-2023
# Last Modified : Sat Dec  6 05:31:27 2025
#
#=========================================

library(argparser)

#Create the argument parser 
p <- arg_parser("Plot theory predictive distributions for a chain file")
# Add a positional argument
p <- add_argument(p, "--xipmvec", help="Observed xipm data vector")
# Add a positional argument
p <- add_argument(p, "--xipm_tpd", help="xipm data vector TPDs")
# Add a positional argument
p <- add_argument(p, "--xipsfvec", help="Observed PSF correlation function data vector")
# Add a positional argument
p <- add_argument(p, "--xigpsfvec", help="Observed PSF-shear cross correlation data vector")
# Add a positional argument
p <- add_argument(p, "--covariance", help="Estimated covariance")
# Add an optional argument
p <- add_argument(p, "--thetamin", help="minimum theta for xipm",type='numeric',default=NA)
# Add an optional argument
p <- add_argument(p, "--thetamax", help="maximum theta for xipm",type='numeric',default=NA)
# Add an optional argument
p <- add_argument(p, "--nmax", help="Number of xipm bins",type='integer',default=NA)
# Add an optional argument
p <- add_argument(p, "--ntomo", help="Number of tomographic bins",type='integer')
# Add an optional argument
p <- add_argument(p, "--output", help="output pdf", default="plot_TPD.pdf")
# Add an optional argument
p <- add_argument(p, "--title", help="Plot title", default="Chain")
# Add an optional argument
p <- add_argument(p, "--type", help="Upper or Lower half of the data vector", default="upper")
# Add a flag
p <- add_argument(p, "--xiponly", help="Only plot the xip component", flag=TRUE)
# Add a flag
p <- add_argument(p, "--diagonly", help="Only plot the diagonal bins?", flag=TRUE)
## Add an optional argument
#p <- add_argument(p, "--xlabel", help="x-axis variable name",default='Radius (arcmin)')
## Add an optional argument
#p <- add_argument(p, "--ylabel", help="y-axis variable name",default=expression(xi^[sys]/xi^paste(Lambda*"CDM"))

#Read the arguments 
args<-parse_args(p)

#Get the number of correlations 
ncorr<-sum(seq(args$ntomo))

#Check for incorrect calling syntax
if (is.na(args$xipmvec)) { 
  stop(cat(print(p))) 
} 


#Read in the data vector 
dat<-helpRfuncs::read.file(file=args$xipmvec)
print(str(dat))
if (ncol(dat)>2) { 
  print(colnames(dat))
  radius<-c(dat$meanr,dat$meanr)
  dat<-data.frame(V1=c(dat$xip,dat$xim))
} else { 
  radius<-rep(rep(10^seq(log10(args$thetamin),log10(args$thetamax),len=args$nmax),ncorr),2)
}
#Get the number of data elements 
ndata<-nrow(dat)/ncorr/2
#Read in the data vector 
psf<-helpRfuncs::read.file(file=args$xipsfvec)
print(str(psf))
if (ncol(psf)>2) { 
  psf<-data.frame(V1=c(psf$xip,psf$xim))
}
#Read in the data vector 
gpsf<-helpRfuncs::read.file(file=args$xigpsfvec)
print(str(gpsf))
if (ncol(gpsf)>2) { 
  print(colnames(gpsf))
  gpsf<-data.frame(V1=c(gpsf$xip,gpsf$xim))
}

#Read the covariance matrix 
cov<-helpRfuncs::read.file(file=args$covariance,type='asc')
cov<-as.matrix(cov)

#Read the theory predictive distributions 
if (file.exists(args$xipm_tpd)) { 
  has_tpd<-TRUE
  tpd<-helpRfuncs::read.chain(file=args$xipm_tpd)
  #Read the samples for each theory prediction 
  samps<-helpRfuncs::read.chain(file=sub("_list_","_",args$xipm_tpd))
  #Assign the weights to the theory predictions 
  tpdweight<-samps$weight
  if (length(tpdweight)==0) { 
    tpdweight<-exp(samps$log_weight)
  }
  if (length(tpdweight)==0) { 
    tpdweight<-samps$post
    tpdweight[which(tpdweight<quantile(tpdweight,prob=0.01))]<-quantile(tpdweight,prob=0.01)
    tpdweight<-tpdweight/min(tpdweight,na.rm=T)
  }
  #Check sizes match 
  if (length(tpdweight)!=nrow(tpd)) { 
    stop(paste("TPD sample weights are not of the same length as the sample?!\n",length(tpdweight),"!=",nrow(tpd)))
  }
  print(summary(tpdweight))
  #Select only the theory predictions, and convert to matrix format 
  cols<-colnames(tpd)
  cols<-cols[which(grepl("scale_cuts_output",cols,ignore.case=T))]
  tpd<-as.matrix(tpd[,cols,with=F])
  
  dat<-(gpsf$V1^2/psf$V1)/tpd[which.max(tpdweight),]
} else { 
  has_tpd<-FALSE
  dat<-(gpsf$V1^2/psf$V1)
} 


#Define the layout matrix for the figure 
if (args$xiponly & args$diagonly) { 
  ncor<-(args$ntomo*(args$ntomo+1))/2
  mat<-matrix(1:args$ntomo,nrow=1)
} else if (args$xiponly) { 
  ncor<-(args$ntomo*(args$ntomo+1))/2
  mat<-matrix(1:(args$ntomo*(args$ntomo+1)/2),nrow=3,ncol=ncor/3,byrow=T)
} else { 
  #upper triangle 
  mat<-matrix(0,nrow=args$ntomo+1,ncol=args$ntomo+1)
  cumul<-0
  for (i in 1:args$ntomo) { 
    mat[i,i:args$ntomo+1]<-i:args$ntomo + cumul
    cumul<-cumul+length(i:args$ntomo)-1
  }
  #lower triangle 
  cumul<-cumul+args$ntomo
  for (i in 1:args$ntomo) {
    mat[i:args$ntomo+1,i]<-i:args$ntomo + cumul
    cumul<-cumul+length(i:args$ntomo)-1
  }
}

#open the plot device 
if (args$xiponly & args$diagonly) { 
  pdf(file=args$output,height=2.5,width=6)
} else if (args$xiponly) { 
  pdf(file=args$output,height=4,width=8)
} else { 
  pdf(file=args$output)
}
#set the layout 
mat<-rbind(max(mat)+1,mat)
layout(mat,height=c(0.3,rep(1,nrow(mat)-1)))
#set the margins 
if (args$xiponly) { 
  par(mar=c(0,0,0,0),oma=c(4,4,1,2),family='serif')
} else {
  par(mar=c(0,0,0,0),oma=c(5,5,1,5),family='serif')
}

#Plot data vector with theory samples 
start=0
#Define the ylimits of each panel 
#ylim=range(c(dat+sqrt(diag(cov))*3,dat-sqrt(diag(cov))*3))/10^mfact
ylims_upper<-list()
start_tmp<-0
mfact<-ceiling(median(log10(abs(dat[1:(length(dat)/2)]))))
count<-0
if (args$xiponly) { 
  ylim=c(Inf,-Inf)
  for (i in 1:args$ntomo) { 
    for (j in i:args$ntomo) { 
      ind<-start_tmp+1:ndata
      if (has_tpd) { 
        ylim=c(min(c(ylim[1],dat[ind]/10^mfact,(-0.1*sqrt(diag(cov)[ind]))/10^mfact/tpd[which.max(tpdweight),ind])),
              max(c(ylim[2],dat[ind]/10^mfact,(+0.1*sqrt(diag(cov)[ind]))/10^mfact/tpd[which.max(tpdweight),ind])))
      } else { 
        ylim=c(min(c(ylim[1],dat[ind]/10^mfact,(-0.1*sqrt(diag(cov)[ind]))/10^mfact)),
              max(c(ylim[2],dat[ind]/10^mfact,(+0.1*sqrt(diag(cov)[ind]))/10^mfact)))
      }
    }
  } 
  for (i in 1:args$ntomo) { 
    ylims_upper[[i]]=list()
    for (j in i:args$ntomo) { 
      ylims_upper[[i]][[j]]<-ylim
    }
  }
} else { 
  for (i in 1:args$ntomo) { 
    ylim=c(Inf,-Inf)
    ylims_upper[[i]]=list()
    for (j in i:args$ntomo) { 
      count<-count+1
      ind<-start_tmp+1:ndata
      if (has_tpd) { 
        ylim=c(min(c(ylim[1],dat[ind]/10^mfact,(-0.1*sqrt(diag(cov)[ind]))/10^mfact/tpd[which.max(tpdweight),ind])),
              max(c(ylim[2],dat[ind]/10^mfact,(+0.1*sqrt(diag(cov)[ind]))/10^mfact/tpd[which.max(tpdweight),ind])))
      } else { 
        ylim=c(min(c(ylim[1],dat[ind]/10^mfact,(-0.1*sqrt(diag(cov)[ind]))/10^mfact)),
              max(c(ylim[2],dat[ind]/10^mfact,(+0.1*sqrt(diag(cov)[ind]))/10^mfact)))
      }
      #ylim=c(min(c(ylim[1],(-3*sqrt(diag(cov)[ind]))/10^mfact)),
      #       max(c(ylim[2],(+3*sqrt(diag(cov)[ind]))/10^mfact)))
      start_tmp<-start_tmp+ndata
    }
    for (j in i:args$ntomo) { 
      ylims_upper[[i]][[j]]<-ylim
    }
  }
}
ylims_lower<-list()
for (i in 1:args$ntomo) ylims_lower[[i]]=list()
mfact<-ceiling(median(log10(abs(dat[length(dat)/2 + 1:(length(dat)/2)]))))
for (jj in 1:args$ntomo) { 
  start_tmp<-length(dat)/2
  for (i in 1:args$ntomo) { 
    for (j in i:args$ntomo) { 
      ind<-start_tmp+1:ndata
      if (j==jj) {  
        cat(paste0("[",i,",",j,"] "))
        if (has_tpd) { 
          ylim=c(min(c(ylim[1],dat[ind]/10^mfact,(-0.1*sqrt(diag(cov)[ind]))/10^mfact/tpd[which.max(tpdweight),ind])),
                max(c(ylim[2],dat[ind]/10^mfact,(+0.1*sqrt(diag(cov)[ind]))/10^mfact/tpd[which.max(tpdweight),ind])))
        } else { 
          ylim=c(min(c(ylim[1],dat[ind]/10^mfact,(-0.1*sqrt(diag(cov)[ind]))/10^mfact)),
                max(c(ylim[2],dat[ind]/10^mfact,(+0.1*sqrt(diag(cov)[ind]))/10^mfact)))
        }
      }
      start_tmp<-start_tmp+ndata
    }
  }
  cat("\n")
  for (i in 1:jj) { 
    ylims_lower[[i]][[jj]]<-ylim
  }
}
print(ylims_lower)

if (args$xiponly) { set=1 } else {set=1:2}

count<-0
for (uplo in set) { 
  #Define the scaling factor for the y-labels 
  mfact<-ceiling(median(log10(abs(dat[length(dat)/2*(uplo-1) + 1:(length(dat)/2)]))))
  for (i in 1:args$ntomo) { 
    for (j in i:args$ntomo) { 
      count<-count+1
      ind<-start+1:ndata
      start=start+ndata
      #Plot the data vector 
      if (args$xiponly & args$diagonly) { 
          if (i!=j) next 
          labels=c(T,count==1,F,F)
          ylim=ylims_upper[[i]][[j]]
      } else if (args$xiponly) { 
          #labels=c(count>ncor*2/3,count%in%(ncor*c(0,1,2)/3+1),count<=ncor/3,count%in%(ncor*c(1,2,3)/3))
          labels=c(count>ncor*2/3,count%in%(ncor*c(0,1,2)/3+1),F,F)
          ylim=ylims_upper[[i]][[j]]
      } else { 
        if (uplo==1){ 
          labels=c(F,F,i==1,j==args$ntomo)
          ylim=ylims_upper[[i]][[j]]
        } else { 
          labels=c(j==args$ntomo,i==1,F,F)
          ylim=ylims_lower[[i]][[j]]
        } 
      }
      plot(radius[ind],dat[ind]/10^mfact,xlab='',ylab='',type='n',
           axes=F,ylim=ylim,log='x',xlim=range(radius))
      #Data points
      #points(radius[ind],dat[ind]/10^mfact,pch=20,cex=0.8,lwd=2)
      #magicaxis::magerr(x=radius[ind],dat[ind]/10^mfact,yhi=sqrt(diag(cov)[ind])/10^mfact,ylo=sqrt(diag(cov)[ind])/10^mfact,lwd=2)
      if (has_tpd) { 
        polygon(col=rgb(232,243,247,maxColorValue=255),border=NA,
                x=c(radius[ind],rev(radius[ind])),
                y=c(-0.1*sqrt(diag(cov)[ind])/tpd[which.max(tpdweight),ind]/10^mfact,
                rev( 0.1*sqrt(diag(cov)[ind])/tpd[which.max(tpdweight),ind]/10^mfact)))
      } else { 
        polygon(col=rgb(232,243,247,maxColorValue=255),border=NA,
                x=c(radius[ind],rev(radius[ind])),
                y=c(-0.1*sqrt(diag(cov)[ind])/10^mfact,
                rev( 0.1*sqrt(diag(cov)[ind])/10^mfact)))
      }
      #Zero line 
      abline(h=0,lwd=1,lty=1)
      abline(h=c(-1,1)*0.02/10^mfact,lwd=1,lty=3)
      lines(col=rgb(238,87,75,maxColorValue=255),radius[ind],dat[ind]/10^mfact,lwd=1.5)

      magicaxis::magaxis(side=1:4,labels=labels,xlab='',ylab='',grid=FALSE,family='serif',cex.lab=1.4)
      text(pos=4,x=radius[ind[1]],y=ylim[1]+diff(ylim)/10,labels=paste0(i,"-",j),font=1)

      #Add the samples 
      #tpdsamp<-tpd[sample(nrow(tpd),prob=tpdweight,size=500),]
      #matplot(radius[ind],t(tpdsamp)[ind,]/10^mfact,add=T,type='l',col=hsv(a=0.1),lty=1)
  
    }
  }
  if (has_tpd) { 
    if (args$xiponly) { 
      mtext(side=2,text=bquote(.(parse(text="xi['+']^'sys'/xi['+']^paste(Lambda,'CDM')")[[1]])*" x10"^.(mfact)),line=2.0,outer=T)
    } else { 
      if (uplo==1) { 
        mtext(side=4,text=bquote(.(parse(text="xi['+']^'sys'/xi['+']^paste(Lambda,'CDM')")[[1]])*" x10"^.(mfact)),line=2.5,outer=T)
      } else if (uplo==2) {  
        mtext(side=2,text=bquote(.(parse(text="xi['-']^'sys'/xi['-']^paste(Lambda,'CDM')")[[1]])*" x10"^.(mfact)),line=2.5,outer=T)
      }
    }
  } else { 
    if (args$xiponly) { 
      mtext(side=2,text=bquote(.(parse(text="xi['+']^'sys'")[[1]])*" x10"^.(mfact)),line=2.0,outer=T)
    } else { 
      if (uplo==1) { 
        mtext(side=4,text=bquote(.(parse(text="xi['+']^'sys'")[[1]])*" x10"^.(mfact)),line=2.5,outer=T)
      } else if (uplo==2) {  
        mtext(side=2,text=bquote(.(parse(text="xi['-']^'sys'")[[1]])*" x10"^.(mfact)),line=2.5,outer=T)
      }
    }
  }
}
#Annotate axes 
if (args$xiponly) { 
  mtext(side=1,text=expression(theta~~'(arcmin)'),line=2.5,outer=T)
} else {
  mtext(side=1,text=expression(theta~~'(arcmin)'),line=2.5,outer=T)
  mtext(side=3,text=expression(theta~~'(arcmin)'),line=2.5,outer=T)
}

plot(1,type='n',axes=F,xlab='',ylab='')
legend('center',ncol=3,legend=c(expression(0.1*sigma[xi+""]),args$title,"±2%"),lty=c(NA,1,3),pch=c(15,NA,NA),pt.cex=2,col=c(rgb(232,243,247,maxColorValue=255),rgb(238,87,75,maxColorValue=255),'black'))

dev.off()

